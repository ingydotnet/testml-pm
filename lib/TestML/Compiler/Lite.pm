##
# This is the Lite version of the TestML compiler. It can parse simple
# statements and assertions and also parse the TestML data format.

package TestML::Compiler::Lite;
use TestML::Base;
extends 'TestML::Compiler';

use TestML::Runtime;

has function => ();

# TODO Use more constants for regexes
use constant POINT => qr/^\*(\w+)/;

sub compile_code {
    my ($self) = @_;
    $self->{function} = TestML::Function->new;
    my $code = $self->code;
    while (length $code) {
        $code =~ s{^(.*)\r?\n?}{};
        my $line = $1;
        $self->parse_comment($line) ||
        $self->parse_directive($line) ||
        $self->parse_assignment($line) ||
        $self->parse_assertion($line) ||
            die "Failed to parse TestML document, here:\n$line$/$code";
    }
}

sub parse_comment {
    my ($self, $line) = @_;
    $line =~ /^\s*(#|$)/ or return;
    return 1;
}

sub parse_directive {
    my ($self, $line) = @_;
    $line =~ /^%TestML +(\d+\.\d+\.\d+)\s*$/ or return;
    $self->function->setvar(
        'TestML' => TestML::Str->new(value => $1),
    );
    return 1;
}

sub parse_assignment {
    my ($self, $line) = @_;
    $line =~ /^\s*(\w+) *= *(.+?);?\s*$/ or return;
    my ($key, $value) = ($1, $2);
    $value =~ s/^(['"])(.*)\1$/$2/;
    $value = $value =~ /^\d+$/
      ? TestML::Num->new(value => $value)
      : TestML::Str->new(value => $value);
    push @{$self->function->statements}, TestML::Statement->new(
        expression => TestML::Expression->new(
            calls => [
                TestML::Call->new(
                    name => 'Set',
                    args => [
                        $key,
                        TestML::Expression->new(
                            calls => [ $value ],
                        ),
                    ],
                ),
            ],
        )
    );
    return 1;
}

sub parse_assertion {
    my ($self, $line) = @_;
    $line =~ /^.*(?:==|~~).*;?\s*$/ or return;
    $line =~ s/;$//;
    push @{$self->function->statements}, $self->compile_assertion($line);
    return 1;
}

sub compile_assertion {
    my ($self, $expr, $points) = @_;
    $points ||= [];
    my ($left, $op, $right) = (TestML::Expression->new, undef, undef);
    my $side = $left;
    my $assertion = undef;
    while (length $expr) {
        my $token = $self->get_token($expr);
        $token =~ POINT && do {
            push @{$side->calls}, $self->make_call($token, $points);
        } ||
        $token =~ /^(==|~~)$/ && do {
            my $name = $token eq '==' ? 'EQ' : 'HAS';
            $left = $side;
            $side = $right = TestML::Expression->new;
            $assertion = TestML::Assertion->new(
                name => $name,
                expression => $right,
            );
        } ||
        ref($token) eq 'ARRAY' && do {
            my @args = @$token;
            shift @args;
            my $args = [
                map {
                  /\./
                      ? $self->compile_assertion($_, $points)
                      : $self->make_call($_, $points);
                } @args
            ];
            my $call = TestML::Call->new(
                name => $token->[0],
                @$args ? (
                    args => $args,
                    explicit_call => 1,
                ) : (),
            );
            push @{$side->calls}, $call;
        } ||
        $token->isa('TestML::Object') && do {
            push @{$side->calls}, $token;
        } ||
        do {
            XXX $expr, $token;
        };
    }

    $right = $side if $right;
    return $left unless $right;
    return TestML::Statement->new(
        expression => $left,
        assertion => $assertion,
        @$points ? (points => $points) : (),
    );
}

sub make_call {
    my ($self, $token, $points) = @_;
    if ($token =~ POINT) {
        my $name = $1;
        push @$points, $name;
        return TestML::Point->new(name => $name);
    }
    if (not ref $token) {
        return TestML::Str->new(value => $token);
    }
    else {
        return $token;
    }
}

sub get_token {
    my ($self, $expr) = @_;
    my ($token, $args);
    if ($_[1] =~ s/^(\w+)\(([^\)]+)\)\.?//) {
        ($token, $args) = ([$1], $2);
        push @$token, map {
            /^(\w+)$/ ? TestML::Expression->new(
                calls => [
                    TestML::Call->new(name => $_),
                ]
            ) :
            /^(['"])(.*)\1$/ ? $2 :
            $_;
        } split /,\s*/, $args;
    }
    elsif ($_[1] =~ s/^\s*(==|~~)\s*//) {
        $token = $1;
    }
    elsif ($_[1] =~ s/^(['"])(.*?)\1//) {
        $token = TestML::Str->new(value => $2);
    }
    elsif ($_[1] =~ s/^(\d+)//) {
        $token = TestML::Num->new(value => $1);
    }
    elsif ($_[1] =~ s/^(\*\w+)\.?//) {
        $token = $1;
    }
    elsif ($_[1] =~ s/^(\w+)\.?//) {
        $token = [$1];
    }
    else {
        die "Can't get token from '$_[1]'";
    }
    return $token;
}

sub compile_data {
    my ($self) = @_;
    my $input = $self->data;
    $input =~ s/^#.*\n/\n/mg;
    $input =~ s/^\\//mg;
    my @blocks = grep $_, split /(^===.*?(?=^===|\z))/ms, $input;
    for my $block (@blocks) {
        $block =~ s/\n+\z/\n/;
    }

    my $data = [];
    for my $string_block (@blocks) {
        my $block = TestML::Block->new;
        $string_block =~ s/^===\ +(.*?)\ *\n//g
            or die "No block label! $string_block";
        $block->{label} = $1;
        while (length $string_block) {
            next if $string_block =~ s/^\n+//;
            my ($key, $value);
            if ($string_block =~ s/\A---\ +(\w+):\ +(.*)\n//g or
                $string_block =~ s/\A---\ +(\w+)\n(.*?)(?=^---|\z)//msg
            ) {
                ($key, $value) = ($1, $2);
            }
            else {
                die "Failed to parse TestML string:\n$string_block";
            }
            $block->{points} ||= {};
            $block->{points}{$key} = $value;

            if ($key =~ /^(ONLY|SKIP|LAST)$/) {
                $block->{$key} = 1;
            }
        }
        push @$data, $block;
    }
    $self->function->{data} = $data if @$data;
}

1;
