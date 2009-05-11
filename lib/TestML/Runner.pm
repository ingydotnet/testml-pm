package TestML::Runner;
use strict;
use warnings;
use TestML::Base -base;

use TestML::Parser;
use Test::Builder;

field 'bridge';
field 'document';

field 'test_builder' => -init => 'Test::Builder->new';

sub run {
    my $self = shift;
    {
        local @INC = ('t', 't/lib', @INC);
        my $class = $self->bridge;
        eval "require $class";
        die $@ if $@;
    }

    my $parser = TestML::Parser->new();
    $parser->open($self->document);
    my $document = $parser->parse;

    print '=== ', $document->meta->title, " ===\n";

    if ($document->meta->tests) {
        $self->test_builder->plan(tests => $document->meta->tests);
    }
    else {
        $self->test_builder->no_plan();
    }

    while (my $test = $document->tests->next) {
        $document->data->reset;

        while (my $block = $document->data->next) {
            $block->fetch('SKIP') and next;
            $block->fetch('LAST') and last;
            for my $point_name ($test->point_names) {
                $block->fetch($point_name) or next; 
            }

            $self->do_test(
                $self->evaluate_expression($test->left, $block),
                $test->op,
                $self->evaluate_expression($test->right, $block),
                $block->label,
            );
        }
    }
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

sub do_test {
    my $self = shift;
    my $left = shift;
    my $operator = shift;
    my $right = shift;
    my $label = shift;
    if ($operator eq '==') {
        $self->test_builder->is_eq($left->value, $right->value, $label);
    }
}

package TestML::Context;
use TestML::Base -base;

field 'name';
field 'value';
