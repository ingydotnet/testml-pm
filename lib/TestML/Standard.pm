package TestML::Standard;
use strict;
use warnings;

sub Select {
    return (shift)->value;
}

sub Point {
    my $context = shift;
    my $name = shift;
    $context->point($name);
    my $value = $context->block->points->{$name};
    if ($value =~ s/\n+\z/\n/ and $value eq "\n") {
        $value = '';
    }
    return $value;
}

sub Raw {
    my $context = shift;
    my $point = $context->point
        or die "Raw called but there is no point";
    return $context->block->points->{$point};
}

sub Catch {
    my $context = shift;
    my $error = $context->error
        or die "Catch called but no TestML error found";
    $error =~ s/ at .* line \d+\.\n\z//;
    $context->error(undef);
    return $error;
}

sub Throw {
    my $context = shift;
    my $msg = @_ ? (shift)->value : $context->value
      or die "Throw called without an error msg";
    die $msg;
}

sub String {
    my $context = shift;
    my $string =
    (defined $context->value) ? $context->value :
    @_ ? ref($_[0]) ? (shift)->value : (shift) :
    $context->raise(
        'StandardLibraryException',
        'String transform called but no string available'
    );
    return $string;
}

sub True { 1 }

sub False { 0 }

sub BoolStr {
    return (shift)->value ? 'True' : 'False';
}

sub List {
    my $context = shift;
    my $value = $context->value || '';
    return [ split /\n/, $value ];
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
