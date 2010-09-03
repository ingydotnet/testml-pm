package TestML::AST;

#-----------------------------------------------------------------------------
package TestML::Function;
use TestML::Base -base;

has 'parent';
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
        $self = $self->parent;
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

has 'type' => 'None';
has 'value';

sub runtime {
    return $TestML::Runtime::self;
}

sub set {
    my $self = shift;
    my $type = shift;
    my $value = shift;
    $self->runtime->throw("Invalid context type '$type'")
        unless $type =~ /^(?:None|Str|Num|Bool|List)$/;
    $self->type($type);
    $self->value($value);
    $self->runtime->function->expression->set_called(1);
}

sub assert_type {
    my $self = shift;
    my $type = $self->type;
    return $self->value if grep $type eq $_, @_;
    $self->runtime->throw("context object is type '$type', but '@_' required");
}

sub as_str {
    my $self = shift;
    my $type = $self->type;
    my $value = $self->value;
    return
        $type eq 'Str' ? $value :
        $type eq 'List' ? join("", @$value) :
        $type eq 'Bool' ? $value ? '1' : '' :
        $type eq 'Num' ? "$value" :
        $type eq 'None' ? '' :
        $self->runtime->throw("Str type error: '$type'");
}

sub as_num {
    my $self = shift;
    my $type = $self->type;
    my $value = $self->value;
    return
        $type eq 'Str' ? $value + 0 :
        $type eq 'List' ? scalar(@$value) :
        $type eq 'Bool' ? $value ? 1 : 0 :
        $type eq 'Num' ? $value :
        $type eq 'None' ? 0 :
        $self->runtime->throw("Num type error: '$type'");
}

sub as_bool {
    my $self = shift;
    my $type = $self->type;
    my $value = $self->value;
    return
        $type eq 'Str' ? length($value) ? 1 : 0 :
        $type eq 'List' ? @$value ? 1 : 0 :
        $type eq 'Bool' ? $value :
        $type eq 'Num' ? $value == 0 ? 0 : 1 :
        $type eq 'None' ? 0 :
        $self->runtime->throw("Bool type error: '$type'");
}

#-----------------------------------------------------------------------------
package TestML::String;
use TestML::Object -base;

has 'type' => 'Str';

#-----------------------------------------------------------------------------
package TestML::Number;
use TestML::Object -base;

has 'type' => 'Num';

#-----------------------------------------------------------------------------
package TestML::Boolean;
use TestML::Object -base;

has 'type' => 'Bool';

#-----------------------------------------------------------------------------
package TestML::Function;
use TestML::Object -base;

has 'type' => 'Func';

