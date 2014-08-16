use strict;
use lib -e 't' ? 't' : 'test';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/semicolons2.tml',
    bridge => 'TestMLBridge',
)->run;
