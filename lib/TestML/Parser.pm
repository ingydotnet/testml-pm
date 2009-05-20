package TestML::Parser;
use strict;
use warnings;
use utf8;
use TestML::Base -base;
use TestML::Parser::Grammar;

field 'stream';
field 'grammar', -init => 'TestML::Parser::Grammar->grammar()';
field 'position';
field 'receiver';
field 'arguments';

sub parse {
    my $self = shift;
    $self->position(0);

    $self->match('document');
    if ($self->position < length($self->stream)) {
        my $substr = substr($self->stream, $self->position, 50);
        $substr =~ s/\n/\\n/;
        XXX +{
            __ => "Parse failed",
            _ => $self->receiver->document,
            state => $self->{state},
            position => $self->position,
            substr => $substr,
            length => length($self->stream),
        };
    }
}

my $stack = []; #XXX

sub match {
    my $self = shift;
    my $topic = shift or die "No topic passed to match";

#     warn ">>> " . (ref($topic) || $topic) . "\n";
    my $info = {
        _ => ref($topic) || $topic,
        stack => $stack,
        position => $self->position,
    }; #XXX

    if (not ref($topic) and $topic =~ /^\w+$/) {
        $self->{state} = $topic;

        $info->{state} = $topic; #XXX
        push @$stack, $topic; #XXX

        if (not defined $self->grammar->{$topic}) {
            die "\n\n*** No grammar support for '$topic'\n\n";
            return;
        }
        
        $topic = $self->grammar->{$topic};
        $self->callback('try');
    }

    my $old_position = $self->position;
    my $result;
    if (not ref $topic and $topic =~ /^\//) {
        $info->{regexp} = $self->get_regexp($topic);
        $result = $self->match_regexp($topic);
    }
    elsif (ref($topic) eq 'ARRAY') {
        $result = $self->match_all($topic);
    }
    elsif (ref($topic) eq 'HASH') {
        $result = $self->match_object($topic)
    }
    else {
        XXX $topic;
    }

    my $status = $result ? 'got' : 'not';
    $self->callback($status);

    $info->{status} = $status; #XXX
#     $self->log($info)                    ;#   if $info->{regexp}; #XXX
    pop @$stack if $info->{state}; #XXX

    $self->position($old_position) unless $result;
    return $result;
}

sub callback {
    my $self = shift;
    my $type = shift;
    my $callback = $type . '_' . $self->{state};
#     warn ">> $callback\n";
    if ($self->receiver->can($callback)) {
        $self->receiver->$callback(@{$self->arguments});
    }
}

sub match_object {
    my $self = shift;
    my $object = shift;
    my ($method, $topic);
    if ($topic = $object->{'='}) {
        $method = 'match';
    }
    elsif ($topic = $object->{'/'}) {
        $method = 'match_one';
    }

    my $start = $self->position;
    my $times = $object->{'^'} || '1';
    my $count = 0;
    my $match;
    while ($match = $self->$method($topic)) {
        $count++;
        last if $times eq '1' or $times eq '?';
    }

    if (not($count) and ($times ne '?' and $times ne '*')) {
        $self->position($start);
        return;
    }

    return 1;
}

sub match_all {
    my $self = shift;
    my $list = shift;
    for my $elem (@$list) {
        $self->match($elem) or return;
    }
    return 1;
}

sub match_one {
    my $self = shift;
    my $list = shift;
    for my $elem (@$list) {
        if ($elem =~ /^\w+$/) {
            $self->match($elem) and return 1;
        }
        elsif ($elem =~ /^\//) {
            $self->match_regexp($elem) and return 1;
        }
        else {
            XXX $elem;
        }
    }
    return;
}

sub match_regexp {
    my $self = shift;
    my $pattern = shift;
    my $regexp = $self->get_regexp($pattern);

    pos($self->{stream}) = $self->position;
    $self->{stream} =~ /$regexp/g or return;
    $self->arguments([$1, $2, $3]);
    $self->position(pos($self->{stream}));

    return 1;
}

sub get_regexp {
    my $self = shift;
    my $pattern = shift;
    $pattern =~ s/^\/(.*)\/$/$1/;
    while ($pattern =~ /\$(\w+)/) {
        my $replacement = $self->grammar->{$1}
          or die "'$1' not in grammar";
        $replacement =~ s/^\/(.*)\/$/$1/;
        $pattern =~ s/\$(\w+)/$replacement/;
    }
    return qr/\G$pattern/;
}

sub log {
    my $self = shift;
    my $info = shift;
    {
        $info->{substr} = substr($self->{stream}, $info->{position}, 40);
        $info->{substr} =~ s/\n/\\n/g;
        $info->{substr} = substr($info->{substr}, 0, 40);
    }
    WWW $info;
#     <> or exit;
}

###############################################################################
sub open {
    my $self = shift;
    my $file = shift;
    $self->stream($self->read($file));
}

sub read {
    my $self = shift;
    my $file = shift;
    my $fh;
    if (ref $file) {
        $fh = $file;
    }
    else {
        CORE::open $fh, $file
          or die "Can't open file '$file' for input.";
    }
    my $content = do {local $/; <$fh>};
    close $fh;
    if (length $content and $content !~ /\n\z/) {
        die "File '$file' does not end with a newline.";
    }
    return $content;
}

