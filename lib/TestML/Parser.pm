package TestML::Parser;
use strict;
use warnings;
use utf8;
use TestML::Base -base;
use TestML::Parser::Grammar;

field 'stream';
field 'grammar', -init => 'TestML::Parser::Grammar->grammar()';
field 'start_token';
field 'position' => 0;
field 'receiver';
field 'arguments' => [];
field 'stack' => [];

sub parse {
    my $self = shift;
    $self->match($self->start_token);
    if ($self->position < length($self->stream)) {
        die "Parse document failed for some reason";
    }
}

sub match {
    my $self = shift;
    my $topic = shift or die "No topic passed to match";

    my $not = ($topic =~ s/^!//) ? 1 : 0;

    my $state = undef;
    if (not ref($topic) and $topic =~ /^\w+$/) {
        $state = $topic;

        push @{$self->stack}, $state;

        if (not defined $self->grammar->{$topic}) {
            die "\n\n*** No grammar support for '$topic'\n\n";
            return 0;
        }
        
        $topic = $self->grammar->{$topic};
        $self->callback('try', $state);
    }

    my $method;
    my $times = '1';
    if (not ref $topic and $topic =~ /^\//) {
        $method = 'match_regexp';
    }
    elsif (ref($topic) eq 'ARRAY') {
        $method = 'match_all';
    }
    elsif (ref($topic) eq 'HASH') {
        $times = $topic->{'^'} if $topic->{'^'};
        if ($topic->{'='}) {
            $topic = $topic->{'='};
            $method = 'match';
        }
        elsif ($topic->{'/'}) {
            $topic = $topic->{'/'};
            $method = 'match_one';
        }
        else { die }
    }
    else { XXX $topic }

    my $position = $self->position;
    my $count = 0;
    while ($self->$method($topic)) {
        $count++;
        last if $times eq '1' or $times eq '?';
    }
    my $result = (($count or $times eq '?' or $times eq '*') ? 1 : 0) ^ $not;

    my $status = $result ? 'got' : 'not';

    if ($state) {
        $self->callback($status, $state);
        pop @{$self->stack};
    }

    $self->position($position) unless $result;
    return $result;
}

sub match_all {
    my $self = shift;
    my $list = shift;
    for my $elem (@$list) {
        $self->match($elem) or return 0;
    }
    return 1;
}

sub match_one {
    my $self = shift;
    my $list = shift;
    for my $elem (@$list) {
        $self->match($elem) and return 1;
    }
    return 0;
}

sub match_regexp {
    my $self = shift;
    my $pattern = shift;
    my $regexp = $self->get_regexp($pattern);

    pos($self->{stream}) = $self->position;
    $self->{stream} =~ /$regexp/g or return 0;
    if (defined $1) {
        $self->arguments([$1, $2, $3, $4, $5]);
    }
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

my $warn = 0;
sub callback {
    my $self = shift;
    my $type = shift;
    my $state = shift;
    my $method = $type . '_' . $state;

#     $warn = 1 if $state eq 'data_section';
#     warn ">> $method\n" if $warn;

    if ($self->receiver->can($method)) {
        $self->receiver->$method(@{$self->arguments});
    }
}

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

1;
