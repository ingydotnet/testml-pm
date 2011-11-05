# BEGIN { $Pegex::Parser::Debug = 1 }
# use Test::Differences; *is = \&eq_or_diff;
use Test::More;
use strict;

BEGIN {
    if (not eval "require YAML::XS") {
        plan skip_all => "requires YAML::XS";
    }
    plan tests => 12;
}

use TestML::Compiler;
use YAML::XS;

test('t/testml/arguments.tml');
test('t/testml/assertions.tml');
test('t/testml/basic.tml');
test('t/testml/dataless.tml');
test('t/testml/exceptions.tml');
test('t/testml/external.tml');
test('t/testml/function.tml');
test('t/testml/label.tml');
test('t/testml/markers.tml');
test('t/testml/standard.tml');
test('t/testml/truth.tml');
test('t/testml/types.tml');

sub test {
    my $file = shift;
    (my $filename = $file) =~ s!.*/!!;
    my $ast1 = TestML::Compiler->new->compile($file);
    my $yaml1 = Dump($ast1);

    my $ast2 = YAML::XS::LoadFile("t/ast/$filename");
    my $yaml2 = Dump($ast2);

    is $yaml1, $yaml2, $filename;
}
