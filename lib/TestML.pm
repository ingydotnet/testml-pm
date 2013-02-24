##
# name:      TestML
# author:    Ingy döt Net <ingy@cpan.org>
# abstract:  A Generic Software Testing Meta Language
# license:   perl
# copyright: 2009-2013
# see:
# - http://www.testml.org/
# - irc://irc.freenode.net#testml

use 5.006001;
use strict;
use warnings;

my $requires = "
use Pegex 0.21 ();
";

package TestML;
use TestML::Mo;

has testml => ( default => sub {''} );
has bridge => ( default => sub {'main'} );
has runtime => ( default => sub {'TestML::Runtime::TAP'} );
has compiler => ( default => sub {'TestML::Compiler'} );
has skip_all => ();
has required => ( default => sub {[]} );

our $VERSION = '0.30';

sub run {
    my ($self) = @_;
    my $runtime = $self->runtime;

    my $testml = $self->testml || \*main::DATA;
    my $base = ($0 =~ m!(.*)/! ? $1 : ".");   # Base directory
    if (not ref $testml and $testml !~ /\n/) {
        $testml =~ s/(.*)\/(.*)/$2/ or die;
        ($base, $testml) = ("$base/$1", $2);
    }
    $testml = (not ref($testml) and $testml =~ /\n/)
        ? $testml
        : $self->slurp($testml, $base);

    if (not ref $runtime) {
        eval "require $runtime";
        $runtime = $self->runtime->new(
            testml => $testml,
            bridge => $self->bridge,
            compiler => $self->compiler,
            base => $base,
        );
    }
    if (my $message = $self->skip_all) {
        $runtime->skip_all($message);
    }
    elsif (@{$self->required}) {
        die "not supported";
    }
    else {
        $runtime->run;
    }
}

sub slurp {
    my ($self, $file, $base) = @_;
    $base ||= '.';
    my $fh;
    if (ref($file)) {
        $fh = $file;
    }
    else {
        my $path = join '/', $base, $file;
        open $fh, $path
            or die "Can't open '$path' for input: $!";
    }
    local $/;
    return <$fh>;
}

package TestML::Lite;
use TestML::Mo;
extends 'TestML';

has compiler => ( default => sub {'TestML::Lite::Compiler'} );

1;

=head1 SYNOPSIS

    # file t/testml/encode.tml
    %TestML 1.0

    Title = 'Tests for AcmeEncode';
    Plan = 3;

    *text.apply_rot13 == *rot13;
    *text.apply_md5   == *md5;

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

    use TestML::Runtime::TAP;

    TestML::Runtime::TAP->new(
        testml => 'testml/encode.tml',
        bridge => 't::Bridge',
    )->run();

or more simply:

    use TestML -run,
        -testml => 'testml/encode.tml',
        -bridge => 't::Bridge';

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
