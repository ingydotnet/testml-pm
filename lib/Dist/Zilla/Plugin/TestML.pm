package Dist::Zilla::Plugin::TestML;
use Moose;

with qw/Dist::Zilla::Role::FileGatherer/;
with 'Dist::Zilla::Role::FileInjector';

use Carp;
use Dist::Zilla::File::InMemory;
use File::Slurp 'read_file';
use File::Spec::Functions qw(catfile);
use Module::Metadata;

sub _mod_to_filename {
    my $module = shift;
    return catfile( split / :: | ' /x, $module ) . '.pm';
}

sub gather_files {
    my ( $self, $arg ) = @_;
    my @mods = qw(
      Pegex::Grammar
      Pegex::Input
      Pegex::Parser
      Pegex::Tree
      Pegex::Receiver
      TestML
      TestML::Base
      TestML::AST
      TestML::Compiler
      TestML::Grammar
      TestML::Library::Debug
      TestML::Library::Standard
      TestML::Runtime
      TestML::Runtime::TAP
    );

    for my $mod (@mods) {

        my $fname = Module::Metadata->find_module_by_name($mod) or croak "Couldn't find module: $mod";
        my $content = read_file( $fname );
        my $file = Dist::Zilla::File::InMemory->new({
            name    => catfile('inc', _mod_to_filename($mod)),
            content => $content,
        });
        $self->add_file($file);
    }
    return;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

#ABSTRACT: explicitly include TestML into a distribution

__END__

=head1 SYNOPSIS

In dist.ini:

 [TestML]

=head1 DESCRIPTION

This module allows you to explicitly include TestML in C<inc/>.

The idea and part of the code were taken from L<Dist::Zilla::Plugin::ModuleIncluder>
