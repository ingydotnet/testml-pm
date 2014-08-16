use strict;
use lib -e 't' ? 't' : 'test';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/semicolons.tml',
    bridge => 'TestMLBridge',
)->run;
