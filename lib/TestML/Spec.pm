package TestML::Spec;
use strict;
use warnings;

use TestML::Base -base;

field 'meta' => -init => 'TestML::Spec::Meta->new';
field 'tests' => -init => 'TestML::Spec::Tests->new';
field 'data' => -init => 'TestML::Spec::Data->new';

#-----------------------------------------------------------------------------
package TestML::Spec::Meta;
use TestML::Base -base;

field 'testml' => 0.0.1;
field 'title' => '';
field 'tests' => 0;
field 'data_syntax' => 'testml';
field 'testml_block_marker' => '===';
field 'testml_field_marker' => '---';

#-----------------------------------------------------------------------------
package TestML::Spec::Tests;
use TestML::Base -base;

sub add {
    my $self = shift;
    push @{$self->tests}, shift;
}

field 'tests' => [];
field 'iterator' => 0;

package TestML::Spec::Test;
use TestML::Base -base;

field 'op';
field 'left';
field 'right';

package TestML::Spec::Expr;
use TestML::Base -base;

sub add {
    my $self = shift;
    push @{$self->functions}, shift;
}

field 'name';
field 'functions' => [];

package TestML::Spec::Function;
use TestML::Base -base;

field 'name';
field 'args';

#-----------------------------------------------------------------------------
package TestML::Spec::Data;
use TestML::Base -base;

sub add {
    my $self = shift;
    push @{$self->blocks}, shift;
}

field 'notes' => '';
field 'blocks' => [];
field 'iterator' => 0;

package TestML::Spec::Block;
use TestML::Base -base;

sub add {
    my $self = shift;
    my $field = shift;
    $self->fields->{$field->name} = $field;
}

field 'description' => '';
field 'notes' => '';
field 'fields' => {};

package TestML::Spec::Field;
use TestML::Base -base;

field 'name' => '';
field 'notes' => '';
field 'content' => '';

1;
