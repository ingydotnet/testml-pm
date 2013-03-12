##
# name:      TestML
# author:    Ingy döt Net <ingy@cpan.org>
# abstract:  A Generic Software Testing Meta Language
# license:   perl
# copyright: 2009-2013
# see:
# - http://www.testml.org/
# - irc://irc.freenode.net#testml

# TODO Maybe switch to 5.8.5 requirement.
use 5.006001;
use strict; use warnings;
package TestML;
use TestML::Base;

# TODO Need to switch VERSION to semvar (x.x.x).
our $VERSION = '0.30';

# Accessors for TestML objects:
has runtime => 'TestML::Runtime::TAP';
has compiler => 'TestML::Compiler::Pegex';
has bridge => 'main';
has library => [
    'TestML::Library::Standard',
    'TestML::Library::Debug',
];
has testml => sub {
    local $/;
    no warnings 'once';
    return <main::DATA>;
};

# This is the method to run a TestML test program. `runtime` will be a runtime
# class. Load the library as a nicety, then construct a Runtime object with the
# user supplied data, and call the run method.
sub run {
    my ($self) = @_;
    my $runtime = $self->runtime;
    eval "require $runtime; 1" or die $@;
    $self->runtime->new(
        compiler => $self->compiler,
        bridge => $self->bridge,
        library => $self->library,
        testml => $self->testml,
    )->run;
}

1;

# TODO Move this doc to a TestML overview, and then use StarDoc inline doc for
# the module.

=head1 SYNOPSIS

    # file t/testml/encode.tml
    %TestML 0.1.0

    Title = 'Tests for AcmeEncode'
    Plan = 3

    *text.apply_rot13 == *rot13
    *text.apply_md5   == *md5

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

This TestML document defines 2 assertions, and defines 2 data blocks.  The
first block has 3 data points, but the second one has only 2.  Therefore the
rot13 assertion applies only to the first block, while the the md5 assertion
applies to both. This results in a total of 3 tests, which is specified in the
meta Plan statement in the document.

To run this test you would have a normal test file that looks like this:

    use TestML;
    use t::Bridge;

    TestML->new(
        testml => 'testml/encode.tml',
        bridge => 't::Bridge',
    )->run;

The apply_* functions are defined in the bridge class that is specified outside
this test (t/Bridge.pm).

=head1 DESCRIPTION

TestML is a generic, programming language agnostic, meta language for writing
unit tests. The idea is that you can use the same test files in multiple
implementations of a given programming idea. Then you can be more certain that
your application written in, say, Python matches your Perl implementation.

In a nutshell you write a bunch of data tests that have inputs and expected
results. Using a simple syntax, you specify what functions the data must pass
through to produce the expected results. You use a bridge class to write the
data functions that pass the data through your application.

In Perl 5, TestML is the evolution of the L<Test::Base> module. It has a
superset of Test:Base's goals. The data markup syntax is currently exactly the
same as Test::Base.
