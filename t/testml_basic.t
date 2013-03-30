use lib 't';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/basic.tml',
    bridge => 'TestMLBridge',
)->run;
