package TestML::Runtime::TAP;
use TestML::Mo;
extends 'TestML::Runtime';

use Test::Builder;

# TODO Redo this using Unix diff. Use global $TestML::Diff.
if ($TestML::Test::Differences) {
    no warnings 'redefine';
    require Test::Differences;
    *Test::Builder::is_eq = sub {
        my ($self) = @_;
        \&Test::Differences::eq_or_diff(@_);
    };
}

has native_test => sub { Test::Builder->new };
has planned => 0;

sub add_library {
    my ($self, $library) = @_;
    if ($library eq 'main') {
        if (not @main::ISA) {
            require TestML::Bridge;
            @main::ISA = ('TestML::Bridge');
        }
    }
    $self->SUPER::add_library($library);
}

sub run {
    my ($self) = @_;
    $self->SUPER::run();
    $self->check_plan();
    $self->plan_end();
}

sub run_assertion {
    my ($self, @args) = @_;

    $self->check_plan;

    $self->SUPER::run_assertion(@args);
}

sub check_plan {
    my ($self) = @_;
    if (! $self->planned) {
        $self->title();
        $self->plan_begin();
        $self->planned(1);
    }
}

sub title {
    my ($self) = @_;
    if (my $title = $self->function->getvar('Title')) {
        $title = $title->value;
        $title = "=== $title ===\n";
        if ($self->native_test->can('note')) {
            $self->native_test->note($title);
        }
        else {
            $self->native_test->diag($title);
        }
    }
}

sub skip_test {
    my ($self, $reason) = @_;
    $self->native_test->plan(skip_all => $reason);
}

sub plan_begin {
    my ($self) = @_;
    if (my $tests = $self->function->getvar('Plan')) {
        $self->native_test->plan(tests => $tests->value);
    }
}

sub plan_end {
    my ($self) = @_;
    $self->native_test->done_testing();
}

sub assert_EQ {
    my ($self, $got, $want) = @_;
    $self->native_test->is_eq(
        $got->str->value,
        $want->str->value,
        $self->get_label,
    );
}

sub assert_HAS {
    my ($self, $got, $has) = @_;
    $got = $got->str->value;
    $has = $has->str->value;
    my $assertion = (index($got, $has) >= 0);
    if (not $assertion) {
        my $msg = <<"...";
Failed TestML HAS (~~) assertion. This text:
'$got'
does not contain this string:
'$has'
...
        $self->native_test->diag($msg);
    }
    $self->native_test->ok($assertion, $self->get_label);
}

sub assert_OK {
    my ($self, $got) = @_;
    $self->native_test->ok(
        $got->bool->value,
        $self->get_label,
    );
}

1;
