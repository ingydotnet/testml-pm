use File::Basename;
use lib dirname(__FILE__);
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/standard.tml',
    bridge => 'TestMLBridge',
)->run;
