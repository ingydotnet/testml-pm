use strict; use warnings;

use TestML::Runtime;

package TestML::Util;

use Exporter 'import';
our @EXPORT = qw( list str num bool none native );

sub list { TestML::List->new(value => $_[0]) }
sub str { TestML::Str->new(value => $_[0]) }
sub num { TestML::Num->new(value => $_[0]) }
sub bool { TestML::Bool->new(value => $_[0]) }
sub none { TestML::None->new(value => $_[0]) }
sub native { TestML::Native->new(value => $_[0]) }

1;
