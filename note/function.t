use TestML -run;
__DATA__
%TestML: 1.0
%Plan: 2

fun1(val, label) {
    Label = label;
    val.OK;
}

fun1(True, 'Functional call style');
True.fun1('Method call style');

