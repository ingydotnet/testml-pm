package TestML::Runner;
use strict;
use warnings;
use TestML::Base -base;

use TestML::Parser;
use Test::Builder;

field 'fixture_class';
field 'testml_file';
field 'test_builder' => -init => 'Test::Builder->new';

sub run {
    my $self = shift;
    my $parser = TestML::Parser->new();
    $parser->open($self->testml_file);
    my $test = $parser->parse;

    if ($test->tests) {
        $self->test_builder->plan(tests => $test->tests);
    }
    else {
        $self->test_builder->no_plan();
    }
    $self->test_builder->ok(1);
    $self->test_builder->ok(1);
    $self->test_builder->ok(1);
    $self->test_builder->ok(1);
}

1;
