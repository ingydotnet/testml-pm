# BEGIN { $Pegex::Parser::Debug = 1 }
# use Test::Differences; *is = \&eq_or_diff;
use Test::More;
use Test::Diff;
use strict;

BEGIN {
    if (not eval "require YAML::XS") {
        plan skip_all => "requires YAML::XS";
    }
    plan tests => 16;
}

use TestML::Runtime;
use TestML::Compiler::Pegex;
use TestML::Compiler::Lite;
use YAML::XS;

test('t/testml/arguments.tml', 'TestML::Compiler::Pegex');
test('t/testml/assertions.tml', 'TestML::Compiler::Pegex');
test('t/testml/basic.tml', 'TestML::Compiler::Pegex');
test('t/testml/dataless.tml', 'TestML::Compiler::Pegex');
test('t/testml/exceptions.tml', 'TestML::Compiler::Pegex');
test('t/testml/external.tml', 'TestML::Compiler::Pegex');
test('t/testml/function.tml', 'TestML::Compiler::Pegex');
test('t/testml/label.tml', 'TestML::Compiler::Pegex');
test('t/testml/markers.tml', 'TestML::Compiler::Pegex');
test('t/testml/semicolons.tml', 'TestML::Compiler::Pegex');
test('t/testml/truth.tml', 'TestML::Compiler::Pegex');
test('t/testml/types.tml', 'TestML::Compiler::Pegex');

test('t/testml/arguments.tml', 'TestML::Compiler::Lite');
test('t/testml/basic.tml', 'TestML::Compiler::Lite');
test('t/testml/exceptions.tml', 'TestML::Compiler::Lite');
test('t/testml/semicolons.tml', 'TestML::Compiler::Lite');

sub test {
    my ($file, $compiler) = @_;
    (my $filename = $file) =~ s!(.*)/!!;
    my $runtime = TestML::Runtime->new(base => $1);
    my $testml = $runtime->read_testml_file($filename);
    my $ast1 = $compiler->new->compile($testml);
    my $yaml1 = Dump($ast1);

    my $ast2 = YAML::XS::LoadFile("t/ast/$filename");
    my $yaml2 = Dump($ast2);

    is $yaml1, $yaml2, "$filename - $compiler";
}
