package TestML::Runner;
use strict;
use warnings;
use TestML::Base -base;

use TestML::Parser;
use Test::Builder;
use Test::More();

field 'bridge';
field 'testml';
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
    $parser->open($self->testml);
    my $spec = $parser->parse;

    print '=== ', $spec->meta->title, " ===\n";

    if ($spec->meta->tests) {
        $self->test_builder->plan(tests => $spec->meta->tests);
    }
    else {
        $self->test_builder->no_plan();
    }

    while (my $test = $spec->tests->next) {
        $spec->data->reset;
        my $left_name = $test->left->start;
        my $op = $test->op;
        my $right_name = $test->right->start;
        while (my $block = $spec->data->next) {
            $block->fetch('SKIP') and next;
            $block->fetch('LAST') and last;
            my $left_entry = $block->fetch($test->left->start) or next; 
            my $right_entry = $block->fetch($test->right->start) or next; 

            $self->test(
                $self->apply($test->left, $left_entry),
                $test->op,
                $self->apply($test->right, $right_entry),
                $block->description,
            );
        }
    }
}

sub apply {
    my $self = shift;
    my $expr = shift;
    my $entry = shift;

    my $value = $entry->value;

    my $function = $expr->peek;

    if ($function and $function->name eq 'raw') {
        $expr->next;
    }
    else {
        $value =~ s/\A\s*\n//;
        $value =~ s/\n\s*\z/\n/;
    }

    $expr->reset;
    while (my $function = $expr->next) {
        my $func = $self->bridge->get_function($function->name)
            or die;
        my @args = @{$function->args};
        $value = &$func($value, @args);
    }

    return $value;
}

sub test {
    my $self = shift;
    my $left_value = shift;
    my $operator = shift;
    my $right_value = shift;
    my $description = shift;
    if (ref($left_value)) {
        Test::More::is_deeply($left_value, $right_value, $description);
    }
    else {
        $self->test_builder->is_eq($left_value, $right_value, $description);
    }
}
