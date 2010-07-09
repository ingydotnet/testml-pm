use TestML::Runner::TAP;

TestML::Runner::TAP->new(
    document => 'testml-tml/markers.tml',
    bridge => 't::Bridge',
)->run();
