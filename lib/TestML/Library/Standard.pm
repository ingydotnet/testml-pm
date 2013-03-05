# TODO
# - This should be an object class ($self, TestML::Mo, etc)
# - $self->cast or $self->value is wrong

package TestML::Library::Standard;
use TestML::Mo;
extends 'TestML::Library';

use TestML::Util;

sub Point {
    my ($self, $name) = @_;
    $name = $name->value        if ref $name; # XXX trailing clause not needed
    my $value = $self->runtime->function->getvar('Block')->points->{$name};
    if ($value =~ s/\n+\z/\n/ and $value eq "\n") {
        $value = '';
    }
    return str($value);
}

sub GetLabel {
    my ($self) = @_;
    my $label = $self->runtime->get_label;
    return str($label);
}

sub Get {
    my ($self, $key) = @_;
    return $self->runtime->function->getvar($key->str->value);
}

sub Set {
    my ($self, $key, $value) = @_;
    $self->runtime->function->setvar($key, $value);
    return $value;
}

sub Type {
    my ($self, $var) = @_;
    return str($var->type);
}

sub Catch {
    my ($self) = @_;
    my $error = $self->runtime->get_error
        or die "Catch called but no TestML error found";
    $error =~ s/ at .* line \d+\.\n\z//;
    $self->runtime->clear_error;
    return str($error);
}

sub Throw {
    my ($self, $msg) = @_;
    # XXX die should be $self->runtime->throw
    die $msg->value;
}

sub Str {
    my ($self, $object) = @_;
    return str($object->str->value);
}
sub Num {
    my ($self, $object) = @_;
    return num($object->num->value);
}
sub Bool {
    my ($self, $object) = @_;
    return bool($object->bool->value);
}
sub List {
    my $self = shift;
    return list([@_]);
}

sub Join {
    my ($self, $list, $separator) = @_;
    $separator = $separator ? $separator->value : '';
    my @strings = map $_->value, @{$list->list->value};
    return join $separator, @strings;
}

sub Strip {
    my ($self, $string, $part) = @_;
    $string = $string->str->value;
    $part = $part->str->value;
    if ((my $i = index($string, $part)) >= 0) {
        $string = substr($string, 0, $i) . substr($string, $i + length($part));
    }
    return $string;
}

sub Not {
    my ($self, $bool) = @_;
    return bool($bool->bool->value ? 0: 1);
}

sub Chomp {
    my ($self, $string) = @_;
    my $value = $string->str->value;
    chomp($value);
    return $value;
}

sub Has {
    my ($self, $string, $part) = @_;
    $string = $string->str->value;
    $part = $part->str->value;
    return bool(index($string, $part) >= 0);
}

sub RunCommand {
    require Capture::Tiny;
    my ($self, $command) = @_;
    $command = $command->value;
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
    my ($self, $path) = @_;
    $path = $path->value;
    File::Path::rmtree($path);
    return str('');
}

sub Stdout {
    my ($self) = @_;
    return $self->runtime->function->getvar('_Stdout');
}

sub Stderr {
    my ($self) = @_;
    return $self->runtime->function->getvar('_Stderr');
}

sub Chdir {
    my ($self, $dir) = @_;
    $dir = $dir->value;
    chdir $dir;
    return str('');
}

sub Read {
    my ($self, $file) = @_;
    $file = $file->value;
    use Cwd;
    open FILE, $file or die "Can't open $file for input in " . Cwd::cwd;
    my $text = do { local $/; <FILE> };
    close FILE;
    return str($text);
}

sub Print {
    my ($self, $string) = @_;
    print STDOUT $string->value;
}

sub Pass {
    my ($self, @args) = @_;
    return @args;
}

sub Text {
    my ($self, $lines) = @_;
    my $value = $lines->list->value;
    return str(join "\n", map($_->value, @$value), '');
}

sub Count {
    my ($self, $list) = @_;
    return num scalar @{$list->list->value};
}

sub Lines {
    my ($self, $text) = @_;
    return list([ map str($_), split /\n/, $text->value ]);
}

sub Reverse {
    my ($self, $list) = @_;
    my $value = $list->list->value;
    return list([ reverse @$value ]);
}

sub Sort {
    my ($self, $list) = @_;
    my $value = $list->list->value;
    return list([ sort { $a->value cmp $b->value } @$value ]);
}

# sub Raw {
#     my $self = shift;
#     my $point = $self->point
#         or die "Raw called but there is no point";
#     return $self->runtime->block->points->{$point};
# }
# 

1;
