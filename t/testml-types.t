use lib 't';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/types.tml',
    bridge => 'TestMLBridge',
)->run;
