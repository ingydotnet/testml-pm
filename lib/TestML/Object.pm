package TestML::Object;
use TestML::Base -base;

has 'type';
has 'value';

sub set {
    my $self = shift;
    my $type = shift;
    my $value = shift;
    $self->runner->throw("Invalid context type '$type'")
        unless $type =~ /^(?:None|Str|Num|Bool|List)$/;
    $self->type($type);
    $self->value($value);
    $self->runner->expression->set_called(1);
}

sub get_value_if_type {
    my $self = shift;
    my $type = $self->type;
    return $self->value if grep $type eq $_, @_;
    $self->runner->throw("context object is type '$type', but '@_' required");
}

sub get_value_as_str {
    my $self = shift;
    my $type = $self->type;
    my $value = $self->value;
    return
        $type eq 'Str' ? $value :
        $type eq 'List' ? join("", @$value) :
        $type eq 'Bool' ? $value ? '1' : '' :
        $type eq 'Num' ? "$value" :
        $type eq 'None' ? '' :
        $self->runner->throw("Str type error: '$type'");
}

sub get_value_as_num {
    my $self = shift;
    my $type = $self->type;
    my $value = $self->value;
    return
        $type eq 'Str' ? $value + 0 :
        $type eq 'List' ? scalar(@$value) :
        $type eq 'Bool' ? $value ? 1 : 0 :
        $type eq 'Num' ? $value :
        $type eq 'None' ? 0 :
        $self->runner->throw("Num type error: '$type'");
}

sub get_value_as_bool {
    my $self = shift;
    my $type = $self->type;
    my $value = $self->value;
    return
        $type eq 'Str' ? length($value) ? 1 : 0 :
        $type eq 'List' ? @$value ? 1 : 0 :
        $type eq 'Bool' ? $value :
        $type eq 'Num' ? $value == 0 ? 0 : 1 :
        $type eq 'None' ? 0 :
        $self->runner->throw("Bool type error: '$type'");
}

package TestML::Context;
use TestML::Object -base;

sub runner {
    return $TestML::Runner::self;
}

