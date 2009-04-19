package TestML::Parser;
use strict;
use warnings;
use TestML::Base -base;

use TestML::Test;

field 'spec';
field 'stream';

sub open {
    my $self = shift;
    my $file = shift;
    open FILE, $file;
    my $testml = do {local $/; <FILE>};
    $self->stream($testml);
    $self->spec(TestML::Test->new());
}

sub parse {
    my $self = shift;
    my $testml = $self->stream;
    $testml =~ /^--META\n(.*)^--TEST\n(.*)^--DATA\n(.*)/ms or die $testml;
    my ($meta, $tests, $data) = ($1, $2, $3);
    $self->_parse_meta($meta);
    $self->_parse_tests($tests);
    $self->_parse_data($data);
    return $self->spec;
}

sub _parse_meta {
    my $self = shift;
    my $text = shift;
    for my $line (split /\n/, $text) {
        next if $line =~ /^\s*(#.*)?$/;
        if ($line =~ /^(\w+):\s*(.*)/) {
            my ($key, $value) = ($1, $2);
            if ($self->spec->meta->can($key)) {
                $self->spec->meta->$key($value);
            }
        }
    }
}

sub _parse_tests {
    my $self = shift;
    my $text = shift;
    for my $line (split /\n/, $text) {
        next if $line =~ /^\s*(#.*)?$/;
    }
}

sub _parse_data {
    my $self = shift;
    my $text = shift;
    for my $line (split /\n/, $text) {
        next if $line =~ /^\s*(#.*)?$/;
    }
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
