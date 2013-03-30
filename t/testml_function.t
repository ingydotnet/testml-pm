use lib 't';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/function.tml',
    bridge => 'TestMLBridge',
)->run;
