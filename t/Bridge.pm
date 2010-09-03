package t::Bridge;
use TestML;

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

sub compile_testml {
    my $context = shift;
    require TestML::Compiler;
    TestML::Compiler->new->compile($context->value);
}

sub msg {
    my $context = shift;
    return $context->value;
}

1;
