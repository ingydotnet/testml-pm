package TestML::Runner;
use strict;
use warnings;
# use TestML::Parser;
use XXX;

sub import {
    my $pkg = shift;
    $pkg->run;
}

sub run {
    my $parser = TestML::Parser->new();
    my $test_file_name = (caller(1))[1];
    my $tesml_file_name =~ s/\.t$/.tml/;

    my $$parser->open();
    my $test_object = 
}

1;
