package TestML::Bridge;

use TestML::Base;

use TestML::Util 'runtime';

sub Block {
    @_ == 1 or
        die 'TestML::Bridge::Block requires 0 arguments';
    runtime->function->getvar('Block');
}

sub Point {
    @_ == 2 or
        die 'TestML::Bridge::Point requires 1 argument';
    runtime->function->getvar('Block')->{points}->{$_[1]};
}

sub Var {
    shift;
    scalar(@_) =~ /^[12]$/ or
        die 'TestML::Bridge::Var requires 1 or 2 arguments';
    @_ == 1
      ? runtime->function->getvar(@_)
      : runtime->function->setvar(@_);
}

sub ONLY {
    @_ == 1 or
        die 'TestML::Bridge::ONLY requires 0 arguments';
    runtime->function->getvar('Block')->{points}->{ONLY} ? 1 : 0;
}

sub LAST {
    @_ == 1 or
        die 'TestML::Bridge::LAST requires 0 arguments';
    runtime->function->getvar('Block')->{points}->{LAST} ? 1 : 0;
}

sub SKIP {
    @_ == 1 or
        die 'TestML::Bridge::SKIP requires 0 arguments';
    runtime->function->getvar('Block')->{points}->{SKIP} ? 1 : 0;
}

1;
