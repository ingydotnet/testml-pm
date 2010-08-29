use TestML -run,
    -bridge => 't::Bridge';

__DATA__

%TestML 1.0
%Data external2.tml
%Data external1.tml

Plan = 4;

*foo == *bar;
