package t::Bridge;
use strict;
use warnings;
use base 'TestML::Bridge';

sub my_thing {
    my $self = shift;
    return join ' - ', split "\n", $self->value;
}

sub parse_testml {
    my $self = shift;
    my $stream = $self->value;
    TestML::Parser->new(
        receiver => TestML::Document::Builder->new(),
        start_token => 'document',
        stream => $stream,
    )->parse;
}

sub msg {
    my $self = shift;
    my $text = $self->value;
    $text =~ /^\s+msg:\s+(.*)/m
      or die "Can't find the error message";
    return $1;
}

sub combine {
    my $self = shift;
    my $suffix = shift;
    $self->value . ' ' . $suffix->value;
}

1;
