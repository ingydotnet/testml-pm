package TestML::Document;
use strict;
use warnings;

use TestML::Base -base;

field 'meta' => -init => 'TestML::Document::Meta->new';
field 'tests' => -init => 'TestML::Document::Tests->new';
field 'data' => -init => 'TestML::Document::Data->new';

#-----------------------------------------------------------------------------
package TestML::Document::Meta;
use TestML::Base -base;

field 'data' => {
    'TestML', '',
    'Data' => [],
    'Title' => '',
    'Plan' => 0,
    'TestMLBlockMarker' => '===',
    'TestMLPointMarker' => '---',
};

sub has {
    my $self = shift;
    my $name = shift;
    return ($name =~ /^(
        TestML |
        Data |
        Title |
        Plan |
        TestMLBlockMarker |
        TestMLPointMarker
    )$/x);
}

sub get {
    my $self = shift;
    my $key = shift;
    return $self->{$key};
}

sub set {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    $self->{$key} = $value;
    return $self->{$key};
}

#-----------------------------------------------------------------------------
package TestML::Document::Tests;
use TestML::Base -base;

field 'expressions' => [];

package TestML::Document::Expression;
use TestML::Base -base;

field 'sub_expressions' => [];
field 'assertion_expression';
field 'points' => [];

package TestML::Document::SubExpression;
use TestML::Base -base;

field 'name';
field 'args' => [];

#-----------------------------------------------------------------------------
package TestML::Document::Data;
use TestML::Base -base;

field 'notes' => '';
field 'blocks' => [];
field 'iterator' => 0;

package TestML::Document::Block;
use TestML::Base -base;

field 'label' => '';
field 'points' => {};

package TestML::Document::Point;
use TestML::Base -base;
 
field 'name' => '';
field 'notes' => '';
field 'value' => '';

#-----------------------------------------------------------------------------
package TestML::Document::Builder;
use TestML::Base -base;

field 'document', -init => 'TestML::Document->new()';
field 'expressions' => [];
field 'stash' => {};

# - or_list
# - and_list
# - reference
# - regexp

sub got_meta_testml_statement {
    my $self = shift;
    my $version = shift;
    $self->document->meta->set('TestML', $version);
}

sub got_meta_statement {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    $self->document->meta->set($key, $value);
}

sub try_test_expression {
    my $self = shift;
    my $exprs = $self->expressions;
    push @$exprs, TestML::Document::Expression->new();
}

sub got_test_expression {
    die 42;
    my $self = shift;
    my $exprs = $self->stash->expressions;
    if (@$exprs == 1) {
        push @{$self->document->tests->expressions}, pop @$exprs;
    }
    else {
        die "XXX under construction";;
    }
}

sub not_test_expression {
    my $self = shift;
    pop @{$self->expressions};
}







