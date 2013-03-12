use lib 't/lib';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/label.tml',
    bridge => 'TestMLBridge',
)->run;
