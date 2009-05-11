package TestML::Parser;
use strict;
use warnings;
use TestML::Base -base;

use TestML::Document;

field 'stream';
field 'document', -init => 'TestML::Document->new()';;
field 'count_stack' => [];

sub open {
    my $self = shift;
    my $file = shift;
    $self->stream($self->read($file));
}

sub read {
    my $self = shift;
    my $file = shift;
    CORE::open FILE, $file
      or die "Can't open file '$file' for input.";
    my $content = do {local $/; <FILE>};
    if (length $content and $content !~ /\n\z/) {
        die "File '$file' does not end with a newline.";
    }
    my $lines = @{[($content =~ /(\n)/g)]};
    push @{$self->count_stack}, {
        file => $file,
        line => 0,
        lines => $lines,
    };
    return $content;
}

sub getline {
    my $self = shift;
    return unless length($self->{stream});
    $self->{stream} =~ s/(.*\n)// or die;
    return $1;
}

sub ungetline {
    my $self = shift;
    my $line = shift;
    $self->stream("$line$self->{stream}");
}

sub parse {
    my $self = shift;
    $self->_parse_head();
    $self->_parse_data();
    return $self->document;
}

my $NON_SPACE = '\S';
my $NON_BREAK = '.';
my $space = '[\ \t]';
my $eol = '\r?\n';
my $keyword = '[a-z][a-z0-9_]*';
my $value = "$NON_SPACE($NON_BREAK*$NON_SPACE)";
my $match_meta = qr/^($keyword):$space+($value)$eol/;
my $match_test = qr/^(.+?)\s+(==)\s+(.+?)\s*$eol/;
my $match_include = qr/^%include$space+($NON_BREAK*$NON_SPACE)$eol/;

sub _parse_head {
    my $self = shift;
    while (my $line = $self->getline()) {
        if ($line =~ $match_meta) {
            my ($key, $value) = ($1, $2);
            $self->error("Invalid meta keyword '$key'\n")
                unless $self->document->meta->has($key);
            $self->document->meta->$key($value);
        }
        elsif ($line =~ $match_test) {
            my ($left, $op, $right) = ($1, $2, $3);
            my $test = TestML::Document::Test->new(
               left => $self->_parse_expression($left), 
               op => $op,
               right => $self->_parse_expression($right), 
            );
            $self->document->tests->add($test);
        }
        elsif ($line =~ $match_include) {
            die;
        }
        elsif ($line =~ /^\s*(#.*)?$/) {
            next;
        }
        elsif ($line =~ /^===\s+\S/) {
            $self->ungetline($line);
            last;
        }
        else {
            $self->error("TestML parse failure\n");
        }
    }
}

sub _parse_expression {
    my $self = shift;
    my $text = shift;
    $text =~ s/^(\w+)//;
    my $expression = TestML::Document::Expression->new(start => $1);
    while (length $text) {
        $text =~ s/^\.(\w+)// or die;
        my $func = TestML::Document::Transform->new(name => $1);
        $expression->add($func);
        if ($text =~ s/^\((.*?)\)//) {
            my $args = $1;
            $args =~ s/^'(.*)'$/$1/;
            $func->args([$args]);
        }
    }
    return $expression;
}

sub _parse_data {
    my $self = shift;
    my $text = $self->stream;
    my $block_marker = $self->document->meta->testml_block_marker;
    my $point_marker = $self->document->meta->testml_point_marker;
    my $current_block;
    my $current_point;
    my @lines = ($text =~ /(.*\n)/g);

    my $is_throw_away = qr/^\s*(#.*)?$/;
    my $is_start_block = qr/^\Q$block_marker\E(?:\s+(.*))?$/;
    my $is_start_point = qr/^\Q$point_marker\E\s+(\w+)(?:\s*:\s*(.*?)\s*)?$/;

    my ($r1, $r2);
    $lines[0] =~ $is_start_block;
    $r1 = $1;

    BLOCK: while (@lines) {
        shift(@lines);
        my $block = TestML::Document::Block->new(label => $r1);
        $self->document->data->add($block);

        shift(@lines) while
            @lines &&
            $lines[0] !~ $is_start_point &&
            $lines[0] !~ $is_start_block;

        last BLOCK unless @lines;
        if ($lines[0] =~ $is_start_block) {
            $r1 = $1;
            next BLOCK;
        }
        $lines[0] =~ $is_start_point or die;
        $r1 = $1;
        $r2 = $2;
        POINT: while (@lines) {
            shift(@lines);
            my $set = 0;
            my $point = TestML::Document::Point->new(name => $r1);
            $block->add($point);
            if (defined $r2) {
                $point->value($r2);
                $set = 1;
            }

            my $text = '';
            $text .= shift(@lines) while
                @lines &&
                $lines[0] !~ $is_start_point &&
                $lines[0] !~ $is_start_block;
            $point->value($text) unless $set;
            if (@lines and $lines[0] =~ $is_start_point) {
                $r1 = $1;
                $r2 = $2;
                next POINT;
            }
            if ($block->points->{ONLY}) {
                $self->document->data->blocks([]);
                $self->document->data->add($block);
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

sub error {
    require Carp;
    my $self = shift;
    my $msg = shift;
    Carp::croak($msg);
}

1;
