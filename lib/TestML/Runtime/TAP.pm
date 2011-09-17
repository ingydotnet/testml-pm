package TestML::Runtime::TAP;
use TestML::Mo;
extends 'TestML::Runtime';

use Test::Builder;

if ($TestML::Test::Differences) {
    no warnings 'redefine';
    require Test::Differences;
    *Test::Builder::is_eq = sub {
        my $self = shift;
        \&Test::Differences::eq_or_diff(@_);
    };
}

has test_builder => default => sub { Test::Builder->new };

sub title {
    my $self = shift;
    if (my $title = $self->function->getvar('Title')) {
        $title = $title->value;
        $title = "=== $title ===\n";
        if ($self->test_builder->can('note')) {
            $self->test_builder->note($title);
        }
        else {
            $self->test_builder->diag($title);
        }
    }
}

sub plan_begin {
    my $self = shift;
    if (defined (my $tests = $self->function->getvar('Plan'))) {
        $self->test_builder->plan(tests => $tests->value);
    }
    else {
        $self->test_builder->no_plan();
    }
}

sub assert_EQ {
    my $self = shift;
    $self->test_builder->is_eq(
        shift->str->value,
        shift->str->value,
        $self->get_label,
    );
}

sub assert_HAS {
    my $self = shift;
    my $text = shift->value;
    my $part = shift->value;
    my $assertion = (index($text, $part) >= 0);
    if (not $assertion) {
        my $msg = <<"...";
Failed TestML HAS (~~) assertion. This text:
'$text'
does not contain this string:
'$part'
...
        $self->test_builder->diag($msg);
    }
    $self->test_builder->ok($assertion, $self->get_label);
}

sub assert_OK {
    my $self = shift;
    my $context = shift;
    $self->test_builder->ok(
        $context->bool->value,
        $self->get_label,
    );
}
