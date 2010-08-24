use TestML::Runtime::TAP;

TestML::Runtime::TAP->new(
    testml => 'testml/basic.tml',
    bridge => 't::Bridge',
)->run();
