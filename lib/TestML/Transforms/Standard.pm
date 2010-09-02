package TestML::Transforms::Standard;
use TestML;

sub Point {
    my $context = shift;
    my $name = shift;
    my $value = $context->runtime->function->block->points->{$name};
    if ($value =~ s/\n+\z/\n/ and $value eq "\n") {
        $value = '';
    }
    $context->set(Str => $value);
}

sub GetLabel {
    my $context = shift;
    my $label = $context->runtime->get_label;
    $context->set(Str => $label);
}

sub Get {
    my $context = shift;
    my $key = shift->value;
    $context->set(Str => $context->runtime->function->namespace->{$key});
}

sub Set {
    my $context = shift;
    my $key = shift;
    my $value = shift->value;
    $context->runtime->function->namespace->{$key} = $value;
    return; 
}

sub Catch {
    my $context = shift;
    my $error = $context->runtime->get_error
        or die "Catch called but no TestML error found";
    $error =~ s/ at .* line \d+\.\n\z//;
    $context->runtime->clear_error;
    $context->set(Str => $error);
}

sub Throw {
    my $context = shift;
    my $msg = @_ ? (shift)->value : $context->value
      or $context->runtime->throw("Throw called without an error msg");
    die $msg;
}

sub Str {
    my $context = shift;
    $context->set(Str => $context->as_str);
}

sub Bool {
    my $context = shift;
    $context->set(Bool => $context->as_bool);
}

sub Num {
    my $context = shift;
    $context->set(Num => $context->as_num);
}

sub True {
    my $context = shift;
    $context->set(Bool => 1);
}

sub Not {
    my $context = shift;
    $context->set(Bool => $context->as_bool ? 0 : 1);
}

sub False {
    my $context = shift;
    $context->set(Bool => 0);
}

sub Chomp {
    my $context = shift;
    my $value = $context->assert_type('Str');
    chomp($value);
    return $value;
}

sub Context {
    my $context = shift;
    $context->set(None => $context);
}

1;

__END__
sub Text {
    my $context = shift;
    my $value = $context->assert_type('List');
    $context->set(Str => join "\n", @$value, '');
}

sub Lines {
    my $context = shift;
    my $value = $context->value || '';
    $value = [ split /\n/, $value ];
    $context->set(List => $value);
}

sub Join {
    my $context = shift;
    my $value = $context->assert_type('List');
    my $string = @_ ? (shift)->value : '';
    $context->set(Str => join $string, @$value);
}

sub Reverse {
    my $context = shift;
    my $value = $context->assert_type('List');
    return [ reverse @$value ];
}

sub Sort {
    my $context = shift;
    my $value = $context->assert_type('List');
    return [ sort @$value ];
}

sub BoolStr {
    my $context = shift;
    return $context->value ? 'True' : 'False';
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

sub Raw {
    my $context = shift;
    my $point = $context->point
        or die "Raw called but there is no point";
    return $context->runtime->block->points->{$point};
}

sub Select {
    return (shift)->value;
}

