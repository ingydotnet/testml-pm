package TestML::Standard;
use strict;
use warnings;
no warnings 'redefine';

sub testml_Select {
    return (shift)->value;
}

sub testml_Point {
    my $self = shift;
    my $name = shift;
    $self->point($name);
    my $value = $self->block->points->{$name};
    if ($value =~ s/\n+\z/\n/ and $value eq "\n") {
        $value = '';
    }
    return $value;
}

sub testml_Raw {
    my $self = shift;
    my $point = $self->point
        or die "Raw called but there is no point";
    return $self->block->points->{$point};
}

sub testml_Catch {
    my $self = shift;
    my $error = $self->error
        or die "Catch called but no TestML error found";
    $error =~ s/ at .* line \d+\.\n\z//;
    $self->error(undef);
    return $error;
}

sub testml_Throw {
    my $self = shift;
    my $msg = shift || $self->value
      or die "Throw called without an error msg";
    die $msg;
}

sub testml_Str {
    my $self = shift;
    my $string =
    (defined $self->value) ? $self->value :
    @_ ? (shift) :
    $self->raise(
        'StandardLibraryException',
        'Str transform called but no string available'
    );
    return $string;
}

sub testml_BoolStr {
    return (shift)->value ? 'True' : 'False';
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

