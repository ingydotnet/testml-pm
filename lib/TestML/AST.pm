package TestML::AST;
use Pegex::AST -base;

use TestML::Runtime;

has points => -init => '[]';

# sub final {
#     my ($self, $match, $top) = @_;
#     return $match
# }

sub got_code_section {
    my ($self, $match) = @_;
    my $code = $match->{code_section} or die;
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
    $match = $match->{assignment_statement};
    return TestML::Statement->new(
        expression => TestML::Expression->new(
            units => [
                TestML::Transform->new(
                    name => 'Set',
                    args => [
                        $match->[0]{variable_name}{1},
                        $match->[2],
                    ],
                ),
            ],
        ),
    );
}

sub got_code_statement {
    my ($self, $match) = @_;
    my ($expression, $assertion);
    my $points = $self->points;
    $self->points([]);
    
    my $list = $match->{code_statement};
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
    my ($self, $match) = @_;
    my $units = [];
    my $list = $match->{code_expression};
    push @$units, shift @$list if @$list;
    $list = shift @$list || [];
    for (@$list) {
        my $unit = $_->{unit_call}[2][0];
        push @$units, $unit;
    }
    return TestML::Expression->new(
        units => $units,
    );
}

sub got_code_object {
    my ($self, $match) = @_;
    if (my $point = $match->{code_object}{point_object}) {
        my $name = $point->{1};
        $name =~ s/^\*// or die;
        push @{$self->points}, $name;
        return TestML::Transform->new(
            name => 'Point',
            args => [$name],
        );
    }
    my $code = $match->{code_object};
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
    else { WWW $match }
}

sub make_str {
    my ($self, $object) = @_;
    my $str;
    if ($str = $object->{quoted_string}{single_quoted_string}) {
        $str = $str->{1};
    }
    return TestML::Str->new(
        value => $str,
    );
}

sub got_assertion_call {
    my ($self, $match) = @_;
    my $call = $match->{assertion_call} or die;
    my ($name, $assertion);
    for (qw(
        assertion_eq
        assertion_has
        assertion_ok
    )) {
        if ($assertion = $call->{$_}) {
            ($name = uc($_)) =~ s/.*_//;
            my $key = "assertion_operator_" . lc $name;
            $assertion = $assertion->{$key}[1];
            last;
        }
    }
    XXX $match unless $assertion;
    return TestML::Assertion->new(
        name => $name,
        expression => $assertion,
    );
}

sub got_transform_name {
    my ($self, $match) = @_;
    if (my $transform = $match->{transform_name}{user_transform}) {
        return TestML::Transform->new(name => $transform->{1});
    }
    else { XXX $match }
}

sub got_unquoted_string {
    my ($self, $match) = @_;
    return $match->{unquoted_string}{1};
}

sub got_semicolon { return }

#----------------------------------------------------------
sub got_data_section {
    my ($self, $match) = @_;
    return TestML::Function->new(
        data => $match->{data_section},
    );
}

sub got_data_block {
    my ($self, $match) = @_;
    my $block = $match->{data_block};
    return TestML::Block->new(
        label => $block->[0]{block_header}[1][1]{block_label},
        points => +{map %$_, @{$block->[2]}},
    );
}

sub got_block_point {
    my ($self, $match) = @_;
    
    return $match->{block_point};
}

sub got_phrase_point {
    my ($self, $match) = @_;

    $match = $match->{phrase_point};
    return {
        $match->[2]{point_name}{1} => $match->[4]{point_phrase}{1},
    };
}

1;
