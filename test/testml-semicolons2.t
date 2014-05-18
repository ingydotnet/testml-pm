use strict;
use File::Basename;
use lib dirname(__FILE__);
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/semicolons2.tml',
    bridge => 'TestMLBridge',
)->run;
