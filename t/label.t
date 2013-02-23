use TestML;
use t::Bridge;

TestML->new(
    testml => 'testml/label.tml',
    bridge => 't::Bridge',
)->run;
