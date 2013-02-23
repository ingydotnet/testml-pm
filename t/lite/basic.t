use TestML;
use t::Bridge;

TestML::Lite->new(
    testml => '../testml/basic.tml',
    bridge => 't::Bridge',
)->run;
