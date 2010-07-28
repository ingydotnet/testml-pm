package TestML::Parser;
use strict;
use warnings;
use utf8;
use TestML::Base -base;
use TestML::Parser::Grammar;
use TestML::Document;

my $document;
my $data;
my $statement;
my $transform_arguments;
my @expression_stack;

sub parse {
    my $self = shift;
    my $testml = shift;

    $document = TestML::Document->new();
    @expression_stack = ();
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
field '_unquoted_string';
field 'arguments' => [];

# ##############################################################################
# sub t {
#     my $name = shift;
#     for (@_) { eval "sub ${_}_$name { x }" }
# }
# 
# my $c = 0;
# sub x {
#     (my $name = (caller(1))[3]) =~ s/.*:://;
#     $c++;
#     warn "$c>> $name\n";
# }
# 
# # t qw(test_statement got not);
# # t qw(ws got);
# # t qw(data_block try got not);
# # t qw(data_header try got not);
# 
# ##############################################################################
# my %ESCAPES = (
#     '\\' => '\\',
#     "'" => "'",
#     'n' => "\n",
#     't' => "\t",
#     '0' => "\0",
# );

sub unquoted_string {
    my $self = shift;
    my $unquoted_string = shift;
    $self->_unquoted_string($unquoted_string);
}

# sub got_single_quoted_string {
#     my $self = shift;
#     my $value = shift;
#     $value =~ s/\\([\\\'])/$ESCAPES{$1}/g;
#     push @{$self->current_expression->[-1]->transforms},
#         TestML::Transform->new(
#             name => 'String',
#             args => [$value],
#         );
# }
# sub got_double_quoted_string {
#     my $self = shift;
#     my $value = shift;
#     $value =~ s/\\([\\\"nt])/$ESCAPES{$1}/g;
#     push @{$self->current_expression->[-1]->transforms},
#         TestML::Transform->new(
#             name => 'String',
#             args => [$value],
#         );
# }
##############################################################################
# sub got_document {
#     my $self = shift;
#     my $data_files = $self->document->meta->data->{Data};
#     if (not @$data_files) {
#         push @$data_files, '_';
#     }
# }

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

##############################################################################
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
        args => [], # TODO $self->arguments,
    );
    push @{$self->expression_stack->[-1]->transforms}, $transform;
    delete $self->{arguments};
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

sub data_block {
    my $self = shift;
    push @{$self->document->data->blocks}, $self->current_block;
}


__END__
sub try_argument {
    my $self = shift;
    push @{$self->current_expression},
        TestML::Expression->new();
}
sub got_argument {
    my $self = shift;
    push @{$self->arguments},
        pop @{$self->current_expression};
}
sub not_argument {
    my $self = shift;
    pop @{$self->current_expression};
}

sub try_test_expression {
    my $self = shift;
    push @{$self->current_expression},
        TestML::Expression->new();
}
sub got_test_expression {
    my $self = shift;
    push @{$self->insertion_stack},
        pop @{$self->current_expression};
}
sub not_test_expression {
    my $self = shift;
    pop @{$self->current_expression};
}

sub try_transform_call {
    my $self = shift;
    $self->arguments([]);
}

sub got_assertion_operator {
    my $self = shift;
    pop @{$self->insertion_stack};
    $self->statement->assertion(TestML::Assertion->new(name => 'EQ'));
    push @{$self->insertion_stack}, $self->statement->assertion->expression;
}

sub got_data_section {
    my $self = shift;
    $self->inline_data(shift);
}

###############################################################################

sub try_data_block {
    my $self = shift;
    $self->current_block(TestML::Block->new());
}

sub got_data_block {
    my $self = shift;
    push @{$self->blocks}, $self->current_block;
}

sub got_block_label {
    my $self = shift;
    $self->current_block->label(shift);
}

sub got_user_point_name {
    my $self = shift;
    $self->point_name(shift);
}

sub got_point_lines {
    my $self = shift;
    $self->current_block->points->{$self->point_name} = shift;
}

sub got_point_phrase {
    my $self = shift;
    $self->current_block->points->{$self->point_name} = shift;
}

1;
