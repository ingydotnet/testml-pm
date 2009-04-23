use TestML::Runner;

TestML::Runner->new(
    testml => 't/testml/basic.tml',
    bridge => 'TestMLTestBridge',
)->run();
