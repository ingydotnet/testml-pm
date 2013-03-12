use lib 't/lib';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/external.tml',
    bridge => 'TestMLBridge',
)->run;
