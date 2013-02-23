use TestML;
use t::Bridge;

TestML->new(
    testml => 'testml/types.tml',
    bridge => 't::Bridge',
)->run;
