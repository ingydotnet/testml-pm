use lib 't';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/semicolons.tml',
    bridge => 'TestMLBridge',
)->run;
