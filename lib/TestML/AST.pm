package TestML::AST;
use Pegex::Mo;
extends 'Pegex::Receiver';

use TestML::Runtime;

has points => default => sub{[]};
has function => default => sub { TestML::Function->new };

# sub final {
#     my ($self, $match, $top) = @_;
#     XXX $match;
# }
# __END__

# sub got_testml_document {
#     my ($self, $document) = @_;
# }

sub got_code_section {
    my ($self, $code) = @_;
    $self->function->statements($code);
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
#         WWW $_;
        my $unit = $_->[0]; #->{unit_call}[0][0];
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
    else { $code }
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
    for (qw( eq has ok )) {
        if ($assertion = $call->{"assertion_$_"}) {
            $name = uc $_;
            $assertion =
                $assertion->{"assertion_operator_$_"}[0] ||
                $assertion->{"assertion_function_$_"}[0];
            last;
        }
    }
    XXX $call unless $assertion;
    return TestML::Assertion->new(
        name => $name,
        expression => $assertion,
    );
}

sub got_assertion_function_ok {
    my ($self, $ok) = @_;
    return {
        assertion_function_ok => [
            TestML::Expression->new,
        ]
    }
}

sub got_function_start {
    my ($self) = @_;
    my $function = TestML::Function->new();
    $function->outer($self->function);
    $self->function($function);
    return 1;
}

sub got_function_object {
    my ($self, $object) = @_;

    my $function = $self->function;
    $self->function($self->function->outer);

    if (@{$object->[0]} and @{$object->[0][0]}) {
        $function->signature($object->[0][0]);
    }
    $function->statements($object->[2]);

    return $function;
}

sub got_function_variables {
    my ($self, $variables) = @_;
    my $vars = [];
    push @$vars, $variables->[0]{function_variable}{1};
    push @$vars, map $_->[0]{function_variable}{1}, @{$variables->[1]};
    return $vars;
}

sub got_transform_name {
    my ($self, $match) = @_;
    my $transform;
    if ($transform = $match->{core_transform} || $match->{user_transform}) {
        return TestML::Transform->new(name => $transform->{1});
    }
    else { XXX $match }
}

sub got_transform_object {
    my ($self, $object) = @_;
    my $transform = $object->[0];
    my $args = [];
    push @$args, $object->[1][0][0],
        if $object->[1][0][0];
    push @$args, map $_->[0], @{$object->[1][0][1]};
    $transform->args($args) if @$args;
    $transform->explicit_call(1)
        if $object->[1][1];
    return $transform;
}

sub got_transform_argument_list {
    my ($self, $list) = @_;
    push @$list, 'explicit';
    return $list;
}

sub got_transform_argument {
    my ($self, $arg) = @_;
    return $arg;
}

sub got_unquoted_string {
    my ($self, $match) = @_;
    return $match->{1};
}

sub got_semicolon { return }

#----------------------------------------------------------
sub got_data_section {
    my ($self, $data) = @_;
    $self->function->data($data);
}

sub got_data_block {
    my ($self, $block) = @_;
    return TestML::Block->new(
        label => $block->[0]{block_header}[0][0]{block_label},
        points => +{map %$_, @{$block->[1]}},
    );
}

sub got_lines_point {
    my ($self, $point) = @_;
    return {
        $point->[0]{point_name}{1} => $point->[1]{point_lines}{1},
    };
}

sub got_phrase_point {
    my ($self, $point) = @_;
    return {
        $point->[0]{point_name}{1} => $point->[1]{point_phrase},
    };
}

1;
