use YAML::XS;
use Data::Dumper;

$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

my $hash = YAML::XS::LoadFile(shift);
precompile($hash);
my $perl = Data::Dumper::Dumper($hash);
chomp($perl);

print <<"...";
package TestML::Parser::Grammar;
use base 'TestML::Parser::Pegex';
use strict;
use warnings;

our \$grammar = +$perl;

sub grammar {
    return \$grammar;
}

1;
...

sub precompile {
    my $node = shift;
    if (ref($node) eq 'HASH') {
        if (exists $node->{'+re'}) {
            my $re = $node->{'+re'};
            $node->{'+re'} = qr/\G$re/;
        }
        else {
            precompile($node->{$_}) for keys %$node;
        }
    }
    elsif (ref($node) eq 'ARRAY') {
        precompile($_) for @$node;
    }
}
