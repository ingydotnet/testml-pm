package TestML::Runtime::TAP;
use TestML::Runtime -base;

use Test::Builder;

has 'test_builder' => -init => 'Test::Builder->new';

sub title {
    my $self = shift;
    if (my $title = $self->namespace->{Title}) {
        $self->test_builder->note("=== $title ===\n");
    }
}

sub plan_begin {
    my $self = shift;
    if (defined (my $tests = $self->namespace->{Plan})) {
        $self->test_builder->plan(tests => $tests);
    }
    else {
        $self->test_builder->no_plan();
    }
}

sub assert_EQ {
    my $self = shift;
    $self->test_builder->is_eq(
        shift->as_str,
        shift->as_str,
        $self->get_label,
    );
}

sub assert_HAS {
    my $self = shift;
    my $assertion = (index shift->value, shift->value) >= 0;
    $self->test_builder->ok($assertion, $self->get_label);
}

sub assert_OK {
    my $self = shift;
    my $context = shift;
    $self->test_builder->ok($context->as_bool, $self->get_label);
}

1;
