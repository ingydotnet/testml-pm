use strict;
use lib -e 't' ? 't' : 'test';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/dataless.tml',
    bridge => 'TestMLBridge',
)->run;
