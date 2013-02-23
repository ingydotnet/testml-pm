use TestML;
use t::Bridge;

TestML->new(
    testml => 'testml/external.tml',
    bridge => 't::Bridge',
)->run;
