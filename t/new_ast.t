use Test::More tests => 1;

use Test::Differences;
# use Test::Differences; *is = \&eq_or_diff;

use TestML::Compiler;
use TestML::Grammar;
use TestML::Grammar2;
use YAML::XS;
use XXX;
use IO::All;
# BEGIN { $Pegex::Parser::Debug = 1 }

# for my $file (<t/testml/*.tml>) {
#     test($file);
#     last;
# }

test('t/testml/basic.tml');

sub test {
    my $file = shift;
    my $text = io($file)->all;
    my $DataMarker = "===";

    $text =~ s/^#.*//gm;
    $text =~ s/^\%.*//gm;

    my ($code, $data);
    if ((my $split = index($text, "\n$DataMarker")) >= 0) {
        $code = substr($text, 0, $split + 1);
        $data = substr($text, $split + 1);
    }

    my $grammar1 = TestML::Grammar2->new(
        receiver => 'TestML::AST',
    );
    my $ast1 = $grammar1->parse($code, 'code_section');
    my $yaml1 = Dump($ast1);

    my $grammar2 = TestML::Grammar->new(
        receiver => TestML::Receiver->new,
    );
    $grammar2->parse($code, 'code_section');
    my $ast2 = $grammar2->receiver->function;
    my $yaml2 = Dump($ast2);

    eq_or_diff $yaml1, $yaml2, $file;
}
