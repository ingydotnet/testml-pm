use Pegex::Compiler;

my $perl = Pegex::Compiler->compile(shift)->to_perl;
chomp($perl);
$perl =~ s/^/  /gm;

print <<"...";
package TestML::Grammar;
use TestML::Mo;
extends 'Pegex::Grammar';

sub tree_ {
$perl
}
...
