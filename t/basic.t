use TestML;
use t::Bridge;

TestML->new(
    testml => 'testml/basic.tml',
    bridge => 't::Bridge',
)->run;
