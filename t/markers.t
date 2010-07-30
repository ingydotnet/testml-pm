use TestML::Runner::TAP;

TestML::Runner::TAP->new(
    document => 'testml/markers.tml',
    bridge => 't::Bridge',
)->run();
