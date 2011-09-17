package TestML::Runtime;
use TestML::Mo;

use TestML::Compiler;

# Since there is only ever one test runtime, it makes things a LOT cleaner to
# keep the reference to it in a global variable accessed by a method, than to
# put a reference to it into every object that needs to access it.
our $self;

has base => default => sub {$0 =~ m!(.*)/! ? $1 : "."};   # Base directory
has testml => ();       # TestML document filename, handle or text
has bridge => ();       # Bridge transform module

# XXX Add TestML.pm support for -library keyword.
has library => default => sub {[]};    # Transform library modules

has function => ();         # Current function executing
has planned => default => sub {0};     # plan() has been called
has test_number => default => sub {0}; # Number of tests run so far

sub BUILD {
    my $self = $TestML::Runtime::self = shift;
    $self->function($self->compile_testml);
    $self->load_variables;
    $self->load_transform_module('TestML::Library::Standard');
    $self->load_transform_module('TestML::Library::Debug');
    if ($self->bridge) {
        $self->load_transform_module($self->bridge);
    }
}

# XXX Move to TestML::Adapter
sub title { }
sub plan_begin { }
sub plan_end { }

sub run {
    my $self = shift;

    my $function = $self->function;
    my $context = TestML::None->new;
    my $args = [];

    $self->run_function($self->function, $context, $args);

    $self->run_plan();
    $self->plan_end();
}

# XXX - TestML exception handling needs to happen at the function level, not
# just at the expression level. Not yet handled here.
sub run_function {
    my $self = shift;
    my $function = shift;
    my $context = shift;
    my $args = shift;

    my $signature = $function->signature;
    die sprintf(
        "Function received %d args but expected %d",
        scalar(@$args),
        scalar(@$signature),
    ) if @$signature and @$args != @$signature;
    $function->setvar('Self', $context);
    for (my $i = 0; $i < @$signature; $i++) {
        my $arg = $args->[$i];
        $arg = $self->run_expression($arg)
            if ref($arg) eq 'TestML::Expression';
        $function->setvar($signature->[$i], $arg);
    }

    my $parent = $self->function;
    $self->function($function);

    for my $statement (@{$function->statements}) {
        $self->run_statement($statement);
    }

    $self->function($parent);

    return TestML::None->new;
}

sub run_statement {
    my $self = shift;
    my $statement = shift;
    my $blocks = @{$statement->points}
        ? $self->select_blocks($statement->points)
        : [1];
    for my $block (@$blocks) {
        $self->function->setvar('Block', $block) if ref($block);
        my $context = $self->run_expression($statement->expression);
        if (my $assertion = $statement->assertion) {
            $self->run_assertion($context, $assertion);
        }
    }
}

