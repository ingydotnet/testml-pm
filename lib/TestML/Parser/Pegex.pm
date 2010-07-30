package TestML::Parser::Pegex;
use strict;
use warnings;
use TestML::Base -base;

# field 'grammar', -init => '$self->{grammar_data}';
field 'stream';
field 'rule';
field 'position' => 0;
field 'receiver';
field 'arguments' => [];

sub parse {
    my $self = shift;
    $self->stream(shift);
    $self->init(@_);
    $self->match($self->rule);
    if ($self->position < length($self->stream)) {
        die "Parse document failed for some reason";
    }
    return $self;
}

sub match {
    my $self = shift;
    my $rule = shift or die "No rule passed to match";

    my $not = 0;

    my $state = undef;
    if (not ref($rule) and $rule =~ /^\w+$/) {
        $state = $rule;
        $self->callback("try_$state");

        if (not defined $self->grammar->{$rule}) {
            die "\n\n*** No grammar support for '$rule'\n\n";
            return 0;
        }
        
        $rule = $self->grammar->{$rule};
    }

    my $method;
    my $times = $rule->{'<'} || '1';
    if ($rule->{'+not'}) {
        $rule = $rule->{'+not'};
        $method = 'match';
        $not = 1;
    }
    elsif ($rule->{'+rule'}) {
        $rule = $rule->{'+rule'};
        $method = 'match';
    }
    elsif (defined $rule->{'+re'}) {
        $rule = $rule->{'+re'};
        $method = 'match_regexp';
    }
    elsif ($rule->{'+all'}) {
        $rule = $rule->{'+all'};
        $method = 'match_all';
    }
    elsif ($rule->{'+any'}) {
        $rule = $rule->{'+any'};
        $method = 'match_any';
    }
    else {
        die "no support for $rule";
    }

    my $position = $self->position;
    my $count = 0;
    while ($self->$method($rule)) {
        $count++;
        last if $times eq '1' or $times eq '?';
    }
    my $result = (($count or $times eq '?' or $times eq '*') ? 1 : 0) ^ $not;

    if ($state and not $not) {
        $result
            ? $self->callback("got_$state")
            : $self->callback("not_$state");
    }

    $self->position($position) unless $result;
    return $result;
}

sub match_all {
    my $self = shift;
    my $list = shift;
    for my $elem (@$list) {
        $self->match($elem) or return 0;
    }
    return 1;
}

sub match_any {
    my $self = shift;
    my $list = shift;
    for my $elem (@$list) {
        $self->match($elem) and return 1;
    }
    return 0;
}

sub match_regexp {
    my $self = shift;
    my $regexp = shift;

    pos($self->{stream}) = $self->position;
    $self->{stream} =~ /$regexp/g or return 0;
    if (defined $1) {
        $self->arguments([$1, $2, $3, $4, $5]);
    }
    $self->position(pos($self->{stream}));

    return 1;
}

my $warn = 0;
sub callback {
    my $self = shift;
    my $method = shift;

    if ($self->receiver->can($method)) {
        $self->receiver->$method(@{$self->arguments});
    }
}

# sub throw_error {
#     my $self = shift;
#     my $msg = shift;
#     my $line = @{[substr($self->stream, 0, $self->position) =~ /(\n)/g]} + 1;
#     my $context = substr($self->stream, $self->position, 50);
#     $context =~ s/\n/\\n/g;
#     die <<"...";
# Error parsing TestML document:
#   msg: $msg
#   line: $line
#   context: "$context"
# ...
# }

1;
