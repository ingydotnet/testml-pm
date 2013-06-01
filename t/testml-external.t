use lib 't';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/external.tml',
    bridge => 'TestMLBridge',
)->run;
