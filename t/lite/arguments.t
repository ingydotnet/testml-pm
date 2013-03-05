use TestML;

TestML->new(
    testml => '../testml/arguments.tml',
    bridge => 't::Bridge',
    compiler => 'TestML::Compiler::Lite',
)->run;
