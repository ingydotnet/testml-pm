package TestML::Runner::TAP;
use strict;
use warnings;

use TestML::Runner -base;

use Test::Builder;

field 'test_builder' => -init => 'Test::Builder->new';

sub init_bridge {
    my $self = shift;

    local @INC = ('t', 't/lib', @INC);
    my $class = $self->bridge;
    if ($class ne 'main') {
        eval "require $class";
        die "Error loading bridge class '$class': $@" if $@;
    }

    return $class->new();
}

sub title {
    my $self = shift;
    if (my $title = $self->doc->meta->data->{Title}) {
        print "=== $title ===\n";
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

sub plan_end {
}

# TODO - Refactor so that standard lib finds this comparison through EQ
sub do_test {
    my $self = shift;
    my $operator = shift;
    my $left = shift;
    my $right = shift;
    my $label = shift;
    if ($operator eq 'EQ') {
        $self->test_builder->is_eq($left->value, $right->value, $label);
    }
}

1;
