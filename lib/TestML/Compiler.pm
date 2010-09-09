package TestML::Compiler;

use TestML::Base -base;
use TestML::Grammar;

has 'base';
has 'debug' => '0';

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

    my $debug = $self->debug;
    $debug = $result->{DebugPegex} if defined $result->{DebugPegex};
    my $grammar = TestML::Grammar->new(
        receiver => TestML::Receiver->new,
        debug => $debug,
    );
    $grammar->parse($code, 'code_section')
        or die "Parse TestML code section failed";

    $self->fixup_grammar($grammar, $result);

    $grammar->parse($data, 'data_section')
        or die "Parse TestML data section failed";

    if ($result->{DumpAST}) {
        XXX($grammar->receiver->function);
    }

    return $grammar->receiver->function;
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
                $result->{TestML} = $value;
                next;
            }
            $order_error = 1 unless $result->{TestML};
            if ($directive eq 'Include') {
                $text .= $self->preprocess($self->slurp($value))->{text};
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
            if $top and not $result->{TestML};
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

    $grammar = $grammar->grammar;
    my $point_lines = $grammar->{point_lines}{'+re'};

    my $block_marker = $hash->{BlockMarker};
    if ($block_marker) {
        $block_marker =~ s/([\$\%\^\*\+\?\|])/\\$1/g;
        $grammar->{block_marker}{'+re'} = qr/\G$block_marker/;
        $point_lines =~ s/===/$block_marker/;
    }

    my $point_marker = $hash->{PointMarker};
    if ($point_marker) {
        $point_marker =~ s/([\$\%\^\*\+\?\|])/\\$1/g;
        $grammar->{point_marker}{'+re'} = qr/\G$point_marker/;
        $point_lines =~ s/---/$point_marker/;
    }

    $grammar->{point_lines}{'+re'} = qr/$point_lines/;
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


#-----------------------------------------------------------------------------
package TestML::Receiver;
use TestML::Base -base;

use TestML::Runtime;

has 'function', -init => 'TestML::Function->new()';

has 'stack' => [];
has 'block';

has 'string';
has 'point_name';

my %ESCAPES = (
    '\\' => '\\',
    "'" => "'",
    'n' => "\n",
    't' => "\t",
    '0' => "\0",
);

sub got_single_quoted_string {
    my $self = shift;
    my $string = shift;
    $string =~ s/\\([\\\'])/$ESCAPES{$1}/g;
    $self->string($string);
}

sub got_double_quoted_string {
    my $self = shift;
    my $string = shift;
    $string =~ s/\\([\\\"nt])/$ESCAPES{$1}/g;
    $self->string($string);
}

sub got_unquoted_string {
    my $self = shift;
    $self->string(shift);
}

sub try_assignment_statement {
    my $self = shift;
    push @{$self->function->statements}, TestML::Statement->new();
    my $expression = $self->function->statements->[-1]->expression;
    $expression->units->[0] = TestML::Transform->new(name => 'Set');
    $self->function->statements->[-1]->expression($expression);
    push @{$self->stack}, TestML::Expression->new;
}

sub got_assignment_statement {
    my $self = shift;
    $self->function->statements->[-1]->expression->units->[0]->args->[1] =
        pop @{$self->stack};
}

sub not_assignment_statement {
    my $self = shift;
    pop @{$self->function->statements};
    pop @{$self->stack};
}

sub got_variable_name {
    my $self = shift;
    my $variable_name = shift;
    $self->function->statements->[-1]->expression->units->[0]->args->[0] =
        $variable_name;
}

sub try_code_statement {
    my $self = shift;
    push @{$self->function->statements}, TestML::Statement->new();
    push @{$self->stack}, $self->function->statements->[-1]->expression;
}

sub got_code_statement {
    my $self = shift;
    pop @{$self->stack};
}

sub not_code_statement {
    my $self = shift;
    pop @{$self->function->statements};
    pop @{$self->stack};
}

sub got_point_object {
    my $self = shift;
    my $point_name = shift;
    $point_name =~ s/^\*// or die;
    push @{$self->stack->[-1]->units},
        TestML::Transform->new(
            name => 'Point',
            args => [$point_name],
        );
    push @{$self->function->statements->[-1]->points}, $point_name;
}

sub try_function_object {
    my $self = shift;
    my $function = TestML::Function->new(outer => $self->function);
    $self->function($function);
}

sub got_function_object {
    my $self = shift;
    push @{$self->stack->[-1]->units}, $self->function;
    $self->function($self->function->outer);
}

sub not_function_object {
    my $self = shift;
    $self->function($self->function->outer);
}

sub got_function_variable {
    my $self = shift;
    push @{$self->function->signature}, shift;
}

sub try_transform_object {
    my $self = shift;
    push @{$self->stack->[-1]->units}, TestML::Transform->new();
}

sub not_transform_object {
    my $self = shift;
    pop @{$self->stack->[-1]->units};
}

sub got_transform_name {
    my $self = shift;
    $self->stack->[-1]->units->[-1]->name(shift);
}

sub got_transform_argument_list {
    my $self = shift;
    $self->stack->[-1]->units->[-1]->explicit_call(1);
}

sub try_transform_argument {
    my $self = shift;
    push @{$self->stack}, TestML::Expression->new;
}

sub got_transform_argument {
    my $self = shift;
    my $argument = pop @{$self->stack};
    push @{$self->stack->[-1]->units->[-1]->args}, $argument;
}

sub not_transform_argument {
    my $self = shift;
    pop @{$self->stack};
}

sub got_string_object {
    my $self = shift;
    push @{$self->stack->[-1]->units},
        TestML::Str->new(value => $self->string);
}

sub got_number_object {
    my $self = shift;
    push @{$self->stack->[-1]->units},
        TestML::Num->new(value => shift);
}

sub try_assertion_call {
    my $self = shift;
    $self->function->statements->[-1]->assertion(TestML::Assertion->new);
    push @{$self->stack},
        $self->function->statements->[-1]->assertion->expression;
}

sub got_assertion_call {
    my $self = shift;
    pop @{$self->stack};
}

sub not_assertion_call {
    my $self = shift;
    $self->function->statements->[-1]->assertion(undef);
    pop @{$self->stack};
}

sub got_assertion_eq {
    my $self = shift;
    $self->function->statements->[-1]->assertion->name('EQ');
}

sub got_assertion_ok {
    my $self = shift;
    $self->function->statements->[-1]->assertion->name('OK');
}

sub got_assertion_has {
    my $self = shift;
    $self->function->statements->[-1]->assertion->name('HAS');
}

sub got_block_label {
    my $self = shift;
    $self->block(TestML::Block->new(label => shift));
}

sub got_point_name {
    my $self = shift;
    $self->point_name(shift);
}

sub got_point_phrase {
    my $self = shift;
    my $point_phrase = shift;
    $self->block->points->{$self->point_name} = $point_phrase;
}

sub got_point_lines {
    my $self = shift;
    my $point_lines = shift;
    $self->block->points->{$self->point_name} = $point_lines;
}

sub got_data_block {
    my $self = shift;
    push @{$self->function->data}, $self->block;
}
