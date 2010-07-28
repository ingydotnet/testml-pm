package TestML::Standard;
use strict;
use warnings;

sub Select {
    return (shift)->value;
}

sub Point {
    my $this = shift;
    my $name = shift;
    $this->point($name);
    my $value = $this->block->points->{$name};
    if ($value =~ s/\n+\z/\n/ and $value eq "\n") {
        $value = '';
    }
    return $value;
}

sub Raw {
    my $this = shift;
    my $point = $this->point
        or die "Raw called but there is no point";
    return $this->block->points->{$point};
}

sub Catch {
    my $this = shift;
    my $error = $this->error
        or die "Catch called but no TestML error found";
    $error =~ s/ at .* line \d+\.\n\z//;
    $this->error(undef);
    return $error;
}

sub Throw {
    my $this = shift;
    my $msg = @_ ? (shift)->value : $this->value
      or die "Throw called without an error msg";
    die $msg;
}

sub String {
    my $this = shift;
    my $string =
    (defined $this->value) ? $this->value :
    @_ ? ref($_[0]) ? (shift)->value : (shift) :
    $this->raise(
        'StandardLibraryException',
        'String transform called but no string available'
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

1;
