use TestML;
use t::Bridge;

TestML::Lite->new(
    testml => '../testml/exceptions.tml',
    bridge => 't::Bridge',
)->run;
