# BEGIN { $Pegex::Parser::Debug = 1 }
use Test::More tests => 1;
use strict;

use Test::Differences;
# use Test::Differences; *is = \&eq_or_diff;

use TestML::Compiler;
use YAML::XS;
use XXX;

# test('t/testml/arguments.tml');
test('t/testml/basic.tml');

sub test {
    my $file = shift;
    (my $filename = $file) =~ s!.*/!!;
    my $ast1 = TestML::Compiler->new->compile($file);
    my $yaml1 = Dump($ast1);

    my $ast2 = YAML::XS::LoadFile("bt/ast/$filename");
    my $yaml2 = Dump($ast2);

    eq_or_diff $yaml1, $yaml2, $filename;
}
