use lib 't/lib';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/basic.tml',
    bridge => 'TestMLBridge',
)->run;
