use TestML::Runner::TAP;

TestML::Runner::TAP->new(
    document => 't/testml/basic.tml',
    bridge => 'TestMLTestBridge',
)->run();
