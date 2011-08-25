# XXX This code currently depends on too much bootstrapping stuffs.

use lib "../../pegex-pm/lib";
# use Pegex::Compiler;
use Pegex::Compiler::Bootstrap;

open IN, shift or die;
my $testml = do {local $/; <IN>};
# my $pegex = Pegex::Compiler->new;
my $pegex = Pegex::Compiler::Bootstrap->new;
$pegex->compile($testml);
my $perl = $pegex->to_perl;
chomp($perl);

print <<"...";
package TestML::Grammar;
use base 'Pegex::Grammar';
# use base 'Pegex::Grammar::Bootstrap';

sub build_tree {
    return +$perl;
}

1;
...

