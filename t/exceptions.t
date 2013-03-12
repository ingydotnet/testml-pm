use lib 't/lib';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/exceptions.tml',
    bridge => 'TestMLBridge',
)->run;
