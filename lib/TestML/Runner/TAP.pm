package TestML::Runner::TAP;
use strict;
use warnings;

use TestML::Runner -base;

use Test::Builder;

has 'test_builder' => -init => 'Test::Builder->new';

sub title {
    my $self = shift;
    if (my $title = $self->doc->meta->data->{Title}) {
        $self->test_builder->note("=== $title ===\n");
    }
}

sub plan_begin {
    my $self = shift;
    if (my $tests = $self->doc->meta->data->{Plan}) {
        $self->test_builder->plan(tests => $tests);
    }
    else {
        $self->test_builder->no_plan();
    }
}

# List Str Num Bool
sub assert_EQ {
    my $self = shift;
    my $left = shift;
    my $right = shift;
    my $left_type = $left->type;
    my $right_type = $right->type;
    $self->throw(
        "Assertion type error: left side is '$left_type' and right side is '$right_type'"
    ) unless $left_type eq $right_type;
    my @label = grep $_, @_;
    return $self->assert_EQ_list($left, $right, @label)
        if $left_type eq 'List';
    $self->test_builder->is_eq($left->value, $right->value, @label);
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
    ) unless $left_type eq $right_type;
    my @label = grep $_, @_;
    my $assertion = (index $left->value, $right->value) >= 0;
    $self->test_builder->ok($assertion, @label);
}

sub assert_OK {
    my $self = shift;
    my $context = shift;
    my @label = grep $_, @_;
    my $assertion = $context->get_value_as_bool ^ $context->not;
    $self->test_builder->ok($assertion, @label);
}

1;
