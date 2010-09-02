package TestML::Runtime;
use TestML::Base -base;

use TestML::Compiler;

# Since there is only ever one test runtime, it makes things a lot easier to
# keep the reference to it in a global variable accessed by a method, than to
# put a reference to it into every object that needs to access it.
our $self;

has 'base', -init => '$0 =~ m!(.*)/! ? $1 : "."';
has 'testml';
has 'bridge';

has 'function';
has 'planned' => 0;

sub init {
    my $self = $TestML::Runtime::self = shift;
    $self->SUPER::init(@_);
    $self->function($self->compile_testml);
    $self->load_variables;
    $self->load_transform_module('TestML::Transforms::Standard');
    $self->load_transform_module('TestML::Transforms::Debug');
    if ($self->bridge) {
        $self->load_transform_module($self->bridge);
    }
    return $self;
}

sub title { }
sub plan_begin { }
sub plan_end { }

sub run {
    my $self = shift;

    $self->run_function($self->function);

    $self->plan_end();
}

sub run_function {
    my $self = shift;
    my $function = shift;
    my $parent = $self->function;
    $self->function($function);

    for my $statement (@{$function->statements}) {
        $self->run_statement($statement);
    }
    $self->function($parent);
}

sub run_statement {
    my $self = shift;
    my $statement = shift;
    my $blocks = @{$statement->points}
        ? $self->select_blocks($statement->points)
        : [TestML::Block->new()];
    for my $block (@$blocks) {
        $self->function->block($block);
        my $context = $self->run_expression(
            $statement->expression,
            $block,
        );
        if (my $assertion = $statement->assertion) {
            $self->run_assertion($context, $block, $assertion);
        }
    }
}

sub run_assertion {
    my $self = shift;
    my $left = shift;
    my $block = shift;
    my $assertion = shift;
    my $method = 'assert_' . $assertion->name;

    # Run this as late as possible.
    if (! $self->planned) {
        $self->title();
        $self->plan_begin();
        $self->planned(1);
    }

    # TODO - Should check 
    my $results = ($left->type eq 'List')
        ? $left->value
        : [ $left ];
    for my $result (@$results) {
        if (@{$assertion->expression->transforms}) {
            my $right = $self->run_expression(
                $assertion->expression,
                $block,
            );
            my $matches = ($right->type eq 'List')
                ? $right->value
                : [ $right ];
            for my $match (@$matches) {
                $self->$method($result, $match);
            }
        }
        else {
            $self->$method($result);
        }
    }
}

sub select_blocks {
    my $self = shift;
    my $wanted = shift;
    my $selected = [];

    OUTER: for my $block (@{$self->function->namespace->{DataBlocks}}) {
        my %points = %{$block->points};
        next if exists $points{SKIP};
        for my $point (@$wanted) {
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

sub run_expression {
    my $self = shift;
    my $prev_expression = $self->function->expression;
    my $expression = shift;
    $self->function->expression($expression);
    my $block = shift || undef;

    my $context = TestML::Context->new();

    for my $transform (@{$expression->transforms}) {
        my $transform_name = $transform->name;
        next if $expression->error and $transform_name ne 'Catch';
        if (ref($transform) eq 'TestML::String') {
            $context->set(Str => $transform->value);
            next;
        }
        elsif (ref($transform) eq 'TestML::Number') {
            $context->set(Num => $transform->value);
            next;
        }
        my $function = $self->function->fetch($transform_name)
            or die "Can't find transform '$transform_name'";
        $expression->set_called(0);
        my $value = eval {
            &$function(
                $context,
                map {
                    (ref($_) eq 'TestML::Expression')
                    ? $self->run_expression($_, $block)
                    : $_
                } @{$transform->args}
            );
        };
        if ($@) {
            $expression->error($@);
            $context->type('None');
            $context->value(undef);
        }
        elsif (not $expression->set_called) {
            $context->value($value);
        }
    }
    if ($expression->error) {
        die $expression->error;
    }
    $self->function->expression($prev_expression);
    return $context;
}

sub compile_testml {
    my $self = shift;
    my $path = ref($self->testml)
        ? $self->testml
        : join '/', $self->base, $self->testml;
    my $function = TestML::Compiler->new(base => $self->base)->compile($path)
        or die "TestML document failed to compile";
    return $function;
}

sub load_variables {
    my $self = shift;
    $self->function->namespace->{Label} = '$BlockLabel';
}

sub load_transform_module {
    my $self = shift;
    my $module = shift;
    if ($module ne 'main') {
        eval "require $module; 1"
            or die "Can't use $module:\n$@";
    }
    no strict 'refs';
    for my $key (sort keys %{"$module\::"}) {
        if (my $function = *{${"$module\::"}{$key}}{CODE}) {
            $self->function->namespace->{$key} = $function;
        }
    }
}

sub get_label {
    my $self = shift;
    my $label = $self->function->namespace->{Label};
    my %replace = map {
        my $v = $self->function->block->points->{$_};
        $v =~ s/\n.*//s;
        $v =~ s/^\s*(.*?)\s*$/$1/;
        ($_, $v);
    } keys %{$self->function->block->points};
    $replace{BlockLabel} = $self->function->block->label;
    $label =~ s/\$(\w+)/$replace{$1}/ge;
    return $label;
}

sub get_error {
    my $self = shift;
    return $self->function->expression->error;
}

sub clear_error {
    my $self = shift;
    return $self->function->expression->error(undef);
}

sub throw {
    require Carp;
    Carp::croak $_[1];
}
