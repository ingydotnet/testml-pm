package TestML::Parser;
use strict;
use warnings;

sub new {
    return bless {}, shift;
}

sub open {
    my $self = shift;

}

sub parse {
}

sub grammar {
    return {
        document => [qw(head body)],
        head => [qw(initiator statement* terminator)],
        statement => [qw(word colonspace value)],
        body => [qw(line*)],
    }

1;
