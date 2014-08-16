use strict;
use lib -e 't' ? 't' : 'test';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/function.tml',
    bridge => 'TestMLBridge',
)->run;
