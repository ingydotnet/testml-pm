use TestML;
use t::Bridge;

TestML->new(
    testml => 'testml/function.tml',
    bridge => 't::Bridge',
)->run;
