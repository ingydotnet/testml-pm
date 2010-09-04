use lib "../../pegex-pm/lib";
# use Pegex::Compiler;
use Pegex::Compiler::Bootstrap;

open IN, shift or die;
my $testml = do {local $/; <IN>};
# my $perl = Pegex::Compiler->compile($testml)->combinate->to_perl;
my $perl = Pegex::Compiler::Bootstrap->compile($testml)->combinate->to_perl; # XXX
chomp($perl);

print <<"...";
package TestML::Grammar;
use base 'Pegex::Grammar';

sub grammar_tree {
    return +$perl;
}

1;
...

