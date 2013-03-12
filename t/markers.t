use lib 't/lib';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/markers.tml',
    bridge => 'TestMLBridge',
)->run;
