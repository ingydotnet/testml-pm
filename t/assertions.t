use TestML;
use t::Bridge;

TestML->new(
    testml => 'testml/assertions.tml',
    bridge => 't::Bridge',
)->run;
