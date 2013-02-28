package TestML::Runtime;
use TestML::Mo;

has testml => ();
has bridge => 'main';
has library => [
    'TestML::Library::Standard',
    'TestML::Library::Debug',
];
has compiler => 'TestML::Compiler';
has base => sub { $0 =~ m!(.*)/! ? $1 : "." };
has skip => 0;
has required => [];

has function => ();
has planned => 0;
has test_number => 0;

# Since there is only ever one test runtime, it makes things a LOT cleaner to
# keep the reference to it in a global variable accessed by a method, than to
# put a reference to it into every object that needs to access it.
our $self;
sub BUILD {
    # Put current Runtime singleton object into a global variable.
    $TestML::Runtime::self = $_[0];
}

# Default methods for Runtimes that don't support these things:
# TODO May wish to emulate them by default.
sub title { }
sub plan_begin { }
sub plan_end { }

sub run {
    my ($self) = @_;

    $self->compile_testml;
    $self->initialize_global_namespace;
    $self->setup_library_objects;

    $self->run_function(
        $self->{function},  # top level testml function
        TestML::None->new,  # context
        [],                 # function arguments
    );

    # TODO Review the plan stuff
    $self->run_plan();
    $self->plan_end();
}

# XXX - TestML exception handling needs to happen at the function level, not
# just at the expression level. Not yet handled here.
sub run_function {
    my ($self, $function, $context, $args) = @_;

    # TODO Move signature processing to separate method
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
    my ($self, $statement) = @_;
    my $blocks = $self->select_blocks($statement->points);
    for my $block (@$blocks) {
        $self->function->setvar('Block', $block) if ref($block);
        my $result = $self->run_expression($statement->expression);
        if (my $assertion = $statement->assertion) {
            $self->run_assertion($result, $assertion);
        }
    }
}

