use TestML;
use t::Bridge;

TestML::Lite->new(
    testml => 'testml/semicolons.tml',
    bridge => 't::Bridge',
)->run;
