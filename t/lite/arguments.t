use TestML;
use t::Bridge;

TestML::Lite->new(
    testml => 'testml/arguments.tml',
    bridge => 't::Bridge',
)->run;
