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
    my $spec = $parser->parse;

    if ($spec->meta->tests) {
        $self->test_builder->plan(tests => $spec->meta->tests);
    }
    else {
        $self->test_builder->no_plan();
    }

    while (my $test = $spec->tests->next) {
        $spec->data->reset;
        while (my $block = $spec->data->next) {
            $self->test_builder->ok(1, 'Dummy test');
        }
    }
}

1;
