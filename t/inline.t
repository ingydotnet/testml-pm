use TestML::Runner::TAP;

TestML::Runner::TAP->new(
    document => \ *DATA,
    bridge => 'TestMLTestBridge',
)->run();

__DATA__

%TestML: 1.0
%Title: Ingy's Test
%Plan: 11

foo == bar;

# bar
#     .EQ(
#     foo
# );

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
