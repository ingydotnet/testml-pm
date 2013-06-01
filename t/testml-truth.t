use lib 't';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/truth.tml',
    bridge => 'TestMLBridge',
)->run;
