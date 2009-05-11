package TestMLTestBridge;
use strict;
use warnings;
use base 'TestML::Bridge';

sub testml_my_thing {
    my $self = shift;
    return join ' - ', split "\n", $self->value;
}

1;
