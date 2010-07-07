use TestML::Runner::TAP;

TestML::Runner::TAP->new(
    document => 't/testml-tml/basic.tml',
    bridge => 't::Bridge',
)->run();
