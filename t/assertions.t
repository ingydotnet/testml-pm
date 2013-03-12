use lib 't/lib';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/assertions.tml',
    bridge => 'TestMLBridge',
)->run;
