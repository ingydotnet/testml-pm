package TestML::Runner;
use strict;
use warnings;
use TestML::Base -base;

use TestML::Document;
use TestML::Parser;

field 'bridge';
field 'document';
field 'doc', -init => '$self->parse()';

sub setup {
    die "\nDon't use TestML::Runner directly.\nUse an appropriate subclass like TestML::Runner::TAP.\n";
}

sub run {
    my $self = shift;
    $self->setup();

    $self->title();

    $self->plan_begin();

#     XXX $self->doc;

    for my $statement (@{$self->doc->tests->statements}) {
#         $self->doc->data->reset;
# 
#         while (my $block = $self->doc->data->next) {
#             $block->fetch('SKIP') and next;
#             $block->fetch('LAST') and last;
#             for my $point_name ($test->point_names) {
#                 $block->fetch($point_name) or next; 
#             }
# 
#             $self->do_test(
#                 $self->evaluate_expression($test->left, $block),
#                 $test->op,
#                 $self->evaluate_expression($test->right, $block),
#                 $block->label,
#             );
#         }
    }

    $self->plan_end();
}

sub evaluate_expression {
    my $self = shift;
    my $expression = shift;
    my $block = shift;

    my $point = $block->fetch($expression->start);

    my $context = TestML::Context->new(
        name => $point->name,
        value => $point->value,
    );

    my $transform = $expression->peek;
    if ($transform and $transform->name eq 'raw') {
        $expression->next;
    }
    else {
        $context->{value} =~ s/\A\s*\n//;
        $context->{value} =~ s/\n\s*\z/\n/;
    }

    $expression->reset;
    while (my $transform = $expression->next) {
        my $function = $self->bridge->get_transform_function($transform->name)
            or die;
        my @args = @{$transform->args};
        my $value = &$function($context, @args);
        $context->value($value);
    }

    return $context;
}

sub parse {
    my $self = shift;

    my $parser = TestML::Parser->new(
        receiver => TestML::Document::Builder->new(),
        start_token => 'document',
    );

    $parser->open($self->document);
    $parser->parse;
#     $self->parse_data($parser->receiver->document);
    return XXX $parser->receiver->document;
}

sub parse_data {
    my $self = shift;
    my $document = shift;
    for my $file (@{$document->meta->get('Data')}) {
        my $parser = TestML::Parser->new(
            receiver => TestML::Document::Builder->new(),
            start_token => 'data',
        );
        if ($file eq '_') {
            $parser->stream($document->inline_data);
        }
        else {
            die "XXX - data files not implemented yet";
        }
        $self->parse;
        push @{$document->data->blocks}, @{$parser->receiver->blocks};
    }
}

package TestML::Context;
use TestML::Base -base;

field 'name';
field 'value';
