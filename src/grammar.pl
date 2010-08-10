use lib "$ENV{HOME}/src/pegex-pm/lib";
use Pegex::Compiler;

open IN, shift or die;
my $testml = do {local $/; <IN>};
my $perl = Pegex::Compiler->compile($testml)->to_perl;
chomp($perl);

print <<"...";
package TestML::Parser::Grammar;
use base 'Pegex::Grammar';
use strict;
use warnings;

sub grammar_tree {
    return +$perl;
}

1;
...

