package TestMLTestBridge;
use strict;
use warnings;
use base 'TestML::BridgeBase';

sub testml_my_thing {
    my $text = shift;
    return join ' - ', split "\n", $text;
}

1;
