use lib 't';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/arguments.tml',
    bridge => 'TestMLBridge',
)->run;
