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

field 'TestML' => 0.0.1;
field 'Data' => [];
field 'Title' => '';
field 'Plan' => 0;
field 'TestMLBlockMarker' => '===';
field 'TestMLPointMarker' => '---';

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
field 'iterator' => 0;

package TestML::Document::Expression;
use TestML::Base -base;

field 'sub_expressions' => [];
field 'assertion_expression';

package TestML::Document::SubExpression;
use TestML::Base -base;

field 'start';
field 'transforms' => [];
field 'iterator' => 0;

sub add {
    my $self = shift;
    push @{$self->transforms}, shift;
}

sub reset {
    my $self = shift;
    $self->iterator(0);
}

sub next {
    my $self = shift;
    my $iterator = $self->iterator;
    $self->iterator($iterator + 1);
    return $self->transforms->[$iterator];
}

sub peek {
    my $self = shift;
    my $iterator = $self->iterator;
    return $self->transforms->[$iterator];
}

package TestML::Document::Transform;
use TestML::Base -base;

field 'name';
field 'args' => [];

#-----------------------------------------------------------------------------
package TestML::Document::Data;
use TestML::Base -base;

field 'notes' => '';
field 'blocks' => [];
field 'iterator' => 0;

sub add {
    my $self = shift;
    push @{$self->blocks}, shift;
}

sub reset {
    my $self = shift;
    $self->iterator(0);
}

sub next {
    my $self = shift;
    my $iterator = $self->iterator;
    $self->iterator($iterator + 1);
    return $self->blocks->[$iterator];
}

package TestML::Document::Block;
use TestML::Base -base;

field 'label' => '';
field 'points' => {};

sub add {
    my $self = shift;
    my $point = shift;
    $self->points->{$point->name} = $point;
}

sub fetch {
    my $self = shift;
    my $name = shift;
    return $self->points->{$name};
}

package TestML::Document::Point;
use TestML::Base -base;
 
field 'name' => '';
field 'notes' => '';
field 'value' => '';

package TestML::Document::Builder;
use TestML::Base -base;
use TestML::Document;

field 'document', -init => 'TestML::Document->new()';

sub hit_meta_testml_statement {
    my $self = shift;
    my $version = shift;
    $self->document->meta->set('TestML', $version);
}

sub hit_meta_statement {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    $self->document->meta->set($key, $value);
}

sub pre_test_statement {
}
sub hit_test_statement {
}
sub not_test_statement {
}

sub xxxpre_test_section { warn "\n\n==== test section ====\n\n\n" }


