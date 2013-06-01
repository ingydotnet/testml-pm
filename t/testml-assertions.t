use lib 't';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/assertions.tml',
    bridge => 'TestMLBridge',
)->run;
