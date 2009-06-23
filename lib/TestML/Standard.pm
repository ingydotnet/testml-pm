package TestML::Standard;
use strict;
use warnings;
no warnings 'redefine';

sub Select {
    return (shift)->value;
}

sub Point {
    my $self = shift;
    my $name = shift;
    $self->point($name);
    my $value = $self->block->points->{$name};
    if ($value =~ s/\n+\z/\n/ and $value eq "\n") {
        $value = '';
    }
    return $value;
}

sub Raw {
    my $self = shift;
    my $point = $self->point
        or die "Raw called but there is no point";
    return $self->block->points->{$point};
}

sub Catch {
    my $self = shift;
    my $error = $self->error
        or die "Catch called but no TestML error found";
    $error =~ s/ at .* line \d+\.\n\z//;
    $self->error(undef);
    return $error;
}

sub Throw {
    my $self = shift;
    my $msg = @_ ? (shift)->value : $self->value
      or die "Throw called without an error msg";
    die $msg;
}

sub String {
    my $self = shift;
    my $string =
    (defined $self->value) ? $self->value :
    @_ ? ref($_[0]) ? (shift)->value : (shift) :
    $self->raise(
        'StandardLibraryException',
        'Str transform called but no string available'
    );
    return $string;
}

sub BoolStr {
    return (shift)->value ? 'True' : 'False';
}

sub List {
    return [ split /\n/, (shift)->value ];
}

sub Join {
    my $list = (shift)->value;
    my $string = @_ ? (shift)->value : '';
    return join $string, @$list;
}

sub Reverse {
    my $list = (shift)->value;
    return [ reverse @$list ];
}

sub Sort {
    my $list = (shift)->value;
    return [ sort @$list ];
}

sub Item {
    my $list = (shift)->value;
    return join("\n", (@$list, ''));
}

sub Union {
    my $list = (shift)->value;
    # my $list2 = shift;
    my $list2 = [ @$list ];
    return [ @$list, @$list2 ];
}

sub Unique {
    my $list = (shift)->value;
    # my $list2 = shift;
    my $list2 = [ @$list ];
    return [ @$list, @$list2 ];
}

sub Chomp {
    my $string = (shift)->value;
    chomp($string);
    return $string;
}
