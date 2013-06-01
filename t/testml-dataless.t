use lib 't';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/dataless.tml',
    bridge => 'TestMLBridge',
)->run;
