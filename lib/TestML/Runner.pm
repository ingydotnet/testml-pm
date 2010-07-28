package TestML::Runner;
use strict;
use warnings;
use TestML::Base -base;

use TestML::Parser;

field 'bridge';
field 'document';
field 'base', -init => '$0 =~ m!(.*)/! ? $1 : "."';
field 'doc', -init => '$self->parse_document()';
field 'transform_modules', -init => '$self->_transform_modules';

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
            if ($statement->assertion->expression) {
                my $right = $self->evaluate_expression(
                    $statement->assertion->expression,
                    $block,
                );
                $self->EQ($left, $right, $block->label);
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
    );

    for my $transform (@{$expression->transforms}) {
        my $transform_name = $transform->name;
        next if $context->error and $transform_name ne 'Catch';
        my $function = $self->get_transform_function($transform_name);
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
            $context->error($@);
            $context->value(undef);
        }
        else {
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
    my $fh;
    if (ref $self->document) {
        $fh = $self->document;
    }
    else {
        my $path = join '/', $self->base, $self->document;
        open $fh, $path or die "Can't open $path for input";
    }
    my $testml = do { local $/; <$fh> };
    my $document = TestML::Parser->parse($testml)
        or die "TestML document failed to parse";
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
        eval "use $module_name";
        if ($@) {
            die "Can't use $module_name:\n$@";
        }
    }
    return $modules;
}

package TestML::Context;
use TestML::Base -base;

field 'document';
field 'block';
field 'point';
field 'value';
field 'error';

1;
