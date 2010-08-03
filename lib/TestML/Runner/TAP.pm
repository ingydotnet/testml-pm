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

sub EQ {
    my $self = shift;
    my $left = shift;
    my $right = shift;
    my $label = shift;
    $self->test_builder->is_eq($left->value, $right->value, $label);
}

1;
