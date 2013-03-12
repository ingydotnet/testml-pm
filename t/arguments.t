use lib 't/lib';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/arguments.tml',
    bridge => 'TestMLBridge',
)->run;
