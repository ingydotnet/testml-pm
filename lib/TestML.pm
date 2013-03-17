use 5.006001; use strict; use warnings;

package TestML;
use TestML::Base;

our $VERSION = '0.30';

has runtime => ();
has compiler => ();
has bridge => ();
has library => ();
has testml => sub {
    local $/;
    no warnings 'once';
    return <main::DATA>;
};

sub run {
    my ($self) = @_;
    $self->set_default_classes;
    $self->runtime->new(
        compiler => $self->compiler,
        bridge => $self->bridge,
        library => $self->library,
        testml => $self->testml,
    )->run;
}

sub set_default_classes {
    my ($self) = @_;
    if (not $self->runtime) {
        require TestML::Runtime::TAP;
        $self->{runtime} = 'TestML::Runtime::TAP';
    }
    if (not $self->compiler) {
        require TestML::Compiler::Pegex;
        $self->{compiler} = 'TestML::Compiler::Pegex';
    }
    if (not $self->bridge) {
        $self->{bridge} = 'main';
        if (not @main::ISA) {
            require TestML::Bridge;
            @main::ISA = ('TestML::Bridge');
        }
    }
    if (not $self->library) {
        require TestML::Library::Standard;
        require TestML::Library::Debug;
        $self->{library} = [
            'TestML::Library::Standard',
            'TestML::Library::Debug',
        ];
    }
}

1;
