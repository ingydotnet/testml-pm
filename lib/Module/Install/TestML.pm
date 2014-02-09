# XXX This module should be deprecated or at least moved to a separate dist.
package Module::Install::TestML;
use strict;
use warnings;

use Module::Install::Base;

use vars qw($VERSION @ISA);
BEGIN {
    @ISA     = 'Module::Install::Base';
}

sub use_testml_tap {
    my ($self) = @_;

    $self->use_testml;

    $self->include('Test::More');
    $self->include('Test::Builder');
    $self->include('Test::Builder::Module');
    $self->requires('Filter::Util::Call');
}

sub use_testml {
    my ($self) = @_;

    $self->include('Pegex::Grammar');
    $self->include('Pegex::Base');
    $self->include('Pegex::Input');
    $self->include('Pegex::Parser');
    $self->include('Pegex::Tree');
    $self->include('Pegex::Receiver');

    $self->include('TestML');
    $self->include('TestML::Base');
    $self->include('TestML::Bridge');
    $self->include('TestML::Compiler');
    $self->include('TestML::Compiler::Pegex');
    $self->include('TestML::Compiler::Pegex::AST');
    $self->include('TestML::Compiler::Pegex::Grammar');
    $self->include('TestML::Library::Debug');
    $self->include('TestML::Library::Standard');
    $self->include('TestML::Runtime');
    $self->include('TestML::Runtime::TAP');
    $self->include('TestML::Util');
}

sub testml_setup {
    my ($self, $config) = @_;
    return unless $self->is_admin;
    die "setup_config requires a yaml file argument"
        unless $config;
    print "testml_setup\n";
    require TestML::Setup;
    TestML::Setup->new->setup($config);
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

Copyright (c) 2009-2014. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
