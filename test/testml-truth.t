use strict;
use File::Basename;
use lib dirname(__FILE__);
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/truth.tml',
    bridge => 'TestMLBridge',
)->run;
