package TestML::Runner::TAP;
use TestML::Runtime::TAP -base;

no warnings;
use Test::Builder;

$main::TODO;
# XXX Deprecation 2010-08-23
Test::Builder->new->diag(
    "\n\n*** NOTE *** TestML::Runner::TAP changed to TestML::Runtime::TAP\n"
) unless $TestML::Runner::TAP::DEPRECATED;

1;
