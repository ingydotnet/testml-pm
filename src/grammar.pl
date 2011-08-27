use Pegex::Compiler;

my $perl = Pegex::Compiler->compile_file(shift)->to_perl;
chomp($perl);

print <<"...";
package TestML::Grammar;
use base 'Pegex::Grammar';

sub build_tree {
    return +$perl;
}

1;
...
