BEGIN {
    no warnings 'once';
    $TestML::Runner::TAP::DEPRECATED = 1;
}

use TestML::Runner::TAP;

TestML::Runner::TAP->new(
    testml => \*DATA,
)->run;

__DATA__
%TestML 1.0

Plan = 1;

Label = 'TestML::Runner::TAP still works';

True.OK;
