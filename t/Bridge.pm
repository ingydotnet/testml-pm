package t::Bridge;
use strict;
use warnings;

sub my_lower {
    my $context = shift;
    return lc($context->value);
}

sub my_upper {
    my $context = shift;
    return uc($context->value);
}

sub combine {
    return join ' ', map $_->value, @_;
}

sub parse_testml {
    my $context = shift;
    TestML::Parser->parse($context->value);
}

sub msg {
    my $context = shift;
    return $context->value;
}

1;
