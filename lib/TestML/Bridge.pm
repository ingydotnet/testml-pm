package TestML::Bridge;
use TestML::Base;

sub runtime {
    return $TestML::Runtime::singleton;
}

1;
