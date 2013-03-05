use TestML;

TestML->new(
    testml => '../testml/basic.tml',
    bridge => 't::Bridge',
    compiler => 'TestML::Compiler::Lite',
)->run;
