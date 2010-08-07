use lib "$ENV{HOME}/src/parse-pegex-pm/lib";
use Parse::Pegex::Compiler;

open IN, shift or die;
my $testml = do {local $/; <IN>};
my $perl = Parse::Pegex::Compiler->new()->compile($testml)->to_perl;
chomp($perl);

print <<"...";
package TestML::Parser::Grammar;
use base 'Parse::Pegex';
use strict;
use warnings;

our \$grammar = +$perl;

sub grammar {
    return \$grammar;
}

1;
...