sub run_assertion {
    my $self = shift;
    my $left = shift;
    my $assertion = shift;
    my $method = 'assert_' . $assertion->name;

    # Run this as late as possible.
    $self->run_plan;

    $self->test_number($self->test_number + 1);
    $self->function->setvar(
        TestNumber => TestML::Num->new(value => $self->test_number),
    );

    # TODO - Should check 
    my $results = ($left->type eq 'List')
        ? $left->value
        : [ $left ];
    for my $result (@$results) {
        if (@{$assertion->expression->units}) {
            my $right = $self->run_expression($assertion->expression);
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

sub run_expression {
    my $self = shift;
    my $prev_expression = $self->function->expression;
    my $expression = shift;
    $self->function->expression($expression);

    my $units = $expression->units;
    my $context = TestML::None->new;

    for (my $i = 0; $i < @$units; $i++) {
        my $unit = $units->[$i];
        if ($expression->error) {
            next unless
                $unit->isa('TestML::Transform') and
                $unit->name eq 'Catch';
        }
        if ($unit->isa('TestML::Object')) {
            $context = $unit;
            next;
        }
        if ($unit->isa('TestML::Function')) {
            $context = $unit;
            next;
        }
        die "Unexpected unit: $unit" unless $unit->isa('TestML::Transform');
        my $callable = $self->function->getvar($unit->name)
            or die "Can't find transform '${\$unit->name}'";
        my $args = $unit->args;
        if ($callable->isa('TestML::Native')) {
            $context = $self->run_native($callable->value, $context, $args);
        }
        elsif ($callable->isa('TestML::Object')) {
            $context = $callable;
        }
        elsif ($callable->isa('TestML::Function')) {
            if ($i or $unit->explicit_call) {
                my $points = $self->function->getvar('Block')->points;
                for my $key (keys %$points) {
                    $callable->setvar($key, TestML::Str->new(value => $points->{$key}));
                }
                $context = $self->run_function($callable, $context, $args);
            }
            $context = $callable;
        }
        else {
            ZZZ $expression, $unit, $callable;
        }
    }
    if ($expression->error) {
        die $expression->error;
    }
    $self->function->expression($prev_expression);
    return $context;
}

sub run_native {
    my $self = shift;
    my $function = shift;
    my $context = shift;
    my $args = shift;
    my $value = eval {
        &$function(
            $context,
            map {
                (ref($_) eq 'TestML::Expression')
                ? $self->run_expression($_)
                : $_
            } @$args
        );
    };
    if ($@) {
        $self->function->expression->error($@);
        $context = TestML::Error->new(value => $@);
    }
    elsif (UNIVERSAL::isa($value, 'TestML::Object')) {
        $context = $value;
    }
    else {
        $context = $self->object_from_native($value);
    }
    return $context;
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

sub object_from_native {
    my $self = shift;
    my $value = shift;
    return
        not(defined $value) ? TestML::None->new :
        ref($value) eq 'ARRAY' ? TestML::List->new(value => $value) :
        $value =~ /^-?\d+$/ ? TestML::Num->new(value => $value + 0) :
        "$value" eq "$TestML::Constant::True" ? $value :
        "$value" eq "$TestML::Constant::False" ? $value :
        "$value" eq "$TestML::Constant::None" ? $value :
        TestML::Str->new(value => $value);
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
    my $global = $self->function->outer;
    $global->setvar(Block => TestML::Block->new);
    $global->setvar(Label => TestML::Str->new(value => '$BlockLabel'));
    $global->setvar(True => $TestML::Constant::True);
    $global->setvar(False => $TestML::Constant::False);
    $global->setvar(None => $TestML::Constant::None);
}

sub load_transform_module {
    my $self = shift;
    my $module_name = shift;
    if ($module_name ne 'main') {
        eval "require $module_name; 1"
            or die "Can't use $module_name:\n$@";
    }

    my $global = $self->function->outer;
    no strict 'refs';
    for my $key (sort keys %{"$module_name\::"}) {
        next if $key eq "\x16";
        my $glob = ${"$module_name\::"}{$key};
        if (my $function = *$glob{CODE}) {
            $global->setvar(
                $key => TestML::Native->new(value => $function),
            );
        }
        elsif (my $object = *$glob{SCALAR}) {
            if (ref($$object)) {
                $global->setvar($key => $$object);
            }
        }
    }
}

sub get_label {
    my $self = shift;
    my $label = $self->function->getvar('Label')->value;
    sub label {
        my $self = shift;
        my $var = shift;
        my $block = $self->function->getvar('Block');
        return $block->label if $var eq 'BlockLabel';
        if (my $v = $block->points->{$var}) {
            $v =~ s/\n.*//s;
            $v =~ s/^\s*(.*?)\s*$/$1/;
            return $v;
        }
        if (my $v = $self->function->getvar($var)) {
            return $v->value;
        }
    }
    $label =~ s/\$(\w+)/label($self, $1)/ge;
    return $label ? ($label) : ();
}

sub run_plan {
    my $self = shift;
    if (! $self->planned) {
        $self->title();
        $self->plan_begin();
        $self->planned(1);
    }
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
use TestML::Mo;

has type => default => sub {'Func'};        # Functions are TestML typed objects
# XXX Make this a featherweight reference.
has signature => default => sub {[]};       # Input variable names
has namespace => default => sub {{}};       # Lexical scoped variable stash
has statements => default => sub {[]};      # Exexcutable code statements
has data => default => sub{[]};             # Data section scoped to this function

# Runtime pointers to current objects.
has expression => ();
has block => ();

my $outer = {};
sub outer { @_ == 1 ? $outer->{$_[0]} : ($outer->{$_[0]} = $_[1]) }

sub getvar {
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

sub setvar {
    my $self = shift;
    my $name = shift;
    my $object = shift;
    $self->namespace->{$name} = $object;
    return;
}

sub forgetvar {
    my $self = shift;
    my $name = shift;
    delete $self->namespace->{$name};
    return;
}

#-----------------------------------------------------------------------------
package TestML::Statement;
use TestML::Mo;

has expression => default => sub {TestML::Expression->new};
has assertion => ();
has points => default => sub {[]};

#-----------------------------------------------------------------------------
package TestML::Expression;
use TestML::Mo;

has units => default => sub {[]};
has error => ();

#-----------------------------------------------------------------------------
package TestML::Assertion;
use TestML::Mo;

has name => ();
has expression => default => sub {TestML::Expression->new};

#-----------------------------------------------------------------------------
package TestML::Transform;
use TestML::Mo;

has name => ();
has args => default => sub {[]};
has explicit_call => default => 0;

#-----------------------------------------------------------------------------
package TestML::Block;
use TestML::Mo;

has label => default => sub {''};
has points => default => sub {{}};

#-----------------------------------------------------------------------------
package TestML::Object;
use TestML::Mo;

has value => ();

sub type {
    my $type = ref(shift);
    $type =~ s/^TestML::// or die "Can't find type of '$type'";
    return $type;
}

sub runtime { return $TestML::Runtime::self }

sub str { my $t = $_[0]->type; die "Cast from $t to Str is not supported" }
sub num { my $t = $_[0]->type; die "Cast from $t to Num is not supported" }
sub bool { my $t = $_[0]->type; die "Cast from $t to Bool is not supported" }
sub list { my $t = $_[0]->type; die "Cast from $t to List is not supported" }
sub none { $TestML::Constant::None }

#-----------------------------------------------------------------------------
package TestML::Str;
use TestML::Mo;
extends 'TestML::Object';

sub str { shift }
sub num { TestML::Num->new(
    value => ($_[0]->value =~ /^-?\d+(?:\.\d+)$/ ? ($_[0]->value + 0) : 0),
)}
sub bool {
    length($_[0]->value) ? $TestML::Constant::True : $TestML::Constant::False
}
sub list { TestML::List->new(value => [split //, $_[0]->value]) }

#-----------------------------------------------------------------------------
package TestML::Num;
use TestML::Mo;
extends 'TestML::Object';

sub str { TestML::Str->new(value => $_[0]->value . "") }
sub num { shift }
sub bool { ($_[0]->value != 0) ? $TestML::Constant::True : $TestML::Constant::False }
sub list {
    my $list = [];
    $#{$list} = int($_[0]) -1;
    TestML::List->new(value =>$list);
}

#-----------------------------------------------------------------------------
package TestML::Bool;
use TestML::Mo;
extends 'TestML::Object';

sub str { TestML::Str->new(value => $_[0]->value ? "1" : "") }
sub num { TestML::Num->new(value => $_[0]->value ? 1 : 0) }
sub bool { shift }

#-----------------------------------------------------------------------------
package TestML::List;
use TestML::Mo;
extends 'TestML::Object';
sub list { shift }

#-----------------------------------------------------------------------------
package TestML::None;
use TestML::Mo;
extends 'TestML::Object';

sub str { Str('') }
sub num { Num(0) }
sub bool { $TestML::Constant::False }
sub list { List([]) }

#-----------------------------------------------------------------------------
package TestML::Error;
use TestML::Mo;
extends 'TestML::Object';

#-----------------------------------------------------------------------------
package TestML::Native;
use TestML::Mo;
extends 'TestML::Object';

package TestML::Constant;

our $True = TestML::Bool->new(value => 1);
our $False = TestML::Bool->new(value => 0);
our $None = TestML::None->new;

