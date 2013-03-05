use TestML;

TestML->new(
    testml => '../testml/semicolons.tml',
    bridge => 't::Bridge',
    compiler => 'TestML::Compiler::Lite',
)->run;
