package TestML::Parser::Pegex;
use strict;
use warnings;
use TestML::Base -base;

field 'stream';
field 'grammar', -init => '$self->{grammar_data}';
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

    my $not = ($rule =~ s/^!//) ? 1 : 0;

    my $state = undef;
    if (not ref($rule) and $rule =~ /^\w+$/) {
        $state = $rule;

        if (not defined $self->grammar->{$rule}) {
            die "\n\n*** No grammar support for '$rule'\n\n";
            return 0;
        }
        
        $rule = $self->grammar->{$rule};
    }

    my $method;
    my $times = $rule->{'<'} || '1';
    if ($rule->{'+rule'}) {
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
    else { XXX $rule }

    my $position = $self->position;
    my $count = 0;
    while ($self->$method($rule)) {
        $count++;
        last if $times eq '1' or $times eq '?';
    }
    my $result = (($count or $times eq '?' or $times eq '*') ? 1 : 0) ^ $not;

    if ($result and $state) {
#         print "> $state\n";
        $self->callback($state);
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
    my $pattern = shift;
    my $regexp = $self->get_regexp($pattern);

    pos($self->{stream}) = $self->position;
    $self->{stream} =~ /$regexp/g or return 0;
    if (defined $1) {
        $self->arguments([$1, $2, $3, $4, $5]);
    }
    $self->position(pos($self->{stream}));

    return 1;
}

sub get_regexp {
    my $self = shift;
    my $pattern = shift;
    $pattern =~ s/^\/(.*)\/$/$1/;
    while ($pattern =~ /\$(\w+)/) {
        my $replacement = $self->grammar->{$1}
          or die "'$1' not in grammar";
        $replacement =~ s/^\/(.*)\/$/$1/;
        $pattern =~ s/\$(\w+)/$replacement/;
    }
    return qr/\G$pattern/;
}

my $warn = 0;
sub callback {
    my $self = shift;
    my $method = shift;

    if ($self->receiver->can($method)) {
        $self->receiver->$method(@{$self->arguments});
    }
}

# sub open {
#     my $self = shift;
#     my $file = shift;
#     $self->stream($self->read($file));
# }
# 
# sub read {
#     my $self = shift;
#     my $file = shift;
#     my $fh;
#     if (ref $file) {
#         $fh = $file;
#     }
#     else {
#         CORE::open $fh, $file
#           or die "Can't open file '$file' for input.";
#     }
#     my $content = do {local $/; <$fh>};
#     close $fh;
#     if (length $content and $content !~ /\n\z/) {
#         die "File '$file' does not end with a newline.";
#     }
#     return $content;
# }
# 
sub throw_error {
    my $self = shift;
    my $msg = shift;
    my $line = @{[substr($self->stream, 0, $self->position) =~ /(\n)/g]} + 1;
    my $context = substr($self->stream, $self->position, 50);
    $context =~ s/\n/\\n/g;
    die <<"...";
Error parsing TestML document:
  msg: $msg
  line: $line
  context: "$context"
...
}

1;
