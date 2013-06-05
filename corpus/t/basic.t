#! perl
use strict;
use warnings;

use Test::More;

ok -e for map { my $file = $_; $file =~ s{::}{/}; "inc/$file.pm" } qw{DateTime DateTime::Locale Params::Validate};
ok !-e for map { my $file = $_; $file =~ s{::}{/}; "inc/$file.pm" } qw{strict warnings Scalar::Util};

done_testing;

