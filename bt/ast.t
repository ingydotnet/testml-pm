# BEGIN { $Pegex::Parser::Debug = 1 }
use Test::More tests => 1;
use strict;

use Test::Differences;
# use Test::Differences; *is = \&eq_or_diff;

use TestML::Compiler;
use TestML::Grammar;
use YAML::XS;
use XXX;
use IO::All;

# for my $file (<t/testml/*.tml>) {
#     test($file);
# }

# test('t/testml/arguments.tml');
test('t/testml/basic.tml');

sub test {
    my $file = shift;
    (my $filename = $file) =~ s!.*/!!;
    my $input = io($file)->all;
    $input =~ s/^#.*//gm;
    $input =~ s/^\%.*//gm;

    my $grammar1 = TestML::Grammar->new(
        receiver => 'TestML::AST',
    );
    my $ast1 = $grammar1->parse($input);
    my $yaml1 = Dump($ast1);

    my $ast2 = YAML::XS::LoadFile("bt/ast/$filename");
    my $yaml2 = Dump($ast2);

    eq_or_diff $yaml1, $yaml2, $filename;
}
