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

sub get {
    my $self = shift;
    my $key = shift;
    return $self->data->{$key};
}

sub set {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    $self->data->{$key} = $value;
    return $self->data->{$key};
}

#-----------------------------------------------------------------------------
package TestML::Document::Tests;
use TestML::Base -base;

field 'expressions' => [];

package TestML::Document::Expression;
use TestML::Base -base;

field 'transforms' => [];
field 'assertion_expression';
field 'points' => [];

package TestML::Document::Transform;
use TestML::Base -base;

field 'name';
field 'args' => [];

#-----------------------------------------------------------------------------
package TestML::Document::Data;
use TestML::Base -base;

field 'blocks' => [];

package TestML::Document::Block;
use TestML::Base -base;

field 'label' => '';
field 'points' => {};

package TestML::Document::Point;
use TestML::Base -base;
 
field 'name' => '';
field 'value' => '';

#-----------------------------------------------------------------------------
package TestML::Document::Builder;
use TestML::Base -base;

field 'document', -init => 'TestML::Document->new()';
field 'expressions' => [];
field 'stash' => {};

sub got_document {
    my $self = shift;
#     XXX $self->document;
}

sub got_meta_testml_statement {
    my $self = shift;
    my $version = shift;
    $self->document->meta->set('TestML', $version);
}

sub x {
    (my $name = (caller(1))[3]) =~ s/.*:://;
#     warn ">> $name\n";
}

sub got_meta_statement {x
    my $self = shift;
    my $key = shift;
    my $value = shift;
    $self->document->meta->set($key, $value);
}

sub try_test_expression {x
    my $self = shift;
    my $exprs = $self->expressions;
    push @$exprs, TestML::Document::Expression->new();
}

sub got_test_expression {x
    my $self = shift;
    my $exprs = $self->expressions;
    if (@$exprs == 1) {
        push @{$self->document->tests->expressions}, pop @$exprs;
    }
    else {
        die "XXX under construction";;
    }
}

sub not_test_expression {x
    my $self = shift;
    pop @{$self->expressions};
}

sub got_data_point {x
    my $self = shift;
    my $point = shift;
    push @{$self->expressions->[0]->points}, $point;
    push @{$self->expressions->[-1]->transforms},
        TestML::Document::Transform->new(
            name => $point,
        );
}

sub try_assertion_operator {x}
sub got_assertion_operator {x}
sub not_assertion_operator {x}




