package TestML::Library;
use TestML::Base;

sub runtime {
    return $TestML::Runtime::singleton;
}

1;
