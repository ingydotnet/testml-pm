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
has 'transforms';

has 'function', -init => '$self->compile_testml()';
has 'planned' => 0;

sub init {
    my $self = $TestML::Runtime::self = shift;
    $self->SUPER::init(@_);
    $self->transforms([
        'TestML::Transforms::Standard',
        'TestML::Transforms::Debug',
        $self->bridge || (),
    ]);
    $self->load_transform_modules;
    return $self;
}

sub title { }
sub plan_begin { }
sub plan_end { }

sub run {
    my $self = shift;

    for my $statement (@{$self->function->statements}) {
        my $blocks = @{$statement->points}
            ? $self->select_blocks($statement->points)
            : [TestML::Block->new()];
        for my $block (@$blocks) {
            $self->function->block($block);
            my $context = $self->evaluate_expression(
                $statement->expression,
                $block,
            );
            if (my $assertion = $statement->assertion) {
                $self->run_assertion($context, $block, $assertion);
            }
        }
    }
    $self->plan_end();
}

sub run_assertion {
    if (! $self->planned) {
        $self->title();
        $self->plan_begin();
        $self->planned(1);
    }

    my $self = shift;
    my $left = shift;
    my $block = shift;
    my $assertion = shift;
    my $method = 'assert_' . $assertion->name;
    # TODO - Should check 
    my $results = ($left->type eq 'List')
        ? $left->value
        : [ $left ];
    for my $result (@$results) {
        if (@{$assertion->expression->transforms}) {
            my $right = $self->evaluate_expression(
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

    OUTER: for my $block (@{$self->function->data->blocks}) {
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

sub evaluate_expression {
    my $self = shift;
    my $prev_expression = $self->function->current_expression;
    my $expression = shift;
    $self->function->current_expression($expression);
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
        my $function = $self->get_transform_function($transform_name);
        $expression->set_called(0);
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
    $self->function->current_expression($prev_expression);
    return $context;
}

sub load_transform_modules {
    my $self = shift;
    for my $module_name (@{$self->transforms}) {
        next if $module_name eq 'main';
        eval "require $module_name; 1"
            or die "Can't use $module_name:\n$@";
    }
}

sub get_transform_function {
    my $self = shift;
    my $name = shift;
    my $modules = $self->transforms();
    for my $module (@$modules) {
        eval "use $module";
        no strict 'refs';
        return \&{"$module\::$name"}
            if defined &{"$module\::$name"};
    }
    die "Can't locate function '$name'";
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
    return $self->function->current_expression->error;
}

sub clear_error {
    my $self = shift;
    return $self->function->current_expression->error(undef);
}

sub throw {
    require Carp;
    Carp::croak $_[1];
}


package TestML::Object;
use TestML::Base -base;

has 'type' => 'None';
has 'value';

sub set {
    my $self = shift;
    my $type = shift;
    my $value = shift;
    $self->runtime->throw("Invalid context type '$type'")
        unless $type =~ /^(?:None|Str|Num|Bool|List)$/;
    $self->type($type);
    $self->value($value);
    $self->runtime->function->current_expression->set_called(1);
}

sub assert_type {
    my $self = shift;
    my $type = $self->type;
    return $self->value if grep $type eq $_, @_;
    $self->runtime->throw("context object is type '$type', but '@_' required");
}

sub as_str {
    my $self = shift;
    my $type = $self->type;
    my $value = $self->value;
    return
        $type eq 'Str' ? $value :
        $type eq 'List' ? join("", @$value) :
        $type eq 'Bool' ? $value ? '1' : '' :
        $type eq 'Num' ? "$value" :
        $type eq 'None' ? '' :
        $self->runtime->throw("Str type error: '$type'");
}

sub as_num {
    my $self = shift;
    my $type = $self->type;
    my $value = $self->value;
    return
        $type eq 'Str' ? $value + 0 :
        $type eq 'List' ? scalar(@$value) :
        $type eq 'Bool' ? $value ? 1 : 0 :
        $type eq 'Num' ? $value :
        $type eq 'None' ? 0 :
        $self->runtime->throw("Num type error: '$type'");
}

sub as_bool {
    my $self = shift;
    my $type = $self->type;
    my $value = $self->value;
    return
        $type eq 'Str' ? length($value) ? 1 : 0 :
        $type eq 'List' ? @$value ? 1 : 0 :
        $type eq 'Bool' ? $value :
        $type eq 'Num' ? $value == 0 ? 0 : 1 :
        $type eq 'None' ? 0 :
        $self->runtime->throw("Bool type error: '$type'");
}

package TestML::Context;
use TestML::Object -base;

sub runtime {
    return $TestML::Runtime::self;
}

