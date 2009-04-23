package TestML;
use strict;
use warnings;
use 5.006001;

$TestML::VERSION = '0.01';

1;

=head1 NAME

TestML - Generic Software Testing Meta Language

=head1 SYNOPSIS

    testml: 0.0.1
    title: Tests for AcmeEncode
    tests: 3

    text.apply_rot13  == rot13
    text.apply_md5    == md5


    === Encode some poetry
    --- text
    There once was a fellow named Ingy,
    Combining languages twas his Thingy.
    --- rot13
    Gurer bapr jnf n sryybj anzrq Vatl,
    Pbzovavat ynathntrf gjnf uvf Guvatl.
    --- md5: 7a1538ff9fc8edf8ea55d02d0b0658be

    === Encode a password
    --- text: soopersekrit
    --- md5: 64002c26dcc62c1d6d0f1cb908de1435

This TestML specification defines 2 tests, and defines 2 data blocks.
The first block has 3 data entries, but the second one has only 2.
Therefore the rot13 test applies only to the first block, while the the
md5 test applies to both. This results in a total of 3 tests, which is
specified in the test.

The apply_* functions are defined in a bridge class that is specified
outside this test.

=head1 DESCRIPTION

TestML is a generic, programming language agnostic, meta language for
writing unit tests. The idea is that you can use the same test files in
multiple implementations of a given programming idea. Then you can be
more certain that your application written in, say, Python matches your
Perl implementation.

In a nutshell you write a bunch of data tests that have inputs and
expected results. Using a simple syntax, you specify what functions the
data must pass through to produce the expected results. You use a bridge
class to write the functions that pass the data through your
application.

This is an early release. More doc coming soon.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2009. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
