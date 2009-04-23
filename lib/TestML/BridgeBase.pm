package TestML::BridgeBase;
use strict;
use warnings;

use TestML::Base -base;

sub get_function {
    my $self = shift;
    my $name = shift;
    my $function = $self->can("testml_${name}");
    if (not defined &$function) {
        die "Can't find function '$function'";
    }
    return \&$function;
}

sub testml_list {
    return [ split /\n/, (shift) ];
}

sub testml_join {
    my $list = shift;
    my $string = @_ ? shift : '';
    return join $string, @$list;
}

sub testml_reverse {
    my $list = shift;
    return [ reverse @$list ];
}

sub testml_sort {
    my $list = shift;
    return [ sort @$list ];
}

sub testml_item {
    my $list = shift;
    return join("\n", (@$list, ''));
}

sub testml_union {
    my $list = shift;
    # my $list2 = shift;
    my $list2 = [ @$list ];
    return [ @$list, @$list2 ];
}

sub testml_unique {
    my $list = shift;
    # my $list2 = shift;
    my $list2 = [ @$list ];
    return [ @$list, @$list2 ];
}

1;