sub run_assertion {
    my ($self, $left, $assertion) = @_;
    my $method = 'assert_' . $assertion->name;

    # Run this as late as possible.
    $self->run_plan;

    $self->{test_number}++;
    $self->function->setvar(
        TestNumber => TestML::Num->new(value => $self->test_number),
    );

    # TODO Review this List stuff
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

# TODO Simplify this
sub run_expression {
    my ($self, $expression) = @_;

    my $prev_expression = $self->function->expression;
    $self->function->expression($expression);

    my $units = $expression->units;
    my $context = TestML::None->new;

    for (my $i = 0; $i < @$units; $i++) {
        my $unit = $units->[$i];
        if ($expression->error) {
            next unless
                $unit->isa('TestML::Call') and
                $unit->name eq 'Catch';
        }
        if ($unit->isa('TestML::Point')) {
            $context = $self->get_point($unit->name);
            next;
        }
        if ($unit->isa('TestML::Object')) {
            $context = $unit;
            next;
        }
        if ($unit->isa('TestML::Function')) {
            $context = $unit;
            next;
        }
        die "Unexpected unit: $unit" unless $unit->isa('TestML::Call');
        my $callable = $self->function->getvar($unit->name)
            or die "Can't find callable '${\$unit->name}'";
        my $args = [
            map {
                $_->isa('TestML::Point')
                    ? $self->get_point($_->name) :
                $_->isa('TestML::Variable')
                    ? $self->function->getvar($_->name) :
                $_;
            } @{$unit->args}
        ];
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

sub get_point {
    my ($self, $point) = @_;
    my $value = $self->function->getvar('Block')->{points}{$point};
    if ($value =~ s/\n+\z/\n/ and $value eq "\n") {
        $value = '';
    }
    return TestML::Str->new(value => $value);
}

sub run_native {
    my ($self, $function, $context, $args) = @_;
    $args = [
        map {
            (ref($_) eq 'TestML::Expression')
            ? $self->run_expression($_)
            : $_
        } @$args
    ];
    unshift @$args, $context if $context;
    my $value = eval {
        &$function(@$args)
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
    my ($self, $wanted) = @_;
    return [1] unless @$wanted;
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
    my ($self, $value) = @_;
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
    my ($self) = @_;

    my $testml = $self->testml
        or die "'testml' document required but not found";
    if ($testml !~ /\n/) {
        my $base = $self->base;
        $testml =~ s/(.*)\/(.*)/$2/ or die;
        $testml = $2;
        $self->{base} = "$base/$1";
        $self->{testml} = $self->read_testml_file($testml);
    }

    my $compiler = $self->compiler;
    eval "require $compiler; 1" or die "Can't load '$compiler'";
    my $function = $compiler->new(
        runtime => $self,
    )->compile($self->testml)
        or die "TestML document failed to compile";
    $self->{function} = $function;
}

sub initialize_global_namespace {
    my ($self) = @_;
    my $global = $self->function->outer;
    $global->setvar(Block => TestML::Block->new);
    $global->setvar(Label => TestML::Str->new(value => '$BlockLabel'));
    $global->setvar(True => $TestML::Constant::True);
    $global->setvar(False => $TestML::Constant::False);
    $global->setvar(None => $TestML::Constant::None);
}

sub setup_library_objects {
    my ($self) = @_;
    if ($self->bridge) {
        $self->load_call_module($self->bridge);
    }
    $self->load_call_module('TestML::Library::Standard');
    $self->load_call_module('TestML::Library::Debug');
}

sub load_call_module {
    my ($self, $module_name) = @_;
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
    my ($self) = @_;
    my $label = $self->function->getvar('Label')->value;
    sub label {
        my ($self, $var) = @_;
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
    my ($self) = @_;
    if (! $self->planned) {
        $self->title();
        $self->plan_begin();
        $self->planned(1);
    }
}

sub get_error {
    my ($self) = @_;
    return $self->function->expression->error;
}

sub clear_error {
    my ($self) = @_;
    return $self->function->expression->error(undef);
}

sub throw {
    require Carp;
    Carp::croak $_[1];
}

sub read_testml_file {
    my ($self, $file) = @_;
    my $path = join '/', $self->base, $file;
    open my $fh, $path
        or die "Can't open '$path' for input: $!";
    local $/;
    return <$fh>;
}

#-----------------------------------------------------------------------------
package TestML::Function;
use TestML::Mo;
# XXX should extend TestML::Object (maybe).

has type => 'Func';     # Functions are TestML typed objects
has signature => [];    # Input variable names
has namespace => {};    # Lexical scoped variable stash
has statements => [];   # Exexcutable code statements
has data => [];         # Data section scoped to this function

# Runtime pointers to current objects.
has expression => ();
has block => ();

my $outer = {};
sub outer { @_ == 1 ? $outer->{$_[0]} : ($outer->{$_[0]} = $_[1]) }

sub getvar {
    my ($self, $name) = @_;
    while ($self) {
        if (my $object = $self->namespace->{$name}) {
            return $object;
        }
        $self = $self->outer;
    }
    return;
}

sub setvar {
    my ($self, $name, $value) = @_;
    $self->namespace->{$name} = $value;
    return;
}

sub forgetvar {
    my ($self, $name) = @_;
    delete $self->namespace->{$name};
    return;
}

#-----------------------------------------------------------------------------
package TestML::Statement;
use TestML::Mo;

has expression => sub {TestML::Expression->new};
has assertion => ();
has points => [];

#-----------------------------------------------------------------------------
package TestML::Expression;
use TestML::Mo;

has units => [];
has error => ();

#-----------------------------------------------------------------------------
package TestML::Assertion;
use TestML::Mo;

has name => ();
has expression => sub {TestML::Expression->new};

#-----------------------------------------------------------------------------
package TestML::Call;
use TestML::Mo;

has name => ();
has args => [];
has explicit_call => 0;

#-----------------------------------------------------------------------------
package TestML::Block;
use TestML::Mo;

has label => '';
has points => {};

#-----------------------------------------------------------------------------
package TestML::Point;
use TestML::Mo;

has name => ();

#-----------------------------------------------------------------------------
package TestML::Variable;
use TestML::Mo;

has name => ();

#-----------------------------------------------------------------------------
package TestML::Object;
use TestML::Mo;

has value => ();

sub type {
    my $type = ref($_[0]);
    $type =~ s/^TestML::// or die "Can't find type of '$type'";
    return $type;
}

# XXX Move this to TestML::Library and TestML::Bridge
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

sub str { $_[0] }
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
sub num { $_[0] }
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
sub bool { $_[0] }

#-----------------------------------------------------------------------------
package TestML::List;
use TestML::Mo;
extends 'TestML::Object';
sub list { $_[0] }

#-----------------------------------------------------------------------------
# XXX Change None to Null
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
# XXX Do we want/need this?
package TestML::Native;
use TestML::Mo;
extends 'TestML::Object';

#-----------------------------------------------------------------------------
package TestML::Constant;

our $True = TestML::Bool->new(value => 1);
our $False = TestML::Bool->new(value => 0);
our $None = TestML::None->new;

