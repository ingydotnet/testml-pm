use TestML;
use t::Bridge;

TestML->new(
    testml => 'testml/dataless.tml',
    bridge => 't::Bridge',
)->run;
