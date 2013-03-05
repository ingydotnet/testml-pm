use TestML;
use t::Bridge;

TestML->new(
    bridge => 't::Bridge',
)->run;

__DATA__

%TestML 0.1.0

Title = "Ingy's Test";
Plan = 4;

*foo == *bar;
*bar == *foo;

=== Foo for thought
--- foo: O HAI
--- bar: O HAI

=== Bar the door
--- bar
O
HAI
--- foo
O
HAI
