package TestML::Runtime::TAP;
use TestML::Runtime -base;

use Test::Builder;

has 'test_builder' => -init => 'Test::Builder->new';

sub title {
    my $self = shift;
    if (my $title = $self->function->namespace->{Title}) {
        $title = $title->value;
        $self->test_builder->note("=== $title ===\n");
    }
}

sub plan_begin {
    my $self = shift;
    if (defined (my $tests = $self->function->namespace->{Plan})) {
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
