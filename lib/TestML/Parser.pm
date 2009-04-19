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
        $line =~ /\s*(.+?)\s+(==)\s+(.+?)\s*$/ or die;
        my ($left, $op, $right) = ($1, $2, $3);
        my $test = TestML::Spec::Test->new(
           left => $self->_parse_expr($left), 
           op => $op,
           right => $self->_parse_expr($right), 
        );
        $self->spec->tests->add($test);
    }
}

sub _parse_expr {
    my $self = shift;
    my $text = shift;
    $text =~ s/^(\w+)//;
    my $expr = TestML::Spec::Expr->new(name => $1);
    while (length $text) {
        $text =~ s/^\.(\w+)// or die;
        my $func = TestML::Spec::Function->new(name => $1);
        $expr->add($func);
        if ($text =~ s/\((.*?)\)//) {
            $func->args($1);
        }
    }
    return $expr;
}

sub _parse_data {
    my $self = shift;
    my $text = shift;
    die unless $self->spec->meta->data_syntax eq 'testml';
    my $block_marker = $self->spec->meta->testml_block_marker;
    my $field_marker = $self->spec->meta->testml_field_marker;
    my $current_block;
    my $current_field;
    my $current_notes = '';
    my @lines = ($text =~ /(.*\n)/g);

    my $is_throw_away = qr/^\s*(#.*)?$/;
    my $is_start_block = qr/^\Q$block_marker\E(?:\s+(.*))?$/;
    my $is_start_field = qr/^\Q$field_marker\E\s+(\w+)(?:\s*:\s*(.*?)\s*)?$/;

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
            $lines[0] !~ $is_start_field &&
            $lines[0] !~ $is_start_block;
        $block->notes($notes);
        last BLOCK unless @lines;
        if ($lines[0] =~ $is_start_block) {
            $r1 = $1;
            next BLOCK;
        }
        $lines[0] =~ $is_start_field or die;
        $r1 = $1;
        $r2 = $2;
        FIELD: while (@lines) {
            shift(@lines);
            my $set = 0;
            my $field = TestML::Spec::Field->new(name => $r1);
            $block->add($field);
            if (defined $r2) {
                $field->content($r2);
                $set = 1;
            }

            my $text = '';
            $text .= shift(@lines) while
                @lines &&
                $lines[0] !~ $is_start_field &&
                $lines[0] !~ $is_start_block;
            if ($set) {
                $field->notes($text);
            }
            else {
                $field->content($text);
            }
            last BLOCK unless @lines;
            if ($lines[0] =~ $is_start_block) {
                $r1 = $1;
                next BLOCK;
            }
            $lines[0] =~ $is_start_field or die;
            $r1 = $1;
            $r2 = $2;
            next FIELD;
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
