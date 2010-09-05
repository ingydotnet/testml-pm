use Test::More tests => 21;

use TestML::Compiler;

my $testml = '
# A comment
%TestML 1.0

Plan = 2;
Title = "O HAI TEST";

*input.uppercase() == *output;

=== Test mixed case string
--- input: I Like Pie
--- output: I LIKE PIE

=== Test lower case string
--- input: i love lucy
--- output: I LOVE LUCY
';

my $func = TestML::Compiler->new->compile($testml);
ok $func, 'TestML string matches against TestML grammar';
is $func->namespace->{TestML}, '1.0', 'Version parses';
is $func->statements->[0]->expression->units->[0]->args->[1]->units->[0]->value, '2', 'Plan parses';
is $func->statements->[1]->expression->units->[0]->args->[1]->units->[0]->value, 'O HAI TEST', 'Title parses';

is scalar(@{$func->statements}), 3, 'Three test statements';
my $statement = $func->statements->[2];
is join('-', @{$statement->points}), 'input-output',
    'Point list is correct';

is scalar(@{$statement->expression->units}), 2, 'Expression has two units';
my $expression = $statement->expression;
is $expression->units->[0]->name, 'Point', 'First sub is a Point';
is $expression->units->[0]->args->[0], 'input', 'Point name is "input"';
is $expression->units->[1]->name, 'uppercase', 'Second sub is "uppercase"';

is $statement->assertion->name, 'EQ', 'Assertion is "EQ"';

$expression = $statement->assertion->expression;
is scalar(@{$expression->units}), 1, 'Right side has one part';
is $expression->units->[0]->name, 'Point', 'First sub is a Point';
is $expression->units->[0]->args->[0], 'output', 'Point name is "output"';

is scalar(@{$func->data}), 2, 'Two data blocks';
my ($block1, $block2) = @{$func->data};
is $block1->label, 'Test mixed case string', 'Block 1 label ok';
is $block1->points->{input}, 'I Like Pie', 'Block 1, input point';
is $block1->points->{output}, 'I LIKE PIE', 'Block 1, output point';
is $block2->label, 'Test lower case string', 'Block 2 label ok';
is $block2->points->{input}, 'i love lucy', 'Block 2, input point';
is $block2->points->{output}, 'I LOVE LUCY', 'Block 2, output point';
