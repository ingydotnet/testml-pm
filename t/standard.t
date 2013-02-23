use TestML;
use t::Bridge;

TestML->new(
    testml => 'testml/standard.tml',
    bridge => 't::Bridge',
)->run;
