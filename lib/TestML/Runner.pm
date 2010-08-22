package TestML::Runner;
use strict;
use warnings;
use TestML::Base -base;

use TestML::Parser;
use TestML::Context;

# Since there is only ever one test runner, it makes things a lot easier to
# keep the reference to it in a global variable accessed by a method, than to
# put a reference to it into every object that needs to access it.
our $self;

has 'bridge';
has 'testml';
has 'base', -init => '$0 =~ m!(.*)/! ? $1 : "."';
has 'document', -init => '$self->parse_document()';
has 'transform_modules', -init => '$self->_transform_modules';
has 'block';
has 'stash' => {
    'Label' => '$BlockLabel',
};

sub init {
    my $self = $TestML::Runner::self = shift;
    return $self->SUPER::init(@_);
}

sub title { }
sub plan_begin { }
sub plan_end { }

sub run {
    my $self = shift;

    $self->title();
    $self->plan_begin();

    for my $statement (@{$self->document->test->statements}) {
        my $blocks = @{$statement->points}
            ? $self->select_blocks($statement->points)
            : [TestML::Block->new()];
        for my $block (@$blocks) {
            $self->block($block);
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
                    $self->$method($left, $right);
                }
                else {
                    $self->$method($left);
                }
            }
        }
    }
    $self->plan_end();
}

sub get_label {
    my $self = shift;
    my $label = $self->stash->{Label};
    my %replace = map {
        my $v = $self->block->points->{$_};
        $v =~ s/\n.*//s;
        $v =~ s/^\s*(.*?)\s*$/$1/;
        ($_, $v);
    } keys %{$self->block->points};
    $replace{BlockLabel} = $self->block->label;
    $label =~ s/\$(\w+)/$replace{$1}/ge;
    return $label;
}

sub select_blocks {
    my $self = shift;
    my $points = shift;
    my $selected = [];

    # XXX $points an %points is very confusing here
    OUTER: for my $block (@{$self->document->data->blocks}) {
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
        not => 0,
        type => 'None',
        runner => $self,
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
    if (ref $self->testml) {
        $fh = $self->testml;
        $base = $self->base;
    }
    else {
        my $path = join '/', $self->base, $self->testml;
        open $fh, $path or die "Can't open $path for input";
        $base = $path;
        $base =~ s/(.*)\/.*/$1/ or die;
    }
    my $text = do { local $/; <$fh> };
    my $document = TestML::Parser->parse($text)
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
                my $text = do { local $/; <IN> };
                my $blocks = TestML::Parser->parse_data($text)
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
