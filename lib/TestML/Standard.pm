package TestML::Standard;
use strict;
use warnings;
no warnings 'redefine';

sub testml_list {
    return [ split /\n/, (shift)->value ];
}

sub testml_join {
    my $list = (shift)->value;
    my $string = @_ ? shift : '';
    return join $string, @$list;
}

sub testml_reverse {
    my $list = (shift)->value;
    return [ reverse @$list ];
}

sub testml_sort {
    my $list = (shift)->value;
    return [ sort @$list ];
}

sub testml_item {
    my $list = (shift)->value;
    return join("\n", (@$list, ''));
}

sub testml_union {
    my $list = (shift)->value;
    # my $list2 = shift;
    my $list2 = [ @$list ];
    return [ @$list, @$list2 ];
}

sub testml_unique {
    my $list = (shift)->value;
    # my $list2 = shift;
    my $list2 = [ @$list ];
    return [ @$list, @$list2 ];
}

