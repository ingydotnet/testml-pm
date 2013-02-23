use TestML;
use t::Bridge;

TestML->new(
    testml => 'testml/arguments.tml',
    bridge => 't::Bridge',
)->run;
