package TestML::Runner;
use strict;
use warnings;
use TestML::Base -base;

use TestML::Parser;

has 'bridge';
has 'document';
has 'base', -init => '$0 =~ m!(.*)/! ? $1 : "."';
has 'doc', -init => '$self->parse_document()';
has 'transform_modules', -init => '$self->_transform_modules';

sub title { }
sub plan_begin { }
sub plan_end { }

sub run {
    my $self = shift;

    $self->title();
    $self->plan_begin();

    for my $statement (@{$self->doc->test->statements}) {
        my $blocks = @{$statement->points}
            ? $self->select_blocks($statement->points)
            : [TestML::Block->new()];
        for my $block (@$blocks) {
            my $left = $self->evaluate_expression(
                $statement->expression,
                $block,
            );
            if (my $assertion = $statement->assertion) {
                my $method = 'assert_' . $assertion->name;
                # TODO - Should check 
                if (@{$assertion->expression->transforms}) {
                    my $right = $self->evaluate_expression(
                        $assertion->expression,
                        $block,
                    );
                    $self->$method($left, $right, $block->label);
                }
                else {
                    $self->$method($left, $block->label);
                }
            }
        }
    }
    $self->plan_end();
}

sub select_blocks {
    my $self = shift;
    my $points = shift;
    my $selected = [];

    # XXX $points an %points is very confusing here
    OUTER: for my $block (@{$self->doc->data->blocks}) {
        my %points = %{$block->points};
        next if exists $points{SKIP};
        for my $point (@$points) {
            next OUTER unless exists $points{$point};
        }
        if (exists $points{ONLY}) {
            @$selected = ($block);
            last;
        }
        push @$selected, $block;
        last if exists $points{LAST};
    }
    return $selected;
}

sub evaluate_expression {
    my $self = shift;
    my $expression = shift;
    my $block = shift || undef;

    my $context = TestML::Context->new(
        document => $self->doc,
        block => $block,
        not => 0,
        type => 'None',
    );

    for my $transform (@{$expression->transforms}) {
        my $transform_name = $transform->name;
        next if $context->type eq 'Error' and $transform_name ne 'Catch';
        if (ref($transform) eq 'TestML::String') {
            $context->set(Str => $transform->value);
            next;
        }
        if ($transform_name eq 'Not') {
            $context->not($context->not ? 0 : 1);
            next;
        }
        my $function = $self->get_transform_function($transform_name);
        $context->_set(0);
        my $value = eval {
            &$function(
                $context,
                map {
                    (ref($_) eq 'TestML::Expression')
                    ? $self->evaluate_expression($_, $block)
                    : $_
                } @{$transform->args}
            );
        };
        if ($@) {
            $context->type('Error');
            $context->error($@);
            $context->value(undef);
        }
        elsif (not $context->_set) {
            $context->value($value);
        }
    }
    if ($context->error) {
        die $context->error;
    }
    return $context;
}

sub get_transform_function {
    my $self = shift;
    my $name = shift;
    my $modules = $self->transform_modules();
    for my $module (@$modules) {
        eval "use $module";
        no strict 'refs';
        return \&{"$module\::$name"}
            if defined &{"$module\::$name"};
    }
    die "Can't locate function '$name'";
}

sub parse_document {
    my $self = shift;
    my ($fh, $base);
    if (ref $self->document) {
        $fh = $self->document;
        $base = $self->base;
    }
    else {
        my $path = join '/', $self->base, $self->document;
        open $fh, $path or die "Can't open $path for input";
        $base = $path;
        $base =~ s/(.*)\/.*/$1/ or die;
    }
    my $testml = do { local $/; <$fh> };
    my $document = TestML::Parser->parse($testml)
        or die "TestML document failed to parse";
    if (@{$document->meta->data->{Data}}) {
        my $data_files = $document->meta->data->{Data};
        my $inline = $document->data->blocks;
        $document->data->blocks([]);
        for my $file (@$data_files) {
            if ($file eq '_') {
                push @{$document->data->blocks}, @$inline;
            }
            else {
                my $path = join '/', $base, $file;
                open IN, $path or die "Can't open $path for input";
                my $testml = do { local $/; <IN> };
                my $blocks = TestML::Parser->parse_data($testml)
                    or die "TestML data document failed to parse";
                push @{$document->data->blocks}, @$blocks;
            }
        }
    }
    return $document;
}

sub _transform_modules {
    my $self = shift;
    my $modules = [qw(
        TestML::Standard    
    )];
    if ($self->bridge) {
        push @$modules, $self->bridge;
    }
    for my $module_name (@$modules) {
        next if $module_name eq 'main';
        eval "use $module_name";
        if ($@) {
            die "Can't use $module_name:\n$@";
        }
    }
    return $modules;
}

package TestML::Context;
use TestML::Base -base;

has 'document';
has 'block';
has 'point';
has 'value';
has 'error';
has 'type';
has 'not';
has '_set';

sub set {
    my $self = shift;
    my $type = shift;
    my $value = shift;
    $self->throw("Invalid context type '$type'")
        unless $type =~ /^(?:None|Str|Num|Bool|List)$/;
    $self->type($type);
    $self->value($value);
    $self->_set(1);
}

sub get_value_if_type {
    my $self = shift;
    my $type = $self->type;
    return $self->value if grep $type eq $_, @_;
    $self->throw("context object is type '$type', but '@_' required");
}

sub get_value_as_str {
    my $self = shift;
    my $type = $self->type;
    my $value = $self->value;
    return
        $type eq 'Str' ? $value :
        $type eq 'List' ? join("\n", @$value, '') :
        $type eq 'Bool' ? $value ? '1' : '' :
        $type eq 'Num' ? "$value" :
        $type eq 'None' ? '' :
        $self->throw("Str type error: '$type'");
}

sub get_value_as_num {
    my $self = shift;
    my $type = $self->type;
    my $value = $self->value;
    return
        $type eq 'Str' ? $value + 0 :
        $type eq 'List' ? scalar(@$value) :
        $type eq 'Bool' ? $value :
        $type eq 'Num' ? $value :
        $type eq 'None' ? 0 :
        $self->throw("Num type error: '$type'");
}

sub get_value_as_bool {
    my $self = shift;
    my $type = $self->type;
    my $value = $self->value;
    return
        $type eq 'Str' ? length($value) ? 1 : 0 :
        $type eq 'List' ? @$value ? 1 : 0 :
        $type eq 'Bool' ? $value :
        $type eq 'Num' ? $value == 0 ? 0 : 1 :
        $type eq 'None' ? 0 :
        $self->throw("Bool type error: '$type'");
}

sub throw {
    require Carp;
    Carp::croak $_[1];
}

1;
