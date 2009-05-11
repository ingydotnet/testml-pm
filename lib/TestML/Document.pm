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

field 'testml' => 0.0.1;
field 'title' => '';
field 'tests' => 0;
field 'testml_block_marker' => '===';
field 'testml_point_marker' => '---';

#-----------------------------------------------------------------------------
package TestML::Document::Tests;
use TestML::Base -base;

field 'tests' => [];
field 'iterator' => 0;

sub add {
    my $self = shift;
    push @{$self->tests}, shift;
}

sub reset {
    my $self = shift;
    $self->iterator(0);
}

sub next {
    my $self = shift;
    my $iterator = $self->iterator;
    $self->iterator($iterator + 1);
    return $self->tests->[$iterator];
}

package TestML::Document::Test;
use TestML::Base -base;

field 'op';
field 'left';
field 'right';
field 'point_names' => [];

package TestML::Document::Expression;
use TestML::Base -base;

field 'start';
field 'functions' => [];
field 'iterator' => 0;

sub add {
    my $self = shift;
    push @{$self->functions}, shift;
}

sub reset {
    my $self = shift;
    $self->iterator(0);
}

sub next {
    my $self = shift;
    my $iterator = $self->iterator;
    $self->iterator($iterator + 1);
    return $self->functions->[$iterator];
}

sub peek {
    my $self = shift;
    my $iterator = $self->iterator;
    return $self->functions->[$iterator];
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
