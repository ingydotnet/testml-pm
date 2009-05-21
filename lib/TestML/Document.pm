package TestML::Document;
use strict;
use warnings;

use TestML::Base -base;

field 'meta' => -init => 'TestML::Document::Meta->new';
field 'tests' => -init => 'TestML::Document::Tests->new';
field 'data' => -init => 'TestML::Document::Data->new';
field 'inline_data';

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

field 'statements' => [];

package Statement;
use TestML::Base -base;

field 'points' => [];
field 'primary_expression' => [];
field 'assertion_operator';
field 'assertion_expression' => [];

package Expression;
use TestML::Base -base;

field 'transforms' => [];

package Transform;
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
field 'current_statement';
field 'insert_expression_here' => [];
field 'current_expression' => [];

##############################################################################
sub t {
    my $name = shift;
    for (@_) { eval "sub ${_}_$name { x }" }
}

my $c = 0;
sub x {
    (my $name = (caller(1))[3]) =~ s/.*:://;
    $c++;
#     warn "$c>> $name\n";
}

# t qw(test_statement got not);
# t qw(ws got);


##############################################################################
sub got_document {
    my $self = shift;
    my $data_files = $self->document->meta->get('Data');
    if (not @$data_files) {
        push @$data_files, '_';
    }
}

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

##############################################################################
sub try_test_statement {x
    my $self = shift;
    $self->current_statement(Statement->new());
    push @{$self->insert_expression_here},
        $self->current_statement->primary_expression;
}
sub got_test_statement {
    my $self = shift;
    my $statement = $self->current_statement;
    $statement->{points} =
        [sort keys %{+{ map {($_, 1)} @{$statement->points} }}];
    push @{$self->document->tests->statements}, $statement;
    delete $self->{current_statement};
}
sub not_test_statement {
    my $self = shift;
    delete $self->{current_statement};
}

sub try_test_expression {x
    my $self = shift;
    push @{$self->current_expression},
        Expression->new();
}
sub got_test_expression {x
    my $self = shift;
    push @{$self->insert_expression_here->[-1]},
        pop @{$self->current_expression};
}
sub not_test_expression {x
    my $self = shift;
    pop @{$self->current_expression};
}

sub got_data_point {x
    my $self = shift;
    my $name = shift;
    push @{$self->current_statement->points}, $name;
    push @{$self->current_expression->[-1]->transforms},
        Transform->new(
            name => 'Point',
            args => [$name],
        );
}
sub got_transform_call {x
    my $self = shift;
    my $name = shift;
    my $args = [];
    push @{$self->current_expression->[-1]->transforms},
        Transform->new(
            name => $name,
            args => $args,
        );
}

sub got_assertion_operator {x
    my $self = shift;
    push @{$self->insert_expression_here},
        $self->current_statement->assertion_expression;
}

sub got_data_section {
    my $self = shift;
    $self->document->inline_data(shift);
}

1; #XXX
