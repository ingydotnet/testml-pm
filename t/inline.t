use TestML::Runner::TAP -run, -bridge => 'TestMLTestBridge';

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
