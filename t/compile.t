# BEGIN { $Pegex::Parser::Debug = 1 }
use Test::Differences; *is = \&eq_or_diff;
use Test::More;
use strict;

BEGIN {
    if (not eval "require YAML::XS") {
        plan skip_all => "requires YAML::XS";
    }
    plan tests => 14;
}

use TestML::Compiler;
use TestML::Compiler::Lite;
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
test('t/testml/truth.tml');
test('t/testml/types.tml');

test('t/testml/arguments.tml', 'TestML::Compiler::Lite');
test('t/testml/basic.tml', 'TestML::Compiler::Lite');
test('t/testml/exceptions.tml', 'TestML::Compiler::Lite');

sub test {
    my ($file, $compiler) = @_;
    $compiler ||= 'TestML::Compiler';
    (my $filename = $file) =~ s!(.*)/!!;
    my $runtime = TestML::Runtime->new(base => $1);
    my $testml = $runtime->read_testml_file($filename);
    my $ast1 = $compiler->new(
        runtime => $runtime,
    )->compile($testml);
    my $yaml1 = Dump($ast1);

    # snapshot:
#     use IO::All;
#     $yaml1 > io("t/ast/$filename");

    my $ast2 = YAML::XS::LoadFile("t/ast/$filename");
    my $yaml2 = Dump($ast2);

    is $yaml1, $yaml2, $filename;
}
