use TestML -run,
    -bridge => 't::Bridge';

__DATA__

%TestML: 1.0
%Plan: 4
%Data: external2.tml
%Data: external1.tml

*foo == *bar;
