package TestML::Standard;
use strict;
use warnings;
no warnings 'redefine';

sub testml_Point {
    my $self = shift;
    my $name = shift;
    my $value = $self->block->points->{$name};
    $value =~ s/\n+\z/\n/;
    return $value;
}

sub testml_List {
    return [ split /\n/, (shift)->value ];
}

sub testml_Join {
    my $list = (shift)->value;
    my $string = @_ ? shift : '';
    return join $string, @$list;
}

sub testml_Reverse {
    my $list = (shift)->value;
    return [ reverse @$list ];
}

sub testml_Sort {
    my $list = (shift)->value;
    return [ sort @$list ];
}

sub testml_Item {
    my $list = (shift)->value;
    return join("\n", (@$list, ''));
}

sub testml_Union {
    my $list = (shift)->value;
    # my $list2 = shift;
    my $list2 = [ @$list ];
    return [ @$list, @$list2 ];
}

sub testml_Unique {
    my $list = (shift)->value;
    # my $list2 = shift;
    my $list2 = [ @$list ];
    return [ @$list, @$list2 ];
}

