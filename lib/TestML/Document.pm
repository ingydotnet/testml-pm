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

#-----------------------------------------------------------------------------
package TestML::Document::Tests;
use TestML::Base -base;

field 'statements' => [];

package TestML::Statement;
use TestML::Base -base;

field 'points' => [];
field 'primary_expression' => [];
field 'assertion_operator';
field 'assertion_expression' => [];

package TestML::Expression;
use TestML::Base -base;

field 'transforms' => [];

package TestML::Transform;
use TestML::Base -base;

field 'name';
field 'args' => [];

#-----------------------------------------------------------------------------
package TestML::Document::Data;
use TestML::Base -base;

field 'blocks' => [];

package TestML::Block;
use TestML::Base -base;

field 'label' => '';
field 'points' => {};

#-----------------------------------------------------------------------------
package TestML::Document::Builder;
use TestML::Base -base;

field 'document', -init => 'TestML::Document->new()';
field 'current_statement';
field 'insert_expression_here' => [];
field 'current_expression' => [];
field 'inline_data';

field 'current_block';
field 'blocks' => [];
field 'point_name';
field 'transform_name';
field 'arguments' => [];

##############################################################################
sub t {
    my $name = shift;
    for (@_) { eval "sub ${_}_$name { x }" }
}

my $c = 0;
sub x {
    (my $name = (caller(1))[3]) =~ s/.*:://;
    $c++;
    warn "$c>> $name\n";
}

# t qw(test_statement got not);
# t qw(ws got);
# t qw(data_block try got not);
# t qw(data_header try got not);

##############################################################################
sub got_document {
    my $self = shift;
    my $data_files = $self->document->meta->data->{Data};
    if (not @$data_files) {
        push @$data_files, '_';
    }
}

sub got_meta_testml_statement {
    my $self = shift;
    my $version = shift;
    $self->document->meta->data->{TestML} = $version;
}

sub got_meta_statement {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    if (ref($self->document->meta->data->{$key}) eq 'ARRAY') {
        push @{$self->document->meta->data->{$key}}, $value;
    }
    else {
        $self->document->meta->data->{$key} = $value;
    }
}

##############################################################################
sub try_test_statement {
    my $self = shift;
    $self->current_statement(TestML::Statement->new());
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

sub try_test_expression {
    my $self = shift;
    push @{$self->current_expression},
        TestML::Expression->new();
}
sub got_test_expression {
    my $self = shift;
    push @{$self->insert_expression_here->[-1]},
        pop @{$self->current_expression};
}
sub not_test_expression {
    my $self = shift;
    pop @{$self->current_expression};
}

sub got_data_point {
    my $self = shift;
    my $name = shift;
    push @{$self->current_statement->points}, $name;
    push @{$self->current_expression->[-1]->transforms},
        TestML::Transform->new(
            name => 'Point',
            args => [$name],
        );
}
sub try_transform_call {
    my $self = shift;
    $self->arguments([]);
}
sub got_single_quoted_string {
    my $self = shift;
    my $value = shift;
    push @{$self->arguments}, $value;
}
sub got_transform_name {
    my $self = shift;
    my $name = shift;
    $self->transform_name($name);
}
sub got_transform_call {
    my $self = shift;
    my $name = $self->transform_name;
    push @{$self->current_expression->[-1]->transforms},
        TestML::Transform->new(
            name => $name,
            args => $self->arguments,
        );
}

sub got_assertion_operator {
    my $self = shift;
    push @{$self->insert_expression_here},
        $self->current_statement->assertion_expression;
}

sub got_data_section {
    my $self = shift;
    $self->inline_data(shift);
}

###############################################################################

sub try_data_block {
    my $self = shift;
    $self->current_block(TestML::Block->new());
}

sub got_data_block {
    my $self = shift;
    push @{$self->blocks}, $self->current_block;
}

sub got_block_label {
    my $self = shift;
    $self->current_block->label(shift);
}

sub got_user_point_name {
    my $self = shift;
    $self->point_name(shift);
}

sub got_point_lines {
    my $self = shift;
    $self->current_block->points->{$self->point_name} = shift;
}

sub got_point_phrase {
    my $self = shift;
    $self->current_block->points->{$self->point_name} = shift;
}

1; #XXX
