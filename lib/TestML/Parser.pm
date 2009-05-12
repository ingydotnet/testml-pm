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

my $ANY = '[\s\S]';
my $SPACE = '[\ \t]';
my $BREAK = '\n';
my $EOL = '\r?\n';
my $NON_SPACE = '\S';
my $NON_BREAK = '.';
my $ALPHA = '[A-Za-z]';
my $ALPHANUM = '[A-Za-z0-9]';
my $WORD = '\w';
my $BACK = '\\';
my $SINGLE = "'";
my $DOUBLE = '"';
my $ESCAPE = '[0abenrtz]';

my $keyword = '[a-z][a-z0-9_]*';
my $line = "$NON_BREAK*$EOL";
my $value = "$NON_SPACE(?:$NON_BREAK*$NON_SPACE)";

my $match_meta = qr/^($keyword):$SPACE+($value)$EOL/;
my $match_test = qr/^$WORD+(?:\.|$SPACE+==$SPACE)/;
my $match_include = qr/^%include$SPACE+($NON_BREAK*$NON_SPACE)$EOL/;
my $match_comment = qr/^#$line/;
my $match_blank = qr/^$SPACE*$EOL/;
my $match_single =
    qr/^$SINGLE((?:[^$BREAK$BACK$SINGLE]|$BACK$SINGLE|$BACK$BACK)*)$SINGLE/;
my $match_double =
    qr/^$DOUBLE((?:[^$BREAK$BACK$DOUBLE]|$BACK$DOUBLE|$BACK$BACK|$BACK$ESCAPE)*)$DOUBLE/;
my $match_yaml_data = qr/^---(SPACE|EOL)/;
my $match_json_data = qr/^\[/;
my $match_xml_data = qr/^\</;

sub parse {
    my $self = shift;
    while (my $line = $self->getline()) {
        my $marker = $self->document->meta->testml_block_marker;
        my $match_testml_data = qr/^$marker($SPACE|$EOL)/;
        if ($line =~ $match_meta) {
            my ($key, $value) = ($1, $2);
            $self->error("Invalid meta keyword '$key'\n")
                unless $self->document->meta->has($key);
            $self->document->meta->$key($value);
        }
        elsif ($line =~ $match_test) {
            $self->_parse_assertion($line);
        }
        elsif ($line =~ $match_include) {
            die;
        }
        elsif ($line =~ $match_blank) {
            next;
        }
        elsif ($line =~ $match_comment) {
            next;
        }
        elsif ($line =~ $match_testml_data) {
            $self->ungetline($line);
            $self->_parse_testml_data();
            last;
        }
        elsif ($line =~ $match_yaml_data) {
            $self->ungetline($line);
            $self->_parse_yaml_data();
            last;
        }
        elsif ($line =~ $match_json_data) {
            $self->ungetline($line);
            $self->_parse_json_data();
            last;
        }
        elsif ($line =~ $match_xml_data) {
            $self->ungetline($line);
            $self->_parse_xml_data();
            last;
        }
        else {
            $self->error("TestML parse failure\n");
        }
    }
    return $self->document;
}

sub _parse_assertion {
    my $self = shift;
    my $text = shift;
    my ($left, $op, $right);
    while (1) {
        last if $left and $right;
        $text =~ s/^($WORD+)// or die;
        my $point_name = $1;
        my $transforms = [];
        while ($text =~ s/^\.($WORD+)\($SPACE*//) {
            my $transform_name = $1;
            my $arguments = [];
            while (1) {
                my $t = $text;
                if ($text =~ s/^($WORD+)//) {
                    push @$arguments,
                        TestML::Document::Expression->new(start => $1);
                }
                elsif ($text =~ s/$match_single//) {
                    my $string = $1;
                    $string =~ s/\\([\\\'])/$1/g;
                    push @$arguments, $string;
                }
                elsif ($text =~ s/$match_double//) {
                    my $string = $1;
                    # TODO Unescape ESCAPEs
                    $string =~ s/\\([\\\"])/$1/g;
                    push @$arguments, $string;
                }
                if ($text =~ s/^$SPACE*\)//) {
                    last;
                }
                $text =~ s/^$SPACE*,$SPACE*//
                    or die;
            }
            push @$transforms, TestML::Document::Transform->new(
                name => $transform_name,
                args => $arguments,
            );
        }
        my $expression = TestML::Document::Expression->new(
            start => $point_name,
            transforms => $transforms,
        );
        if (! $left) { $left = $expression }
        elsif (! $right) { $right = $expression }
        else { die }
    }
    continue {
        if (not $op) {
            $text =~ s/^$SPACE*(==)$SPACE+// or die;
            $op = $1;
        }
    }
    die unless $left and $op and $right;
    $self->document->tests->add(
        TestML::Document::Test->new(
           left => $left, 
           op => $op,
           right => $right, 
        )
    );
}

sub _parse_testml_data {
    my $self = shift;
    my $text = $self->stream;
    my $block_marker = $self->document->meta->testml_block_marker;
    my $point_marker = $self->document->meta->testml_point_marker;
    my $current_block;
    my $current_point;
    my @lines = ($text =~ /(.*\n)/g);

    my $is_start_block = qr/^\Q$block_marker\E(?:\s+(.*))?$/;
    my $is_start_point = qr/^\Q$point_marker\E\s+(\w+)(?:\s*:\s*(.*?)\s*)?$/;

    my ($r1, $r2);
    $lines[0] =~ $is_start_block;
    $r1 = $1;

    BLOCK: while (@lines) {
        shift(@lines);
        my $block = TestML::Document::Block->new(label => $r1);
        $self->document->data->add($block);

        shift(@lines) while @lines && $lines[0] !~ $is_start_point &&
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

sub _parse_yaml_data {
    my $self = shift;
    die "YAML data section support not yet implemented";
}

sub _parse_json_data {
    my $self = shift;
    die "JSON data section support not yet implemented";
}

sub _parse_xml_data {
    my $self = shift;
    die "XML data section support not yet implemented";
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

sub error {
    require Carp;
    my $self = shift;
    my $msg = shift;
    Carp::croak($msg);
}

1;
