use TestML::Runner;

TestML::Runner->new(
    class => 'TestML::Fixture',
    testml => 'testml/tests/basic.tml',
)->run();
