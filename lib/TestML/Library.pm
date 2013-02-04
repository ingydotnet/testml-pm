use strict; use warnings;
package TestML::Library;

use Exporter 'import';

our @EXPORT = qw( str num bool list );

sub str { TestML::Str->new(value => $_[0]) }
sub num { TestML::Num->new(value => $_[0]) }
sub bool { TestML::Bool->new(value => $_[0]) }
sub list { TestML::List->new(value => $_[0]) }

1;
