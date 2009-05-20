use YAML::XS;
use Data::Dumper;

$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 1;

my $hash = Data::Dumper::Dumper YAML::XS::LoadFile(shift);
chomp($hash);

print <<"...";
package TestML::Parser::Grammar;
use strict;
use warnings;
sub grammar {
    return +$hash;
}

1;
...
