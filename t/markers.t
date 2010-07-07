use TestML::Runner::TAP;

TestML::Runner::TAP->new(
    document => 't/testml-tml/markers.tml',
    bridge => 't::Bridge',
)->run();
