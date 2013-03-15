package TestML::Runtime;
use TestML::Base;

has testml => ();                       # Top level TestML document to run.
has bridge => ();                       # Bridge class to use.
has library => ();                      # Library classes to use.
has compiler => ();                     # Class of TestML compiler to use.
has base => ();
has skip => ();                         # This test should be skipped.

has function => ();                     # Currently running function.
has error => ();                        # Current exception
has global => ();                       # Global namespace

sub BUILD {
    my ($self) = @_;
    # Put current Runtime singleton object into a global variable.
    $TestML::Runtime::singleton = $self;
    $self->{base} ||= $0 =~ m!(.*)/! ? $1 : ".";
}

sub run {
    my ($self) = @_;

    $self->compile_testml;
    $self->initialize_runtime;

    $self->run_function(
        $self->{function},  # top level testml function
        undef,              # context
        [],                 # function arguments
    );
}

sub run_function {
    my ($self, $function, $args) = @_;

    $self->apply_signature($function, $args);

    my $parent = $self->function;
    $self->function($function);

    for my $statement (@{$function->statements}) {
        if (ref($statement) eq 'TestML::Assignment') {
            $self->run_assignment($statement);
        }
        else {
            $self->run_statement($statement);
        }
    }
    $self->function($parent);
    return TestML::None->new;
}

sub apply_signature {
    my ($self, $function, $args) = @_;
    my $signature = $function->signature;

    die sprintf(
        "Function received %d args but expected %d",
        scalar(@$args),
        scalar(@$signature),
    ) if @$signature and @$args != @$signature;

    $function->setvar('Self', $function);
    for (my $i = 0; $i < @$signature; $i++) {
        my $arg = $args->[$i];
        $arg = $self->run_expression($arg)
            if ref($arg) eq 'TestML::Expression';
        $function->setvar($signature->[$i], $arg);
    }
}

sub run_statement {
    my ($self, $statement) = @_;
    my $blocks = $self->select_blocks($statement->points);
    for my $block (@$blocks) {
        $self->function->setvar('Block', $block) if ref($block);
        my $result = $self->run_expression($statement->expr);
        if (my $assert = $statement->assert) {
            $self->run_assertion($result, $assert);
        }
    }
}

sub run_assignment {
    my ($self, $statement) = @_;
    $self->function->setvar(
        $statement->name,
        $self->run_expression($statement->expr),
    );
}

sub run_assertion {
    my ($self, $left, $assert) = @_;
    my $method = 'assert_' . $assert->name;

    $self->function->getvar('TestNumber')->{value}++;

    if ($assert->expr) {
        $self->$method($left, $self->run_expression($assert->expr));
    }
    else {
        $self->$method($left);
    }
}

sub run_expression {
    my ($self, $expr) = @_;

    my $context = undef;
    $self->{error} = undef;
    if ($expr->isa('TestML::Expression')) {
        my @calls = @{$expr->calls};
        die if @calls <= 1;
        $context = $self->run_call(shift(@calls), undef);
        for my $call (@calls) {
            if ($self->error) {
                next unless
                    $call->isa('TestML::Call') and
                    $call->name eq 'Catch';
            }
            $context = $self->run_call($call, $context);
        }
    }
    else {
        $context = $self->run_call($expr);
    }
    if ($self->error) {
        die $self->error;
    }
    return $context;
}

sub run_call {
    my ($self, $call, $context) = @_;

    if ($call->isa('TestML::Object')) {
        return $call;
    }
    if ($call->isa('TestML::Function')) {
        return $call;
    }
    if ($call->isa('TestML::Point')) {
        return $self->get_point($call->name);
    }
    if ($call->isa('TestML::Call')) {
        my $name = $call->name;
        my $callable =
            $self->function->getvar($name) ||
            $self->get_point($name) ||
            $self->lookup_callable($name)
                or die "Can't locate '$name' callable";
        if ($callable->isa('TestML::Object')) {
            return $callable;
        }
        return $callable unless $call->args or defined $context;
        $call->{args} ||= [];
        my $args = [map $self->run_expression($_), @{$call->args}];
        unshift @$args, $context if $context;
        if ($callable->isa('TestML::Native')) {
            return $self->run_native($callable, $args);
        }
        if ($callable->isa('TestML::Function')) {
            return $self->run_function($callable, $args);
        }
        XXX $call, $callable;
    }
    XXX $call;
}

sub lookup_callable {
    my ($self, $name) = @_;
    for my $library (@{$self->function->getvar('Library')->value}) {
        if ($library->can($name)) {
            my $function = sub { $library->$name(@_) };
            my $callable = TestML::Native->new(value => $function);
            $self->function->setvar($name, $callable);
            return $callable;
        }
    }
    return;
}

sub get_point {
    my ($self, $name) = @_;
    my $value = $self->function->getvar('Block')->{points}{$name}
        or return;
    if ($value =~ s/\n+\z/\n/ and $value eq "\n") {
        $value = '';
    }
    return TestML::Str->new(value => $value);
}

