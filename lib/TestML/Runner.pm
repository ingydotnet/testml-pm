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
    my $self = shift;
    my $class = $self->bridge or die "No Bridge class specified";
    eval "require $class; 1" or die $@;
    return $class->new();
}

sub run {
    my $self = shift;

    $self->base(($0 =~ /(.*)\//) ? $1 : '.');

    $self->setup();

    $self->title();

    $self->plan_begin();

    for my $statement (@{$self->doc->tests->statements}) {
        my $blocks = $self->select_blocks($statement->points);
        for my $block (@$blocks) {
            my $left = $self->evaluate_expression(
                $statement->primary_expression->[0],
                $block,
            );
            if (@{$statement->assertion_expression}) {
                my $right = $self->evaluate_expression(
                    $statement->assertion_expression->[0],
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
    my $block = shift;

    my $topic = TestML::Topic->new(
        document => $self->doc,
        block => $block,
        value => undef,
    );

    for my $transform (@{$expression->transforms}) {
        my $function = $self->Bridge->get_transform_function($transform->name);
        $topic->value(&$function($topic, @{$transform->args}));
    }
    return $topic;
}

sub parse {
    my $self = shift;

    my $parser = TestML::Parser->new(
        receiver => TestML::Document::Builder->new(),
        start_token => 'document',
    );

    $parser->open($self->document);
    $parser->parse;

    $self->parse_data($parser->receiver);
    return $parser->receiver->document;
}

sub parse_data {
    my $self = shift;
    my $builder = shift;
    my $document = $builder->document;
    for my $file (@{$document->meta->data->{Data}}) {
        my $parser = TestML::Parser->new(
            receiver => TestML::Document::Builder->new(),
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

package TestML::Topic;
use TestML::Base -base;

field 'document';
field 'block';
field 'value';
