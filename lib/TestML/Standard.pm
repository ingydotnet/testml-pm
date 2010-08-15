package TestML::Standard;
use strict;
use warnings;

sub Point {
    my $context = shift;
    my $name = shift;
    $context->point($name);
    my $value = $context->block->points->{$name};
    if ($value =~ s/\n+\z/\n/ and $value eq "\n") {
        $value = '';
    }
    $context->set(Str => $value);
}

sub Catch {
    my $context = shift;
    my $error = $context->error
        or die "Catch called but no TestML error found";
    $error =~ s/ at .* line \d+\.\n\z//;
    $context->error(undef);
    $context->set(Str => $error);
}

sub Throw {
    my $context = shift;
    my $msg = @_ ? (shift)->value : $context->value
      or die "Throw called without an error msg";
    die $msg;
}

sub Str {
    my $context = shift;
    $context->set(Str => $context->get_value_as_str);
}

sub Bool {
    my $context = shift;
    $context->set(Bool => $context->get_value_as_bool);
}

sub Num {
    my $context = shift;
    $context->set(Num => $context->get_value_as_num);
}

sub True {
    my $context = shift;
    $context->set(Bool => 1);
}

sub False {
    my $context = shift;
    $context->set(Bool => 0);
}

sub BoolStr {
    my $context = shift;
    return $context->value ? 'True' : 'False';
}

sub Join {
    my $context = shift;
    my $value = $context->get_value_if_type('List');
    my $string = @_ ? (shift)->value : '';
    $context->set(Str => join $string, @$value);
}

sub Reverse {
    my $context = shift;
    my $value = $context->get_value_if_type('List');
    return [ reverse @$value ];
}

sub Sort {
    my $context = shift;
    my $value = $context->get_value_if_type('List');
    return [ sort @$value ];
}

sub Chomp {
    my $context = shift;
    my $value = $context->get_value_if_type('Str');
    chomp($value);
    return $value;
}

sub Text {
    my $context = shift;
    my $value = $context->get_value_if_type('List');
    $context->set(Str => join "\n", @$value, '');
}

sub Lines {
    my $context = shift;
    my $value = $context->value || '';
    $value = [ split /\n/, $value ];
    $context->set(List => $value);
}

1;

__END__
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

sub Raw {
    my $context = shift;
    my $point = $context->point
        or die "Raw called but there is no point";
    return $context->block->points->{$point};
}

sub Select {
    return (shift)->value;
}

