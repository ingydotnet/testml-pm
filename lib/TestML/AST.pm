package TestML::AST;
use Pegex::Mo;
extends 'Pegex::Receiver';

use TestML::Runtime;

has points => default => sub{[]};
has function => ();

# sub final {
#     my ($self, $match, $top) = @_;
#     return $match
# }
# __END__

sub got_code_section {
    my ($self, $code) = @_;
    my $statements = [];
    for (@$code) {
        push @$statements, $_
            if ref eq 'TestML::Statement';
    }
    return TestML::Function->new(
        @$statements ? (statements => $statements) : (),
    );
}

sub got_assignment_statement {
    my ($self, $match) = @_;
    return TestML::Statement->new(
        expression => TestML::Expression->new(
            units => [
                TestML::Transform->new(
                    name => 'Set',
                    args => [
                        $match->[0]{variable_name}{1},
                        $match->[1],
                    ],
                ),
            ],
        ),
    );
}

sub got_code_statement {
    my ($self, $list) = @_;
    my ($expression, $assertion);
    my $points = $self->points;
    $self->points([]);
    
    for (@$list) {
        if (ref eq 'TestML::Expression') {
            $expression = $_;
        }
        if (ref eq 'TestML::Assertion') {
            $assertion = $_;
        }
    }
    return TestML::Statement->new(
        $expression ? ( expression => $expression ) : (),
        $assertion ? ( assertion => $assertion ) : (),
        @$points ? ( points => $points ) : (),
    );
}

sub got_code_expression {
    my ($self, $list) = @_;
    my $units = [];
    push @$units, shift @$list if @$list;
    $list = shift @$list || [];
    for (@$list) {
        my $unit = $_->{unit_call}[0][0];
        push @$units, $unit;
    }
    return TestML::Expression->new(
        units => $units,
    );
}

sub got_code_object {
    my ($self, $code) = @_;
    if (my $point = $code->{point_object}) {
        my $name = $point->{1};
        $name =~ s/^\*// or die;
        push @{$self->points}, $name;
        return TestML::Transform->new(
            name => 'Point',
            args => [$name],
        );
    }
    if (my $transform = $code->{transform_object}) {
        return $transform;
    }
    if (my $string = $code->{string_object}) {
        return $self->make_str($string);
    }
    if (my $number = $code->{number_object}) {
        return TestML::Num->new(
            value => $number->{number}{1},
        );
    }
    else { WWW $code }
}

sub make_str {
    my ($self, $object) = @_;
    my $str;
    if ($str = $object->{quoted_string}) {
        $str = $str->{1};
    }
    return TestML::Str->new(
        value => $str,
    );
}

sub got_assertion_call {
    my ($self, $call) = @_;
    my ($name, $assertion);
    for (qw(
        assertion_eq
        assertion_has
        assertion_ok
    )) {
        if ($assertion = $call->{$_}) {
            ($name = uc($_)) =~ s/.*_//;
            my $key = "assertion_operator_" . lc $name;
            $assertion = $assertion->{$key}[0];
            last;
        }
    }
    XXX $call unless $assertion;
    return TestML::Assertion->new(
        name => $name,
        expression => $assertion,
    );
}

sub got_transform_name {
    my ($self, $match) = @_;
    if (my $transform = $match->{user_transform}) {
        return TestML::Transform->new(name => $transform->{1});
    }
    else { XXX $match }
}

sub got_unquoted_string {
    my ($self, $match) = @_;
    return $match->{1};
}

sub got_semicolon { return }

#----------------------------------------------------------
sub got_data_section {
    my ($self, $data) = @_;
    return TestML::Function->new(
        data => $data,
    );
}

sub got_data_block {
    my ($self, $block) = @_;
    return TestML::Block->new(
        label => $block->[0]{block_header}[1][1]{block_label},
        points => +{map %$_, @{$block->[2]}},
    );
}

sub got_block_point {
    my ($self, $point) = @_;
    
    return $point;
}

sub got_phrase_point {
    my ($self, $point) = @_;
    return {
        $point->[0]{point_name}{1} => $point->[1]{point_phrase}{1},
    };
}

1;
