package TestML::Library::Standard;
use TestML;

sub Point {
    my $context = shift;
    my $name = shift;
    my $value = $context->runtime->function->getvar('Block')->points->{$name};
    if ($value =~ s/\n+\z/\n/ and $value eq "\n") {
        $value = '';
    }
    return str($value);
}

sub GetLabel {
    my $context = shift;
    my $label = $context->runtime->get_label;
    return str($label);
}

sub Get {
    my $context = shift;
    my $key = shift->str->value;
    return $context->runtime->function->getvar($key);
}

sub Set {
    my $context = shift;
    my $key = shift;
    my $value = shift;
    $context->runtime->function->setvar($key, $value);
    return $value;
}

sub Type {
    return str(shift->type);
}

sub Catch {
    my $context = shift;
    my $error = $context->runtime->get_error
        or die "Catch called but no TestML error found";
    $error =~ s/ at .* line \d+\.\n\z//;
    $context->runtime->clear_error;
    return str($error);
}

sub Throw {
    my $context = shift;
    my $msg = @_ ? (shift)->value : $context->value
      or $context->runtime->throw("Throw called without an error msg");
    die $msg;
}

sub Str { return str(shift->str->value) }
sub Num { return num(shift->num->value) }
sub Bool { return bool(shift->bool->value) }
sub List {
    my $context = shift;
    return list([@_]);
}

sub Join {
    my $context = shift;
    return join '', map $_->value, @{$context->list->value};
}

sub Strip {
    my $context = shift;
    my $string = $context->str->value;
    my $part = shift->str->value;
    if ((my $i = index($string, $part)) >= 0) {
        $string = substr($string, 0, $i) . substr($string, $i + length($part));
    }
    return $string;
}

sub Not { return bool(shift->bool->value ? 0: 1) }

sub Chomp {
    my $value = shift->str->value;
    chomp($value);
    return $value;
}

1;

# sub Context {
#     my $context = shift;
#     $context->set(None => $context);
# }
# 
# sub Text {
#     my $context = shift;
#     my $value = $context->assert_type('List');
#     $context->set(Str => join "\n", @$value, '');
# }
# 
# sub Lines {
#     my $context = shift;
#     my $value = $context->value || '';
#     $value = [ split /\n/, $value ];
#     $context->set(List => $value);
# }
# 
# sub Join {
#     my $context = shift;
#     my $value = $context->assert_type('List');
#     my $string = @_ ? (shift)->value : '';
#     $context->set(Str => join $string, @$value);
# }
# 
# sub Reverse {
#     my $context = shift;
#     my $value = $context->assert_type('List');
#     return [ reverse @$value ];
# }
# 
# sub Sort {
#     my $context = shift;
#     my $value = $context->assert_type('List');
#     return [ sort @$value ];
# }
# 
# sub BoolStr {
#     my $context = shift;
#     return $context->value ? 'True' : 'False';
# }
# 
# 
# sub Union {
#     my $list = (shift)->value;
#     # my $list2 = shift;
#     my $list2 = [ @$list ];
#     return [ @$list, @$list2 ];
# }
# 
# sub Unique {
#     my $list = (shift)->value;
#     # my $list2 = shift;
#     my $list2 = [ @$list ];
#     return [ @$list, @$list2 ];
# }
# 
# sub Raw {
#     my $context = shift;
#     my $point = $context->point
#         or die "Raw called but there is no point";
#     return $context->runtime->block->points->{$point};
# }
# 
# sub Select {
#     return (shift)->value;
# }
