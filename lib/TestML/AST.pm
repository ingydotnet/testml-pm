package TestML::AST;

#-----------------------------------------------------------------------------
package TestML::Function;
use TestML::Base -base;

has 'outer';
has 'namespace' => {};
has 'statements' => [];
has 'data' => [];
has 'expression';
has 'block';

sub fetch {
    my $self = shift;
    my $name = shift;
    while ($self) {
        if (my $object = $self->namespace->{$name}) {
            return $object;
        }
        $self = $self->outer;
    }
    return;
}

#-----------------------------------------------------------------------------
package TestML::Statement;
use TestML::Base -base;

has 'expression', -init => 'TestML::Expression->new';
has 'assertion';
has 'points' => [];

#-----------------------------------------------------------------------------
package TestML::Expression;
use TestML::Base -base;

has 'transforms' => [];
has 'error';
has 'set_called';

#-----------------------------------------------------------------------------
package TestML::Assertion;
use TestML::Base -base;

has 'name';
has 'expression', -init => 'TestML::Expression->new';

#-----------------------------------------------------------------------------
package TestML::Transform;
use TestML::Base -base;

has 'name';
has 'args' => [];

#-----------------------------------------------------------------------------
package TestML::Block;
use TestML::Base -base;

has 'label' => '';
has 'points' => {};

#-----------------------------------------------------------------------------
package TestML::Object;
use TestML::Base -base;

our @EXPORT_BASE = qw(Str Num Bool List);

has 'type' => 'None';
has 'value';

sub runtime { return $TestML::Runtime::self }

sub Str     { TestML::Str->new(value => shift) }
sub Num     { TestML::Num->new(value => shift) }
sub Bool    { TestML::Bool->new(value => shift) }
sub List    { TestML::List->new(value => shift) }

use Carp;
sub str { my $t = $_[0]->type; confess "Cast from $t to Str is not supported" }
sub num { my $t = $_[0]->type; die "Cast from $t to Num is not supported" }
sub bool { my $t = $_[0]->type; die "Cast from $t to Bool is not supported" }
sub list { my $t = $_[0]->type; die "Cast from $t to List is not supported" }

#-----------------------------------------------------------------------------
package TestML::Str;
use TestML::Object -base;

has 'type' => 'Str';

sub str { shift }
sub num { $_[0]->value =~ /^-?\d+(?:\.\d+)$/ ? ($_[0]->value + 0) : 0 }
sub bool { TestML::Bool->new(value => length($_[0]->value) ? 1 : 0) }
sub list { List([split //, $_[0]->value]) }

#-----------------------------------------------------------------------------
package TestML::Num;
use TestML::Object -base;

has 'type' => 'Num';

sub str { TestML::Str->new($_[0]->value . "") }
sub num { shift }
sub bool { TestML::Bool->new(value => ($_[0]->value != 0)) }
sub list { my $list = []; $#{$list} = int($_[0]) -1; TestML::List->new($list) }

#-----------------------------------------------------------------------------
package TestML::Bool;
use TestML::Object -base;

has 'type' => 'Bool';

sub str { TestML::Str->new($_[0]->value ? "1" : "") }
sub num { TestML::Num->new($_[0]->value ? 1 : 0) }
sub bool { shift }

#-----------------------------------------------------------------------------
package TestML::List;
use TestML::Object -base;

has 'type' => 'List';

#-----------------------------------------------------------------------------
package TestML::None;
use TestML::Object -base;

has 'type' => 'None';

sub str { Str('') }
sub num { Num(0) }
sub bool { Bool(0) }
sub list { List([]) }

#-----------------------------------------------------------------------------
package TestML::Code;
use TestML::Object -base;

has 'type' => 'Code';

# #-----------------------------------------------------------------------------
# package TestML::Native;
# use TestML::Object -base;
# 
# has 'type' => 'Func';
# 

package TestML::AST;

our $True = TestML::Bool->new(value => 1);
our $False = TestML::Bool->new(value => 0);
our $None = TestML::None->new;

