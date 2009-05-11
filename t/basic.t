use TestML::Runner;

TestML::Runner->new(
    document => 't/testml/basic.tml',
    bridge => 'TestMLTestBridge',
)->run();
