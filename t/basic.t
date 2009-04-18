use TestML::Runner;

TestML::Runner->new(
    fixture_class => 'TestML::Fixture',
    testml_file => 'testml/tests/basic.tml',
)->run();
