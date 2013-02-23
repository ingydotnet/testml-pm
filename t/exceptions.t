use TestML;
use t::Bridge;

TestML->new(
    testml => 'testml/exceptions.tml',
    bridge => 't::Bridge',
)->run;
