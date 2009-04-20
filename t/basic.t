use TestML::Runner;

TestML::Runner->new(
    fixture => 'TestML::Fixture',
    testml => 'testml/tests/basic.tml',
)->run();
