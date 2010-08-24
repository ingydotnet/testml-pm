package TestML::Runtime::TAP;
use TestML::Runtime -base;

use Test::Builder;

has 'test_builder' => -init => 'Test::Builder->new';

sub title {
    my $self = shift;
    if (my $title = $self->document->meta->data->{Title}) {
        $self->test_builder->note("=== $title ===\n");
    }
}

sub plan_begin {
    my $self = shift;
    if (my $tests = $self->document->meta->data->{Plan}) {
        $self->test_builder->plan(tests => $tests);
    }
    else {
        $self->test_builder->no_plan();
    }
}

sub assert_EQ {
    my $self = shift;
    my $left = shift;
    my $right = shift;
    my $left_type = $left->type;
    my $right_type = $right->type;
    die(
        "Assertion type error: left side is '$left_type' and right side is '$right_type'"
    ) unless $left_type eq $right_type;
    return $self->assert_EQ_list($left, $right)
        if $left_type eq 'List';
    $self->test_builder->is_eq(
        $left->get_value_as_str,
        $right->get_value_as_str,
        $self->get_label,
    );
}

sub assert_HAS {
    my $self = shift;
    my $left = shift;
    my $right = shift;
    my $left_type = $left->type;
    my $right_type = $right->type;
    $self->throw(
        "HAS assertion requires left and right side types be 'Str'.\n" .
        "Left side is '$left_type' and right side is '$right_type'"
    ) unless $left_type eq 'Str' and $left_type eq $right_type;
    my $assertion = (index $left->value, $right->value) >= 0;
    $self->test_builder->ok($assertion, $self->get_label);
}

sub assert_OK {
    my $self = shift;
    my $context = shift;
    $self->test_builder->ok($context->get_value_as_bool, $self->get_label);
}

1;
