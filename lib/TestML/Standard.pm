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
    $context->set(String => $value);
}

sub Catch {
    my $context = shift;
    my $error = $context->error
        or die "Catch called but no TestML error found";
    $error =~ s/ at .* line \d+\.\n\z//;
    $context->error(undef);
    $context->set(String => $error);
}

sub Throw {
    my $context = shift;
    my $msg = @_ ? (shift)->value : $context->value
      or die "Throw called without an error msg";
    die $msg;
}

sub String {
    my $context = shift;
    my ($type, $value) = $context->get(@_);
    $value = 
        $type eq 'String' ? $value :
        $type eq 'Number' ? "$value" :
        $type eq 'List' ? join("\n", @$value, '') :
        $type eq 'Boolean' ? $value ? '1' : '' :
        $type eq 'None' ? '' :
        $context->throw("String type error: '$type'");
    $context->set(String => $value);
}

sub List {
    my $context = shift;
    my $value = $context->value || '';
    $value = [ split /\n/, $value ];
    $context->set(List => $value);
}

sub Boolean {
    my $context = shift;
    my $value = $context->value ? 1 : 0;
    $context->set(Boolean => $value);
}

sub Number {
    my $context = shift;
    my $value = 0 + $context->value;
    $context->set(Number => $value);
}

sub True {
    my $context = shift;
    $context->set(Boolean => 1);
}

sub False {
    my $context = shift;
    $context->set(Boolean => 0);
}

sub BoolStr {
    my $context = shift;
    return $context->value ? 'True' : 'False';
}

sub Join {
    my $context = shift;
    my $list = $context->value;
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

sub Chomp {
    my $string = (shift)->value;
    chomp($string);
    return $string;
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

