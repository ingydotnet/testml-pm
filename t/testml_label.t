use lib 't';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/label.tml',
    bridge => 'TestMLBridge',
)->run;
