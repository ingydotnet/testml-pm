package t::Bridge;
use strict;
use warnings;

sub my_thing {
    my $this = shift;
    return join ' - ', split "\n", $this->value;
}

sub combine {
    return join ' ', map $_->value, @_;
}

sub parse_testml {
    my $this = shift;
    TestML::Parser->parse($this->value);
}

sub msg {
    my $this = shift;
    return $this->value;
}

1;
