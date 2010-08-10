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

sub assert_EQ {
    my $self = shift;
    my $left = shift;
    my $right = shift;
    my @label = grep $_, @_;
    $self->test_builder->is_eq($left->value, $right->value, @label);
}

sub assert_HAS {
    my $self = shift;
    my $left = shift;
    my $right = shift;
    my @label = grep $_, @_;
    my $assertion = (index $left->value, $right->value) >= 0;
    $self->test_builder->ok($assertion, @label);
}

use XXX;
sub assert_OK {
    my $self = shift;
    my $left = shift;
    my @label = grep $_, @_;
    my $assertion = $left->value;
    $self->test_builder->ok($assertion, @label);
}

1;
