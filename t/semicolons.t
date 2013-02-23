use TestML;
use t::Bridge;

TestML->new(
    testml => 'testml/semicolons.tml',
    bridge => 't::Bridge',
)->run;