sub run_native {
    my ($self, $native, $args) = @_;
    my $value = eval {
        $native->value->(@$args)
    };
    if ($@) {
        $self->{error} = $@;
        return TestML::None->new;
    }
    elsif (UNIVERSAL::isa($value, 'TestML::Object')) {
        return $value;
    }
    else {
        return $self->object_from_native($value);
    }
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
        $testml =~ /(.*)\/(.*)/ or die;
        $testml = $2;
        $self->{base} = $self->base . '/' . $1;
        $self->{testml} = $self->read_testml_file($testml);
    }

    my $compiler = $self->compiler;
    eval "require $compiler; 1" or die "Can't load '$compiler':\n$@";
    $self->{function} = $compiler->new->compile($self->testml)
        or die "TestML document failed to compile";
}

sub initialize_runtime {
    my ($self) = @_;
    my $global = $self->{global} = $self->function->outer;

    # Set global variables.
    $global->setvar(Block => TestML::Block->new);
    $global->setvar(Label => TestML::Str->new(value => '$BlockLabel'));
    $global->setvar(True => $TestML::Constant::True);
    $global->setvar(False => $TestML::Constant::False);
    $global->setvar(None => $TestML::Constant::None);
    $global->setvar(TestNumber => TestML::Num->new(value => 0));
    $global->setvar(Library => TestML::List->new);

    for my $lib ($self->bridge, $self->library) {
        if (ref($lib) eq 'ARRAY') {
            $self->add_library($_) for @$lib;
        }
        else {
            $self->add_library($lib);
        }
    }
}

sub add_library {
    my ($self, $library) = @_;
    if (not $library->can('new')) {
        eval "require $library";
    }
    $self->function->getvar('Library')->push($library);
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
use TestML::Base;

has type => 'Func';     # Functions are TestML typed objects
has signature => [];    # Input variable names
has namespace => {};    # Lexical scoped variable stash
has statements => [];   # Exexcutable code statements
has data => [];         # Data section scoped to this function

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
    return $value;
}

sub forgetvar {
    my ($self, $name) = @_;
    return delete $self->namespace->{$name};
}

#-----------------------------------------------------------------------------
package TestML::Assignment;
use TestML::Base;

has name => ();
has expr => ();

#-----------------------------------------------------------------------------
package TestML::Statement;
use TestML::Base;

has expr => sub {TestML::Expression->new};
has assert => ();
has points => [];

#-----------------------------------------------------------------------------
package TestML::Expression;
use TestML::Base;

has calls => [];

#-----------------------------------------------------------------------------
package TestML::Assertion;
use TestML::Base;

has name => ();
has expr => ();

#-----------------------------------------------------------------------------
package TestML::Call;
use TestML::Base;

has name => ();
has args => ();
has explicit_call => 0;

#-----------------------------------------------------------------------------
package TestML::Block;
use TestML::Base;

has label => '';
has points => {};

#-----------------------------------------------------------------------------
package TestML::Point;
use TestML::Base;

has name => ();

#-----------------------------------------------------------------------------
package TestML::Object;
use TestML::Base;

has value => ();

sub type {
    my $type = ref($_[0]);
    $type =~ s/^TestML::// or die "Can't find type of '$type'";
    return $type;
}

sub str { my $t = $_[0]->type; die "Cast from $t to Str is not supported" }
sub num { my $t = $_[0]->type; die "Cast from $t to Num is not supported" }
sub bool { my $t = $_[0]->type; die "Cast from $t to Bool is not supported" }
sub list { my $t = $_[0]->type; die "Cast from $t to List is not supported" }
sub none { $TestML::Constant::None }

#-----------------------------------------------------------------------------
package TestML::Str;
use TestML::Base;
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
use TestML::Base;
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
use TestML::Base;
extends 'TestML::Object';

sub str { TestML::Str->new(value => $_[0]->value ? "1" : "") }
sub num { TestML::Num->new(value => $_[0]->value ? 1 : 0) }
sub bool { $_[0] }

#-----------------------------------------------------------------------------
package TestML::List;
use TestML::Base;
extends 'TestML::Object';
has value => [];
sub list { $_[0] }
sub push {
    my ($self, $elem) = @_;
    push @{$self->value}, $elem;
}

#-----------------------------------------------------------------------------
package TestML::None;
use TestML::Base;
extends 'TestML::Object';

sub str { Str('') }
sub num { Num(0) }
sub bool { $TestML::Constant::False }
sub list { List([]) }

#-----------------------------------------------------------------------------
package TestML::Error;
use TestML::Base;
extends 'TestML::Object';

#-----------------------------------------------------------------------------
package TestML::Native;
use TestML::Base;
has value => ();

#-----------------------------------------------------------------------------
package TestML::Constant;

our $True = TestML::Bool->new(value => 1);
our $False = TestML::Bool->new(value => 0);
our $None = TestML::None->new;

1;
