use TestML;
use t::Bridge;

TestML->new(
    testml => 'testml/truth.tml',
    bridge => 't::Bridge',
)->run;
