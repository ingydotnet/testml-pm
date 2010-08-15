package Module::Install::TestML;
use strict;
use warnings;

use Module::Install::Base;

use vars qw($VERSION @ISA);
BEGIN {
    $VERSION = '0.11';
    @ISA     = 'Module::Install::Base';
}

sub use_testml_tap {
    my $self = shift;

    $self->use_testml;
     
    $self->include('Test::More');
    $self->include('Test::Builder');
    $self->include('Test::Builder::Module');
    $self->requires('Filter::Util::Call');
}

sub use_testml {
    my $self = shift;

    $self->include('TestML');
    $self->include('TestML::Base');
    $self->include('TestML::Document');
    $self->include('TestML::Parser');
    $self->include('TestML::Parser::Grammar');
    $self->include('TestML::Runner');
    $self->include('TestML::Runner::TAP');
    $self->include('TestML::Standard');
    $self->include('Pegex::Grammar');
    $self->include('Pegex::Base');
}

1;

=encoding utf8

=head1 NAME

Module::Install::TestML - Module::Install Support for TestML

=head1 SYNOPSIS

    use inc::Module::Install;

    name     'Foo';
    all_from 'lib/Foo.pm';

    use_testml_tap;

    WriteAll;

=head1 DESCRIPTION

This module adds the C<use_testml_tap> directive to Module::Install.

Now you can get full TestML support for your module with no external
dependency on TestML.

Just add this line to your Makefile.PL:

    use_testml_tap;

That's it. Really. Now Test::Base is bundled into your module, so that
it is no longer any burden on the person installing your module.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2009, 2010. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
