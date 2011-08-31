use Pegex::Compiler;

my $perl = Pegex::Compiler->compile_file(shift)->to_perl;
chomp($perl);

print <<"...";
package TestML::Grammar;
use base 'Pegex::Grammar';
use strict;

sub tree_ {
    return +$perl;
}

1;
...
