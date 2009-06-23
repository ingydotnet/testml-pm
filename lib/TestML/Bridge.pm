package TestML::Bridge;
use strict;
use warnings;

use TestML::Base -base;

sub __transform_classes {
    my $class = shift;
    my $list = [qw(
        TestML::Standard    
    )];
    if (not grep {$_ eq $class} @$list) {
        unshift @$list, $class;
    }
    return $list;
}

sub __get_transform_function {
    my $class = shift;
    my $name = shift;
    my $classes = $class->__transform_classes();
    my $function;
    for my $class (@$classes) {
        eval "use $class";
        $function = $class->can($name) and last;
    }
    if (not $function) {
        die "Can't locate function '$name'";
    }
    return $function;
}

1;
