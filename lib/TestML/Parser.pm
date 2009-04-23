package TestML::Parser;
use strict;
use warnings;
use TestML::Base -base;

use TestML::Spec;

field 'spec';
field 'stream';

sub open {
    my $self = shift;
    my $file = shift;
    open FILE, $file;
    my $testml = do {local $/; <FILE>};
    $self->stream($testml);
    $self->spec(TestML::Spec->new());
}

sub parse {
    my $self = shift;
    $self->_parse_header();
    $self->_parse_data();
    return $self->spec;
}

sub _parse_header {
    my $self = shift;
    my $text = $self->stream;
    while (length $text) {
        $text =~ s/^(.*)\n//;
        my $line = $1;
        if ($line =~ /^\s*(#.*)?$/) {
            next;
        }
        elsif (
            $line =~ /^===\s+\S/ and
            $self->spec->meta->data_syntax eq 'testml'
        ) {
            $self->stream("$line\n$text");
            last;
        }
        elsif ($line =~ /^(\w+):\s*(.*)/) {
            my ($key, $value) = ($1, $2);
            if ($self->spec->meta->can($key)) {
                $self->spec->meta->$key($value);
            }
        }
        elsif ($line =~ /\s*(.+?)\s+(==)\s+(.+?)\s*$/) {
            my ($left, $op, $right) = ($1, $2, $3);
            my $test = TestML::Spec::Test->new(
               left => $self->_parse_expr($left), 
               op => $op,
               right => $self->_parse_expr($right), 
            );
            $self->spec->tests->add($test);
        }
        else {
            die "TestML parse failure on line:\n$line\n";
        }
    }
}

sub _parse_expr {
    my $self = shift;
    my $text = shift;
    $text =~ s/^(\w+)//;
    my $expr = TestML::Spec::Expr->new(start => $1);
    while (length $text) {
        $text =~ s/^\.(\w+)// or die;
        my $func = TestML::Spec::Function->new(name => $1);
        $expr->add($func);
        if ($text =~ s/^\((.*?)\)//) {
            my $args = $1;
            $args =~ s/^'(.*)'$/$1/;
            $func->args([$args]);
        }
    }
    return $expr;
}

sub _parse_data {
    my $self = shift;
    my $text = $self->stream;
    die unless $self->spec->meta->data_syntax eq 'testml';
    my $block_marker = $self->spec->meta->testml_block_marker;
    my $entry_marker = $self->spec->meta->testml_entry_marker;
    my $current_block;
    my $current_entry;
    my $current_notes = '';
    my @lines = ($text =~ /(.*\n)/g);

    my $is_throw_away = qr/^\s*(#.*)?$/;
    my $is_start_block = qr/^\Q$block_marker\E(?:\s+(.*))?$/;
    my $is_start_entry = qr/^\Q$entry_marker\E\s+(\w+)(?:\s*:\s*(.*?)\s*)?$/;

    my ($r1, $r2);

    my $notes = '';
    $notes .= shift(@lines) while $lines[0] !~ $is_start_block;
    $r1 = $1;
    $self->spec->data->notes($notes);

    BLOCK: while (@lines) {
        shift(@lines);
        my $block = TestML::Spec::Block->new(description => $r1);
        $self->spec->data->add($block);

        my $notes = '';
        $notes .= shift(@lines) while
            @lines &&
            $lines[0] !~ $is_start_entry &&
            $lines[0] !~ $is_start_block;
        $block->notes($notes);
        last BLOCK unless @lines;
        if ($lines[0] =~ $is_start_block) {
            $r1 = $1;
            next BLOCK;
        }
        $lines[0] =~ $is_start_entry or die;
        $r1 = $1;
        $r2 = $2;
        ENTRY: while (@lines) {
            shift(@lines);
            my $set = 0;
            my $entry = TestML::Spec::Entry->new(name => $r1);
            $block->add($entry);
            if (defined $r2) {
                $entry->value($r2);
                $set = 1;
            }

            my $text = '';
            $text .= shift(@lines) while
                @lines &&
                $lines[0] !~ $is_start_entry &&
                $lines[0] !~ $is_start_block;
            if ($set) {
                $entry->notes($text);
            }
            else {
                $entry->value($text);
            }
            if (@lines and $lines[0] =~ $is_start_entry) {
                $r1 = $1;
                $r2 = $2;
                next ENTRY;
            }
            if ($block->entries->{ONLY}) {
                $self->spec->data->blocks([]);
                $self->spec->data->add($block);
                last BLOCK;
            }
            last BLOCK unless @lines;
            if ($lines[0] =~ $is_start_block) {
                $r1 = $1;
                next BLOCK;
            }
            die;
        }
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
