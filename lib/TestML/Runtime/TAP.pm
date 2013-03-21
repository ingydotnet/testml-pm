use Test::Builder;
use TestML::Runtime;

package TestML::Runtime::TAP;
use TestML::Base;
extends 'TestML::Runtime';

has test_framework => sub { Test::Builder->new };
has planned => 0;

sub run {
    my ($self) = @_;
    $self->SUPER::run;
    $self->check_plan;
    $self->plan_end;
}

sub run_assertion {
    my ($self, @args) = @_;
    $self->check_plan;
    $self->SUPER::run_assertion(@args);
}

sub check_plan {
    my ($self) = @_;
    if (! $self->planned) {
        $self->title;
        $self->plan_begin;
        $self->{planned} = 1;
    }
}

sub title {
    my ($self) = @_;
    if (my $title = $self->function->getvar('Title')) {
        $title = $title->value;
        $title = "=== $title ===\n";
        $self->test_framework->note($title);
    }
}

sub skip_test {
    my ($self, $reason) = @_;
    $self->test_framework->plan(skip_all => $reason);
}

sub plan_begin {
    my ($self) = @_;
    if (my $tests = $self->function->getvar('Plan')) {
        $self->test_framework->plan(tests => $tests->value);
    }
}

sub plan_end {
    my ($self) = @_;
    $self->test_framework->done_testing();
}

# TODO Use Test::Diff here.
sub assert_EQ {
    my ($self, $got, $want) = @_;
    $self->test_framework->is_eq(
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
        $self->test_framework->diag($msg);
    }
    $self->test_framework->ok($assertion, $self->get_label);
}

sub assert_OK {
    my ($self, $got) = @_;
    $self->test_framework->ok(
        $got->bool->value,
        $self->get_label,
    );
}

1;
