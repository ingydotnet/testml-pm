package TestML::Bridge;
use TestML::Mo;

sub runtime {
    return $TestML::Runtime::singleton;
}

1;
