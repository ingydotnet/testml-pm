package TestML::Runner;
use strict;
use warnings;
use TestML::Base -base;

use TestML::Document;
use TestML::Parser;

field 'bridge';
field 'document';
field 'base';
field 'doc', -init => '$self->parse()';
field 'Bridge', -init => '$self->init_bridge';

sub setup {
    die "\nDon't use TestML::Runner directly.\nUse an appropriate subclass like TestML::Runner::TAP.\n";
}

sub init_bridge {
    die "'init_bridge' must be implemented in subclass";
}

sub run {
    my $self = shift;

    $self->base(($0 =~ /(.*)\//) ? $1 : '.');
    $self->title();
    $self->plan_begin();

    for my $statement (@{$self->doc->tests->statements}) {
        my $points = $statement->points;
        if (not @$points) {
            my $left = $self->evaluate_expression($statement->left_expression->[0]);
            if (@{$statement->right_expression}) {
                my $right = $self->evaluate_expression(
                    $statement->right_expression->[0]
                );
                $self->do_test('EQ', $left, $right, undef);
            }
            next;
        }
        my $blocks = $self->select_blocks($points);
        for my $block (@$blocks) {
            my $left = $self->evaluate_expression(
                $statement->left_expression->[0],
                $block,
            );
            if (@{$statement->right_expression}) {
                my $right = $self->evaluate_expression(
                    $statement->right_expression->[0],
                    $block,
                );
                $self->do_test('EQ', $left, $right, $block->label);
            }
        }
    }
    $self->plan_end();
}

sub select_blocks {
    my $self = shift;
    my $points = shift;
    my $blocks = [];

    OUTER: for my $block (@{$self->doc->data->blocks}) {
        exists $block->points->{SKIP} and next;
        exists $block->points->{LAST} and last;
        for my $point (@$points) {
            next OUTER unless exists $block->points->{$point};
        }
        if (exists $block->points->{ONLY}) {
            @$blocks = ($block);
            last;
        }
        push @$blocks, $block;
    }
    return $blocks;
}

sub evaluate_expression {
    my $self = shift;
    my $expression = shift;
    my $block = shift || undef;

    my $context = TestML::Context->new(
        document => $self->doc,
        block => $block,
        value => undef,
    );

    for my $transform (@{$expression->transforms}) {
        my $transform_name = $transform->name;
        next if $context->error and $transform_name ne 'Catch';
        my $function = $self->Bridge->__get_transform_function($transform_name);
        my $value = eval {
            &$function(
                $context,
                map {
                    (ref($_) eq 'TestML::Expression')
                    ? $self->evaluate_expression($_, $block)
                    : $_
                } @{$transform->args}
            );
        };
        if ($@) {
            $context->error($@);
        }
        else {
            $context->value($value);
        }
    }
    if ($context->error) {
        die $context->error;
    }
    return $context;
}

sub parse {
    my $self = shift;

    my $parser = TestML::Parser->new(
        receiver => TestML::Document::Builder->new(),
        start_token => 'document',
    );
    $parser->receiver->grammar($parser->grammar);

    $parser->open($self->document);
    $parser->parse;

    $self->parse_data($parser);
    return $parser->receiver->document;
}

sub parse_data {
    my $self = shift;
    my $parser = shift;
    my $builder = $parser->receiver;
    my $document = $builder->document;
    for my $file (@{$document->meta->data->{Data}}) {
        my $parser = TestML::Parser->new(
            receiver => TestML::Document::Builder->new(),
            grammar => $parser->grammar,
            start_token => 'data',
        );

        if ($file eq '_') {
            $parser->stream($builder->inline_data);
        }
        else {
            $parser->open($self->base . '/' . $file);
        }
        $parser->parse;
        push @{$document->data->blocks}, @{$parser->receiver->blocks};
    }
}

package TestML::Context;
use TestML::Base -base;

field 'document';
field 'block';
field 'point';
field 'value';
field 'error';
