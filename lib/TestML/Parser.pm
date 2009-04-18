package TestML::Parser;
use strict;
use warnings;
use TestML::Base -base;

use TestML::Test;

field 'stream';

sub open {
    my $self = shift;
    my $file = shift;
    open FILE, $file;
    my $testml = do {local $/; <FILE>};
    $self->stream($testml);
}

sub parse {
    my $self = shift;
    my $test = TestML::Test->new();
    my $testml = $self->stream;
    $testml =~ /^--META\n(.*)^--TEST\n(.*)^--DATA\n(.*)/ms or die $testml;
    my ($meta, $tests, $data) = ($1, $2, $3);
    if ($meta =~ /^tests:\s+(\d+)$/m) {
        $test->tests($1);
    }
    return $test;
}

sub grammar {
    return {
        document => [qw(head body)],
        head => [qw(initiator statement* terminator)],
        statement => [qw(word colonspace value)],
        body => [qw(line*)],
    }
}

1;
