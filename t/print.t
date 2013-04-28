use strict;
use Test::More tests => 1;
use Capture::Tiny ':all';

my ($out, $err) = capture {
    system $^X, '-Ilib', 't/script/hello.pl';
};
die "Run failed:\nstdout: $out\nstderr:$err\n" unless 0 == $?;

ok $out =~ /^Goodbye, World!\n/m;
