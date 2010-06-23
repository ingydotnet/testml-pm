use TestML -run;

__DATA__
%TestML: 1.0

Throw(*error).bogus().Catch() == *error;
*error.Throw().bogus().Catch() == *error;
Throw('My error message').Catch() == *error;

*empty == String("");
*empty == "";

"foo" == "foo";

=== Throw/Catch
--- error: My error message

=== Empty Point
--- empty


