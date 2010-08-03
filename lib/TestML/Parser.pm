package TestML::Parser;
use strict;
use warnings;
use TestML::Base -base;
use TestML::Parser::Grammar;
use TestML::Document;

sub parse {
    my $parser = TestML::Parser::Grammar->new(
        rule => 'document',
        receiver => TestML::Parser::Actions->new,
    );
    $parser->parse($_[1])
        or die "Parse TestML failed";
    return $parser->receiver->document;
}

sub parse_data {
    my $parser = TestML::Parser::Grammar->new(
        rule => 'data_section',
        receiver => TestML::Parser::Actions->new,
    );
    $parser->parse($_[1])
        or die "Parse TestML data failed";
    return $parser->receiver->document->data->blocks;
}

#-----------------------------------------------------------------------------
package TestML::Parser::Actions;
use TestML::Base -base;

use TestML::Document;

has 'document', -init => 'TestML::Document->new()';

has 'statement';
has 'expression_stack' => [];
has 'current_block';
has 'point_name';
has 'transform_name';
has 'string';
has 'transform_arguments' => [];

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

sub got_meta_section {
    my $self = shift;

    my $grammar = TestML::Parser::Grammar->grammar;

    my $block_marker = $self->document->meta->data->{BlockMarker};
    $block_marker =~ s/([\$\%\^\*\+\?\|])/\\$1/g;
    $grammar->{block_marker}{'+re'} = qr/\G$block_marker/;

    my $point_marker = $self->document->meta->data->{PointMarker};
    $point_marker =~ s/([\$\%\^\*\+\?\|])/\\$1/g;
    $grammar->{point_marker}{'+re'} = qr/\G$point_marker/;

    my $point_lines = $grammar->{point_lines}{'+re'};
    $point_lines =~ s/===/$block_marker/;
    $point_lines =~ s/---/$point_marker/;
    $grammar->{point_lines}{'+re'} = qr/$point_lines/;
}

sub got_meta_testml_statement {
    my $self = shift;
    $self->document->meta->data->{TestML} = shift;
}

sub got_meta_statement {
    my $self = shift;
    my $meta_keyword = shift;
    my $meta_value = shift;
    if (ref($self->document->meta->data->{$meta_keyword}) eq 'ARRAY') {
        push @{$self->document->meta->data->{$meta_keyword}}, $meta_value;
    }
    else {
        $self->document->meta->data->{$meta_keyword} = $meta_value;
    }
}

sub try_test_statement {
    my $self = shift;
    $self->statement(TestML::Statement->new());
    push @{$self->expression_stack}, $self->statement->expression;
}

sub got_test_statement {
    my $self = shift;
    push @{$self->document->test->statements}, $self->statement;
}

sub end_test_statement {
    my $self = shift;
    pop @{$self->expression_stack};
}

sub got_point_call {
    my $self = shift;
    my $point_name = shift;
    $point_name =~ s/^\*// or die;
    my $transform = TestML::Transform->new(
        name => 'Point',
        args => [$point_name],
    );
    push @{$self->expression_stack->[-1]->transforms}, $transform;
    push @{$self->statement->points}, $point_name;
}

sub got_transform_call {
    my $self = shift;
    pop @{$self->expression_stack};
    my $transform_name = $self->transform_name;
    my $transform = TestML::Transform->new(
        name => $transform_name,
        args => $self->transform_arguments,
    );
    push @{$self->expression_stack->[-1]->transforms}, $transform;
}

sub got_transform_name {
    my $self = shift;
    $self->transform_name(shift);
    push @{$self->expression_stack}, TestML::Expression->new;
    $self->transform_arguments([]);
}

sub got_transform_argument {
    my $self = shift;
    push @{$self->transform_arguments}, pop @{$self->expression_stack};
    push @{$self->expression_stack}, TestML::Expression->new;
}

sub got_string_call {
    my $self = shift;
    my $string = $self->string;
    my $transform = TestML::Transform->new(
        name => 'String',
        args => [ $string ],
    );
    push @{$self->expression_stack->[-1]->transforms}, $transform;
}

sub try_assertion_call {
#     print "try_assertion_call\n";
    my $self = shift;
    $self->statement->assertion(TestML::Assertion->new);
    push @{$self->expression_stack}, $self->statement->assertion->expression;
}

sub got_assertion_call {
#     print "got_assertion_call\n";
    my $self = shift;
    pop @{$self->expression_stack};
}

sub not_assertion_call {
#     print "not_assertion_call\n";
    my $self = shift;
    $self->statement->assertion(undef);
    pop @{$self->expression_stack};
}

sub got_assertion_eq {
    my $self = shift;
    $self->statement->assertion->name('EQ');
}

sub got_assertion_ok {
    my $self = shift;
    $self->statement->assertion->name('OK');
}

sub got_assertion_has {
    my $self = shift;
    $self->statement->assertion->name('HAS');
}

sub got_block_label {
    my $self = shift;
    my $block = TestML::Block->new(label => shift);
    $self->current_block($block);
}

sub got_point_name {
    my $self = shift;
    $self->point_name(shift);
}

sub got_point_phrase {
    my $self = shift;
    my $point_phrase = shift;
    $self->current_block->points->{$self->point_name} = $point_phrase;
}

sub got_point_lines {
    my $self = shift;
    my $point_lines = shift;
    $self->current_block->points->{$self->point_name} = $point_lines;
}

sub got_data_block {
    my $self = shift;
    push @{$self->document->data->blocks}, $self->current_block;
}

# TODO Refactor errors...
sub got_NO_META_TESTML_ERROR {
    die 'No TestML meta directive found';
}

sub got_SEMICOLON_ERROR {
    die 'You seem to be missing a semicolon';
}

1;
