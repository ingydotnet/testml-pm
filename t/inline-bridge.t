use TestML -run, -bridge => 'main';

sub upper {
    my $self = shift;
    return uc($self->value);
}
__DATA__

%TestML: 1.0

*foo.upper() == *bar;

=== Foo for thought
--- foo: o hai
--- bar: O HAI

=== Bar the door
--- foo
o
Hai
--- bar
O
HAI

