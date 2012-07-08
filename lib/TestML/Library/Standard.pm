package TestML::Library::Standard;
use TestML;

sub Point {
    my $context = shift;
    my $name = shift;
    $name = $name->value if ref $name;
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
    my $separator = @_ ? shift->value : '';
    my @strings = map $_->value, @{$context->list->value};
    return join $separator, @strings;
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

sub Has {
    my $text = shift->value;
    my $part = shift->value;
    return bool(index($text, $part) >= 0);
}

sub RunCommand {
    require Capture::Tiny;
    my $context = shift;
    my $arg = shift
       or die "RunCommand requires an argument";
    my $command = $arg->value;
    chomp($command);
    my $sub = sub {
        system($command);
    };
    my ($stdout, $stderr) = Capture::Tiny::capture($sub);
    $context->runtime->function->setvar('_Stdout', $stdout);
    $context->runtime->function->setvar('_Stderr', $stderr);
    return str('');
}

sub RmPath {
    require File::Path;
    my $context = shift;
    my $arg = shift
       or die "RmPath requires an argument";
    my $path = $arg->value;
    File::Path::rmtree($path);
    return str('');
}

sub Stdout {
    my $context = shift;
    return $context->runtime->function->getvar('_Stdout');
}

sub Stderr {
    my $context = shift;
    return $context->runtime->function->getvar('_Stderr');
}

sub Chdir {
    my $context = shift;
    my $arg = shift
       or die "Chdir requires an argument";
    my $dir = $arg->value;
    chdir $dir;
    return str('');
}

sub Read {
    my $context = shift;
    my $arg = shift
        or die "Read requires an argument";
    my $file = $arg->value;
    use Cwd;
    open FILE, $file or die "Can't open $file for input in " . Cwd::cwd;
    my $text = do { local $/; <FILE> };
    close FILE;
    return str($text);
}

sub Print {
    my $context = shift;
    my $arg = shift;
    print STDOUT $arg ? $arg->value : $context->value;
}

sub Pass {
    return @_;
}

1;

# sub Context {
#     my $context = shift;
#     $context->set(None => $context);
# }

sub Text {
    my $context = shift;
    my $value = $context->list->value;
    return str(join "\n", map($_->value, @$value), '');
}

sub Count {
    my $context = shift;
    return num scalar @{$context->list->value};
}

sub Lines {
    my $context = shift;
    my $value = $context->value || '';
    return list([ map str($_), split /\n/, $value ]);
}

# sub Join {
#     my $context = shift;
#     my $value = $context->assert_type('List');
#     my $string = @_ ? (shift)->value : '';
#     $context->set(Str => join $string, @$value);
# }

sub Reverse {
    my $context = shift;
    my $value = $context->list->value;
    return list([ reverse @$value ]);
}

sub Sort {
    my $context = shift;
    my $value = $context->list->value;
    return list([ sort { $a->value cmp $b->value } @$value ]);
}

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
