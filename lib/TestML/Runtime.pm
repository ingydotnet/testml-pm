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
has 'test_number' => 0;

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

    $self->run_plan();
    $self->plan_end();
}

sub run_plan {
    my $self = shift;
    if (! $self->planned) {
        $self->title();
        $self->plan_begin();
        $self->planned(1);
    }
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
    $self->run_plan;

    $self->test_number($self->test_number + 1);
    $self->function->namespace->{TestNumber} =
        TestML::Num->new(value => $self->test_number);

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

    OUTER: for my $block (@{$self->function->data}) {
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

    my $transforms = $expression->transforms;
    my $context = TestML::Object->new;

    for (my $i = 0; $i < @$transforms; $i++) {
        my $transform = $transforms->[$i];
        next if $expression->error and (
            not $transform->isa('TestML::Transform') or
            $transform->name ne 'Catch'
        );
        if ($transform->isa('TestML::Object')) {
            $context = $transform;
            next;
        }
        my $object = $self->function->fetch($transform->name)
            or die "Can't find transform '${\$transform->name}'";
        if ($object->isa('TestML::Code')) {
            my $function = $object->value;
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
                $context = TestML::Error->new(value => $@);
            }
            elsif (UNIVERSAL::isa($value, 'TestML::Object')) {
                $context = $value;
            }
            else {
                $context =
                    not(defined $value) ? TestML::None->new :
                    ref($value) eq 'ARRAY' ? TestML::List->new(value => $value) :
                    $value =~ /^-?\d+$/ ? TestML::Num->new(value => $value + 0) :
                    TestML::Str->new(value => $value);
            }
        }
        else {
            $context = $object;
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
    $self->function->namespace->{Label} =
        TestML::Str->new(value => '$BlockLabel');
    $self->function->namespace->{True} = $TestML::AST::True;
    $self->function->namespace->{False} = $TestML::AST::False;
    $self->function->namespace->{None} = $TestML::AST::None;
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
        my $glob = ${"$module\::"}{$key};
        if (my $function = *$glob{CODE}) {
            $self->function->namespace->{$key} = TestML::Code->new(
                value => $function,
            );
        }
        elsif (my $object = *$glob{SCALAR}) {
            if ($$object) {
                $self->function->namespace->{$key} = $$object;
            }
        }
    }
}

sub get_label {
    my $self = shift;
    my $label = $self->function->namespace->{Label}->value;
    sub label {
        my $self = shift;
        my $var = shift;
        return $self->function->block->label if $var eq 'BlockLabel';
        if (my $v = $self->function->block->points->{$var}) {
            $v =~ s/\n.*//s;
            $v =~ s/^\s*(.*?)\s*$/$1/;
            return $v;
        }
        if (my $v = $self->function->namespace->{$var}) {
            return $v->value;
        }
    }
    $label =~ s/\$(\w+)/label($self, $1)/ge;
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

#-----------------------------------------------------------------------------
package TestML::Function;
use TestML::Base -base;

has 'outer';
has 'namespace' => {};
has 'statements' => [];
has 'data' => [];
has 'expression';
has 'block';

sub fetch {
    my $self = shift;
    my $name = shift;
    while ($self) {
        if (my $object = $self->namespace->{$name}) {
            return $object;
        }
        $self = $self->outer;
    }
    return;
}

#-----------------------------------------------------------------------------
package TestML::Statement;
use TestML::Base -base;

has 'expression', -init => 'TestML::Expression->new';
has 'assertion';
has 'points' => [];

#-----------------------------------------------------------------------------
package TestML::Expression;
use TestML::Base -base;

has 'transforms' => [];
has 'error';
has 'set_called';

#-----------------------------------------------------------------------------
package TestML::Assertion;
use TestML::Base -base;

has 'name';
has 'expression', -init => 'TestML::Expression->new';

#-----------------------------------------------------------------------------
package TestML::Transform;
use TestML::Base -base;

has 'name';
has 'args' => [];

#-----------------------------------------------------------------------------
package TestML::Block;
use TestML::Base -base;

has 'label' => '';
has 'points' => {};

#-----------------------------------------------------------------------------
package TestML::Object;
use TestML::Base -base;

our @EXPORT_BASE = qw(Str Num Bool List);

has 'type' => 'None';
has 'value';

sub runtime { return $TestML::Runtime::self }

sub Str     { TestML::Str->new(value => shift) }
sub Num     { TestML::Num->new(value => shift) }
sub Bool    { TestML::Bool->new(value => shift) }
sub List    { TestML::List->new(value => shift) }

use Carp;
sub str { my $t = $_[0]->type; confess "Cast from $t to Str is not supported" }
sub num { my $t = $_[0]->type; die "Cast from $t to Num is not supported" }
sub bool { my $t = $_[0]->type; die "Cast from $t to Bool is not supported" }
sub list { my $t = $_[0]->type; die "Cast from $t to List is not supported" }

#-----------------------------------------------------------------------------
package TestML::Str;
use TestML::Object -base;

has 'type' => 'Str';

sub str { shift }
sub num { $_[0]->value =~ /^-?\d+(?:\.\d+)$/ ? ($_[0]->value + 0) : 0 }
sub bool { TestML::Bool->new(value => length($_[0]->value) ? 1 : 0) }
sub list { List([split //, $_[0]->value]) }

#-----------------------------------------------------------------------------
package TestML::Num;
use TestML::Object -base;

has 'type' => 'Num';

sub str { TestML::Str->new($_[0]->value . "") }
sub num { shift }
sub bool { TestML::Bool->new(value => ($_[0]->value != 0)) }
sub list { my $list = []; $#{$list} = int($_[0]) -1; TestML::List->new($list) }

#-----------------------------------------------------------------------------
package TestML::Bool;
use TestML::Object -base;

has 'type' => 'Bool';

sub str { TestML::Str->new($_[0]->value ? "1" : "") }
sub num { TestML::Num->new($_[0]->value ? 1 : 0) }
sub bool { shift }

#-----------------------------------------------------------------------------
package TestML::List;
use TestML::Object -base;

has 'type' => 'List';

#-----------------------------------------------------------------------------
package TestML::None;
use TestML::Object -base;

has 'type' => 'None';

sub str { Str('') }
sub num { Num(0) }
sub bool { Bool(0) }
sub list { List([]) }

#-----------------------------------------------------------------------------
package TestML::Error;
use TestML::Object -base;

has 'type' => 'Error';

#-----------------------------------------------------------------------------
package TestML::Code;
use TestML::Object -base;

has 'type' => 'Code';

# #-----------------------------------------------------------------------------
# package TestML::Native;
# use TestML::Object -base;
# 
# has 'type' => 'Func';
# 

package TestML::AST;

our $True = TestML::Bool->new(value => 1);
our $False = TestML::Bool->new(value => 0);
our $None = TestML::None->new;

