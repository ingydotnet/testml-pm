package TestMLTestBridge;
use strict;
use warnings;
use base 'TestML::Bridge';

sub testml_my_thing {
    my $self = shift;
    return join ' - ', split "\n", $self->value;
}

sub testml_parse_testml {
    my $self = shift;
    my $stream = $self->value;
    TestML::Parser->new(
        receiver => TestML::Document::Builder->new(),
        start_token => 'document',
        stream => $stream,
    )->parse;
}

sub testml_msg {
    my $self = shift;
    my $text = $self->value;
    $text =~ /^\s+msg:\s+(.*)/m
      or die "Can't find the error message";
    return $1;
}

1;
