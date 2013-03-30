use lib 't';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/exceptions.tml',
    bridge => 'TestMLBridge',
)->run;
