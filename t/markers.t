use TestML::Runner::TAP;

TestML::Runner::TAP->new(
    document => 't/testml/markers.tml',
    bridge => 'TestMLTestBridge',
)->run();
