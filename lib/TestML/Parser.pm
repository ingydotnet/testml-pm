package TestML::Parser;
use strict;
use warnings;
use TestML::Base -base;
use TestML::Parser::Grammar;
use TestML::Document;

sub parse {
    my $self = shift;
    my $testml = shift;

    my $document = TestML::Document->new();
    TestML::Parser::Grammar->new()->parse(
        $testml,
        rule => 'document',
        receiver => TestML::Parser::Actions->new(document => $document),
    ) or die "Parse TestML failed";
#     $self->parse_data($parser);
    return $document;
}

# TODO - No tests for external data sections yet.
# sub parse_data {
#     my $self = shift;
#     my $parser = shift;
#     my $builder = $parser->receiver;
#     my $document = $builder->document;
#     for my $file (@{$document->meta->data->{Data}}) {
#         my $parser = TestML::Parser->new(
#             receiver => TestML::Parser::Actions->new(),
#             grammar => $parser->grammar,
#             start_token => 'data',
#         );
# 
#         if ($file eq '_') {
#             $parser->stream($builder->inline_data);
#         }
#         else {
#             $parser->open($self->base . '/' . $file);
#         }
#         $parser->parse;
#         push @{$document->data->blocks}, @{$parser->receiver->blocks};
#     }
# }

#-----------------------------------------------------------------------------
package TestML::Parser::Actions;
use TestML::Base -base;

use TestML::Document;

field 'document', -init => 'TestML::Document->new()';
field 'grammar';

field 'statement';
field 'expression_stack' => [];
field 'inline_data';

field 'current_block';
field 'blocks' => [];
field 'point_name';
field '_point_name';
field '_transform_name';
field 'string';
field 'transform_arguments' => [];

my %ESCAPES = (
    '\\' => '\\',
    "'" => "'",
    'n' => "\n",
    't' => "\t",
    '0' => "\0",
);

sub single_quoted_string {
    my $self = shift;
    my $string = shift;
    $string =~ s/\\([\\\'])/$ESCAPES{$1}/g;
    $self->string($string);
}

sub double_quoted_string {
    my $self = shift;
    my $string = shift;
    $string =~ s/\\([\\\"nt])/$ESCAPES{$1}/g;
    $self->string($string);
}

sub unquoted_string {
    my $self = shift;
    my $string = shift;
    $self->string($string);
}

sub meta_section {
    my $self = shift;

#     if ($meta_keyword =~ /^(Block|Point)Marker$/) {
#         $meta_keyword =~ s{([a-z])?([A-Z])}
#                           {$1 ? ($1 . '_' . lc($2)) : lc($2)}ge;
#         $meta_value =~ s/([\$\%\^\*\+\?\|])/\\$1/g;
#         $self->grammar->{$meta_keyword} = '/' . $meta_value . '/';
#     }

#     $self->grammar->{BlockMarker} = $self->document->meta->data->{BlockMarker};
#     $self->grammar->{PointMarker} = $self->document->meta->data->{PointMarker};
}


sub meta_testml_statement {
    my $self = shift;
    my $testml_version = shift;
    $self->document->meta->data->{TestML} = $testml_version;
}

sub meta_statement {
    my $self = shift;
    my $meta_keyword = shift;
    my $meta_value = shift;
#     if (ref($self->document->meta->data->{$meta_keyword}) eq 'ARRAY') {
#         push @{$self->document->meta->data->{$meta_keyword}}, $meta_value;
#     }
#     else {
        $self->document->meta->data->{$meta_keyword} = $meta_value;
#     }
}

sub test_statement_start {
    my $self = shift;
    $self->statement(TestML::Statement->new());
    push @{$self->expression_stack}, $self->statement->expression;
}

sub test_statement {
    my $self = shift;
    push @{$self->document->test->statements}, $self->statement;
    pop @{$self->expression_stack};
}

sub point_call {
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

sub transform_name {
    my $self = shift;
    my $name = shift;
    $self->_transform_name($name);
}

sub transform_call {
    my $self = shift;
    my $transform_name = $self->_transform_name;
    my $transform = TestML::Transform->new(
        name => $transform_name,
        args => $self->transform_arguments,
    );
    push @{$self->expression_stack->[-1]->transforms}, $transform;
}

sub transform_argument_list_start {
    my $self = shift;
    push @{$self->expression_stack}, TestML::Expression->new;
    $self->transform_arguments([]);
}

sub transform_argument {
    my $self = shift;
    push @{$self->transform_arguments}, pop @{$self->expression_stack};
    push @{$self->expression_stack}, TestML::Expression->new;
}

sub transform_argument_list_stop {
    my $self = shift;
    pop @{$self->expression_stack};
}

sub string_call {
    my $self = shift;
    my $string = $self->string;
    my $transform = TestML::Transform->new(
        name => 'String',
        args => [ $string ],
    );
    push @{$self->expression_stack->[-1]->transforms}, $transform;
}

sub assertion_operator {
    my $self = shift;
    pop @{$self->expression_stack};
    $self->statement->assertion(TestML::Assertion->new(name => 'EQ'));
    push @{$self->expression_stack}, $self->statement->assertion->expression;
}

sub block_label {
    my $self = shift;
    my $block_label = shift;
    my $block = TestML::Block->new(label => $block_label);
    $self->current_block($block);
}

sub user_point_name {
    my $self = shift;
    my $point_name = shift;
    $self->_point_name($point_name);
}

sub point_phrase {
    my $self = shift;
    my $point_phrase = shift;
    $self->current_block->points->{$self->point_name} = $point_phrase;
}

sub point_lines {
    my $self = shift;
    my $point_lines = shift;
    $self->current_block->points->{$self->point_name} = $point_lines;
}

sub data_block {
    my $self = shift;
    push @{$self->document->data->blocks}, $self->current_block;
}

sub NO_META_TESTML_ERROR {
    die 'No TestML meta directive found';
}

sub SEMICOLON_ERROR {
    die 'You seem to be missing a semicolon';
}

1;
