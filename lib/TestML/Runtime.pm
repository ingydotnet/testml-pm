package TestML::Runtime;
use TestML::Base -base;

use TestML::Parser;
use TestML::Object;

# Since there is only ever one test runtime, it makes things a lot easier to
# keep the reference to it in a global variable accessed by a method, than to
# put a reference to it into every object that needs to access it.
our $self;

has 'bridge';
has 'testml';
has 'transforms';
has 'base', -init => '$0 =~ m!(.*)/! ? $1 : "."';
has 'document', -init => '$self->parse_document()';
has 'expression';
has 'block';
has 'variables' => {
    'Label' => '$BlockLabel',
};

sub init {
    my $self = $TestML::Runtime::self = shift;
    $self->SUPER::init(@_);
    $self->transforms([
        'TestML::Transforms::Standard',
        'TestML::Transforms::Debug',
        $self->bridge || (),
    ]);
    $self->load_transform_modules;
    return $self;
}

sub title { }
sub plan_begin { }
sub plan_end { }

sub run {
    my $self = shift;

    $self->title();
    $self->plan_begin();

    for my $statement (@{$self->document->test->statements}) {
        my $blocks = @{$statement->points}
            ? $self->select_blocks($statement->points)
            : [TestML::Block->new()];
        for my $block (@$blocks) {
            $self->block($block);
            my $left = $self->evaluate_expression(
                $statement->expression,
                $block,
            );
            if (my $assertion = $statement->assertion) {
                my $method = 'assert_' . $assertion->name;
                # TODO - Should check 
                if (@{$assertion->expression->transforms}) {
                    my $right = $self->evaluate_expression(
                        $assertion->expression,
                        $block,
                    );
                    $self->$method($left, $right);
                }
                else {
                    $self->$method($left);
                }
            }
        }
    }
    $self->plan_end();
}

sub select_blocks {
    my $self = shift;
    my $wanted = shift;
    my $selected = [];

    OUTER: for my $block (@{$self->document->data->blocks}) {
        my %points = %{$block->points};
        next if exists $points{SKIP};
        for my $point (@$wanted) {
            next OUTER unless exists $points{$point};
        }
        if (exists $points{ONLY}) {
            @$selected = ($block);
            last;
        }
        push @$selected, $block;
        last if exists $points{LAST};
    }
    return $selected;
}

sub evaluate_expression {
    my $self = shift;
    my $prev_expression = $self->expression;
    my $expression = shift;
    $self->expression($expression);
    my $block = shift || undef;

    my $context = TestML::Context->new();

    for my $transform (@{$expression->transforms}) {
        my $transform_name = $transform->name;
        next if $expression->error and $transform_name ne 'Catch';
        if (ref($transform) eq 'TestML::String') {
            $context->set(Str => $transform->value);
            next;
        }
        my $function = $self->get_transform_function($transform_name);
        $expression->set_called(0);
        my $value = eval {
            &$function(
                $context,
                map {
                    (ref($_) eq 'TestML::Expression')
                    ? $self->evaluate_expression($_, $block)
                    : $_
                } @{$transform->args}
            );
        };
        if ($@) {
            $expression->error($@);
            $context->type('None');
            $context->value(undef);
        }
        elsif (not $expression->set_called) {
            $context->value($value);
        }
    }
    if ($expression->error) {
        die $expression->error;
    }
    $self->expression($prev_expression);
    return $context;
}

sub load_transform_modules {
    my $self = shift;
    for my $module_name (@{$self->transforms}) {
        next if $module_name eq 'main';
        eval "require $module_name; 1"
            or die "Can't use $module_name:\n$@";
    }
}

sub get_transform_function {
    my $self = shift;
    my $name = shift;
    my $modules = $self->transforms();
    for my $module (@$modules) {
        eval "use $module";
        no strict 'refs';
        return \&{"$module\::$name"}
            if defined &{"$module\::$name"};
    }
    die "Can't locate function '$name'";
}

sub parse_document {
    my $self = shift;
    my ($fh, $base);
    if (ref $self->testml) {
        $fh = $self->testml;
        $base = $self->base;
    }
    else {
        my $path = join '/', $self->base, $self->testml;
        open $fh, $path or die "Can't open $path for input";
        $base = $path;
        $base =~ s/(.*)\/.*/$1/ or die;
    }
    my $text = do { local $/; <$fh> };
    my $document = TestML::Parser->parse($text)
        or die "TestML document failed to parse";
    if (@{$document->meta->data->{Data}}) {
        my $data_files = $document->meta->data->{Data};
        my $inline = $document->data->blocks;
        $document->data->blocks([]);
        for my $file (@$data_files) {
            if ($file eq '_') {
                push @{$document->data->blocks}, @$inline;
            }
            else {
                my $path = join '/', $base, $file;
                open IN, $path or die "Can't open $path for input";
                my $text = do { local $/; <IN> };
                my $blocks = TestML::Parser->parse_data($text)
                    or die "TestML data document failed to parse";
                push @{$document->data->blocks}, @$blocks;
            }
        }
    }
    return $document;
}

sub get_label {
    my $self = shift;
    my $label = $self->variables->{Label};
    my %replace = map {
        my $v = $self->block->points->{$_};
        $v =~ s/\n.*//s;
        $v =~ s/^\s*(.*?)\s*$/$1/;
        ($_, $v);
    } keys %{$self->block->points};
    $replace{BlockLabel} = $self->block->label;
    $label =~ s/\$(\w+)/$replace{$1}/ge;
    return $label;
}

sub get_error {
    my $self = shift;
    return $self->expression->error;
}

sub clear_error {
    my $self = shift;
    return $self->expression->error(undef);
}

sub throw {
    require Carp;
    Carp::croak $_[1];
}
