use lib 't';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/standard.tml',
    bridge => 'TestMLBridge',
)->run;
