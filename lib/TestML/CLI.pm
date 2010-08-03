package TestML::CLI;
use strict;
use warnings;
use TestML::Base -base;

use Getopt::Long;

has 'testml' => 't/testml/';
has 'config_dir' => 't/';

sub run {
    my $self = shift;

    GetOptions(
        "help" => \$self->{help},
        "testml=s" => \$self->{testml},
        "config-dir=s" => \$self->{config_dir},
         
    ) or die $self->usage;

}
