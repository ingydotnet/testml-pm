# TODO
# - This should be an object class ($self, TestML::Mo, etc)
# - $self->cast or $self->value is wrong

package TestML::Library::Standard;
use TestML::Mo;
extends 'TestML::Library';

use TestML::Util;

sub Point {
    my $self = shift;
    my $name = shift;
    $name = $name->value if ref $name;
    my $value = $self->runtime->function->getvar('Block')->points->{$name};
    if ($value =~ s/\n+\z/\n/ and $value eq "\n") {
        $value = '';
    }
    return str($value);
}

sub GetLabel {
    my $self = shift;
    my $label = $self->runtime->get_label;
    return str($label);
}

sub Get {
    my $self = shift;
    my $key = shift->str->value;
    return $self->runtime->function->getvar($key);
}

sub Set {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    $self->runtime->function->setvar($key, $value);
    return $value;
}

sub Type {
    return str(shift->type);
}

sub Catch {
    my $self = shift;
    my $error = $self->runtime->get_error
        or die "Catch called but no TestML error found";
    $error =~ s/ at .* line \d+\.\n\z//;
    $self->runtime->clear_error;
    return str($error);
}

sub Throw {
    my ($msg) = pop;
    # XXX die should be $self->runtime->throw
    die $msg->value;
}

sub Str { return str(shift->str->value) }
sub Num { return num(shift->num->value) }
sub Bool { return bool(shift->bool->value) }
sub List {
    my $self = shift;
    return list([@_]);
}

sub Join {
    my $self = shift;
    my $separator = @_ ? shift->value : '';
    my @strings = map $_->value, @{$self->list->value};
    return join $separator, @strings;
}

sub Strip {
    my $self = shift;
    my $string = $self->str->value;
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
    my $self = shift;
    my $arg = shift
       or die "RunCommand requires an argument";
    my $command = $arg->value;
    chomp($command);
    my $sub = sub {
        system($command);
    };
    my ($stdout, $stderr) = Capture::Tiny::capture($sub);
    $self->runtime->function->setvar('_Stdout', $stdout);
    $self->runtime->function->setvar('_Stderr', $stderr);
    return str('');
}

sub RmPath {
    require File::Path;
    my $self = shift;
    my $arg = shift
       or die "RmPath requires an argument";
    my $path = $arg->value;
    File::Path::rmtree($path);
    return str('');
}

sub Stdout {
    my $self = shift;
    return $self->runtime->function->getvar('_Stdout');
}

sub Stderr {
    my $self = shift;
    return $self->runtime->function->getvar('_Stderr');
}

sub Chdir {
    my $self = shift;
    my $arg = shift
       or die "Chdir requires an argument";
    my $dir = $arg->value;
    chdir $dir;
    return str('');
}

sub Read {
    my $self = shift;
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
    my $self = shift;
    my $arg = shift;
    print STDOUT $arg ? $arg->value : $self->value;
}

sub Pass {
    return @_;
}

1;

sub Text {
    my $self = shift;
    my $value = $self->list->value;
    return str(join "\n", map($_->value, @$value), '');
}

sub Count {
    my $self = shift;
    return num scalar @{$self->list->value};
}

sub Lines {
    my $self = shift;
    my $value = $self->value || '';
    return list([ map str($_), split /\n/, $value ]);
}

# sub Join {
#     my $self = shift;
#     my $value = $self->assert_type('List');
#     my $string = @_ ? (shift)->value : '';
#     $self->set(Str => join $string, @$value);
# }

sub Reverse {
    my $self = shift;
    my $value = $self->list->value;
    return list([ reverse @$value ]);
}

sub Sort {
    my $self = shift;
    my $value = $self->list->value;
    return list([ sort { $a->value cmp $b->value } @$value ]);
}

# sub BoolStr {
#     my $self = shift;
#     return $self->value ? 'True' : 'False';
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
#     my $self = shift;
#     my $point = $self->point
#         or die "Raw called but there is no point";
#     return $self->runtime->block->points->{$point};
# }
# 
