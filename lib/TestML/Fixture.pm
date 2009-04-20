package TestML::Fixture;
use strict;
use warnings;

use TestML::Base -base;

sub get_function {
    my $self = shift;
    my $name = shift;
    my $context = (shift) ? 'list' : 'scalar';
    my $function = "testml_${name}_$context";
    no strict 'refs';
    if (not defined &$function) {
        die "Can't find function '$function'";
    }
    return \&function;
}

sub testml_join_list {
    my $list = shift;
    my $string = shift || '';
    return join @$list, $string;
}

1;
