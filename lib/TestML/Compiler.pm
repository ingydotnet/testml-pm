package TestML::Compiler;

use TestML::Mo;
use TestML::Grammar;
use TestML::AST;

has base => ();

sub compile {
    my $self = shift;
    my $file = shift;
    if (not ref $file and $file !~ /\n/) {
        $file =~ s/(.*)\/(.*)/$2/ or die;
        $self->base($1);
    }
    my $input = (not ref($file) and $file =~ /\n/)
        ? $file
        : $self->slurp($file);

    my $result = $self->preprocess($input, 'top');

    my ($code, $data) = @$result{qw(code data)};

    my $grammar = TestML::Grammar->new(
        receiver => TestML::AST->new,
    );
    $grammar->parse($code, 'code_section')
        or die "Parse TestML code section failed";

    $self->fixup_grammar($grammar, $result);

    if (length $data) {
        $grammar->parse($data, 'data_section')
            or die "Parse TestML data section failed";
    }

    if ($result->{DumpAST}) {
        XXX($grammar->receiver->function);
    }

    my $function = $grammar->receiver->function;
    $function->outer(TestML::Function->new());

    return $function;
}

sub preprocess {
    my $self = shift;
    my $text = shift;
    my $top = shift;

    my @parts = split /^((?:\%\w+.*|\#.*|\ *)\n)/m, $text;

    $text = '';

    my $result = {
        TestML => '',
        DataMarker => '',
        BlockMarker => '===',
        PointMarker => '---',
    };

    my $order_error = 0;
    for my $part (@parts) {
        next unless length($part);
        if ($part =~ /^(\#.*|\ *)\n/) {
            $text .= "\n";
            next;
        }
        if ($part =~ /^%(\w+)\s*(.*?)\s*\n/) {
            my ($directive, $value) = ($1, $2);
            $text .= "\n";
            if ($directive eq 'TestML') {
                die "Invalid TestML directive"
                    unless $value =~ /^\d+\.\d+$/;
                die "More than one TestML directive found"
                    if $result->{TestML};
                $result->{TestML} = TestML::Str->new(value => $value);
                next;
            }
            $order_error = 1 unless $result->{TestML};
            if ($directive eq 'Include') {
                my $sub_result = $self->preprocess($self->slurp($value));
                $text .= $sub_result->{text};
                $result->{DataMarker} = $sub_result->{DataMarker};
                $result->{BlockMarker} = $sub_result->{BlockMarker};
                $result->{PointMarker} = $sub_result->{PointMarker};
                die "Can't define %TestML in an Included file"
                    if $sub_result->{TestML};
            }
            elsif ($directive =~ /^(DataMarker|BlockMarker|PointMarker)$/) {
                $result->{$directive} = $value;
            }
            elsif ($directive =~ /^(DebugPegex|DumpAST)$/) {
                $value = 1 unless length($value);
                $result->{$directive} = $value;
            }
            else {
                die "Unknown TestML directive '$directive'";
            }
        }
        else {
            $order_error = 1 if $text and not $result->{TestML};
            $text .= $part;
        }
    }

    if ($top) {
        die "No TestML directive found"
            unless $result->{TestML};
        die "%TestML directive must be the first (non-comment) statement"
            if $order_error;

        my $DataMarker = $result->{DataMarker} ||= $result->{BlockMarker};
        my ($code, $data);
        if ((my $split = index($text, "\n$DataMarker")) >= 0) {
            $result->{code} = substr($text, 0, $split + 1);
            $result->{data} = substr($text, $split + 1);
        }
        else {
            $result->{code} = $text;
            $result->{data} = '';
        }

        $result->{code} =~ s/^\\(\\*[\%\#])/$1/gm;
        $result->{data} =~ s/^\\(\\*[\%\#])/$1/gm;
    }
    else {
        $result->{text} = $text;
    }

    return $result;
}

sub fixup_grammar {
    my $self = shift;
    my $grammar = shift;
    my $hash = shift;

    my $namespace = $grammar->receiver->function->namespace;
    $namespace->{TestML} = $hash->{TestML};

    my $tree = $grammar->tree;

    my $point_lines = $tree->{point_lines}{'.rgx'};

    my $block_marker = $hash->{BlockMarker};
    if ($block_marker) {
        $block_marker =~ s/([\$\%\^\*\+\?\|])/\\$1/g;
        $tree->{block_marker}{'.rgx'} = qr/\G$block_marker/;
        $point_lines =~ s/===/$block_marker/;
    }

    my $point_marker = $hash->{PointMarker};
    if ($point_marker) {
        $point_marker =~ s/([\$\%\^\*\+\?\|])/\\$1/g;
        $tree->{point_marker}{'.rgx'} = qr/\G$point_marker/;
        $point_lines =~ s/\\-\\-\\-/$point_marker/;
    }

    $tree->{point_lines}{'.rgx'} = qr/$point_lines/;
}

sub slurp {
    my $self = shift;
    my $file = shift;
    my $fh;
    if (ref($file)) {
        $fh = $file;
    }
    else {
        my $path = join '/', $self->base, $file;
        open $fh, $path
            or die "Can't open '$path' for input: $!";
    }
    local $/;
    return <$fh>;
}

1;
