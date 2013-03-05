use TestML;

TestML->new(
    testml => '../testml/exceptions.tml',
    bridge => 't::Bridge',
    compiler => 'TestML::Compiler::Lite',
)->run;
