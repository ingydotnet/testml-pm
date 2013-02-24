#
# This is the Lite version of the TestML compiler. It can parse simple
# statements and assertions and also parse the TestML data format.

package TestML::Lite::Compiler;
use TestML::Mo;

use constant POINT => qr/^\*(\w+)/;

# support assignment statement for any variable
sub compile {
    my ($self, $document) = @_;
    my $function = TestML::Function->new;
    $document =~ /\A(.*?)(^===.*)?\z/ms or die;
    my ($code, $data) = ($1, $2);
    while ($code =~ s{(.*)$/}{}) {
        my $line = $1;
        next if $line =~ /^\s*(#|$)/;
        if ($line =~ /^%TestML +(\d+\.\d+\.\d+)\s*$/) {
            $function->setvar(
                'TestMLVersion' => TestML::Str->new(value => $1),
            );
        }
        elsif ($line =~ /^\s*(\w+) *= *(.+?);?\s*$/) {
            my ($key, $value) = ($1, $2);
            $value =~ s/^(['"])(.*)\1$/$2/;
            $value = $value =~ /^\d+$/
              ? TestML::Num->new(value => $value)
              : TestML::Str->new(value => $value);
            $function->setvar($key, $value);
        }
        elsif ($line =~ /^.*(?:==|~~).*;?\s*$/) {
            $line =~ s/;$//;
            push @{$function->statements}, $self->compile_assertion($line);
        }
        else {
            die "Failed to parse TestML::Lite document, here:\n$code";
        }
    }
    if ($data) {
        $function->{data} = $self->compile_data($data);
    }
    $function->outer(TestML::Function->new());
    return $function;
}

sub compile_assertion {
    my ($self, $expr) = @_;
    my ($left, $op, $right) = (TestML::Expression->new, undef, undef);
    my $side = $left;
    my $points = [];
    my $assertion = undef;
    while (length $expr) {
        my $token = $self->get_token($expr);
        $token =~ POINT && do {
            push @{$side->units}, $self->make_unit($token, $points);
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
                      ? $self->compile_assertion($_)
                      : $self->make_unit($_, $points);
                } @args
            ];
            my $call = TestML::Call->new(
                name => $token->[0],
                args => $args,
                explicit_call => 1,
            );
            push @{$side->units}, $call;
        } ||
        $token->isa('TestML::Object') && do {
            push @{$side->units}, $token;
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
        points => $points,
    );
}

sub make_unit {
    my ($self, $token, $points) = @_;
    if ($token =~ POINT) {
        my $name = $1;
        push @$points, $name;
        return TestML::Point->new(name => $name)
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
            /^\w+$/ ? TestML::Variable->new(name => $_) :
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
        $token = TestML::Num->new(value => $2);
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
    my ($self, $string);
    $_[1] =~ s/^#.*\n//mg;
    $_[1] =~ s/^\\//mg;
    $_[1] =~ s/^\s*\n//mg;
    my @blocks = grep $_, split /(^===.*?(?=^===|\z))/ms, $_[1];
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
    return $data;
}

1;
