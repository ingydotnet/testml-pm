use lib 't/lib';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/standard.tml',
    bridge => 'TestMLBridge',
)->run;
