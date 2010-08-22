use TestML::Runner::TAP;

TestML::Runner::TAP->new(
    testml => 'testml/basic.tml',
    bridge => 't::Bridge',
)->run();
