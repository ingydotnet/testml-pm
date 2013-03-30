package TestML::Setup;
use TestML::Base;

use YAML::XS;
use IO::All;
use Template::Toolkit::Simple;
use File::Basename;
use Cwd 'abs_path';

use constant DEFAULT_TESTML_CONF => './t/testml.yaml';

sub setup {
    my ($self, $testml_conf) = @_;
    $testml_conf ||= DEFAULT_TESTML_CONF;
    die "TestML conf file '$testml_conf' not found"
      unless -f $testml_conf;
    die "TestML conf file must be .yaml"
        unless $testml_conf =~ /\.ya?ml$/;
    # File paths are relative to the yaml file location
    my $base = File::Basename::dirname($testml_conf);
    my $conf = YAML::XS::LoadFile($testml_conf);
    my $source = $conf->{source_testml_dir}
        or die "`testml_setup` requires 'source_testml_dir' key in '$testml_conf'";
    my $target = $conf->{local_testml_dir}
        or die "`testml_setup` requires 'local_testml_dir' key in '$testml_conf'";
    my $tests = $conf->{test_file_dir} || '.';
    $source = abs_path("$base/$source");
    $target = abs_path("$base/$target");
    $tests = abs_path("$base/$tests");
    die "'#{source}' directory does not exist"
        unless -e $source;
    mkdir $target unless -d $target;
    mkdir $tests unless -d $tests;
    my $template = $conf->{test_file_template} || '';
    my $skip = $conf->{exclude_testml_files} || [];
    my $files = $conf->{include_testml_files} ||
        [map $_->filename, grep {"$_" =~ /\.tml$/} io($source)->all_files];
    for my $file (sort @$files) {
        next if grep {$_ eq $file} @$skip;
        my $s = "$source/$file";
        my $t = "$target/$file";
        if (not -f $t or io($s)->all ne io($t)->all) {
            print "Copying ${\$self->rel($s)} to ${\$self->rel($t)}\n";
            io($t)->print(io($s)->all);
        }
        if ($template) {
            (my $test = $file) =~ s/\.tml$/.t/;
            $test = $conf->{test_file_prefix} . $test
                if $conf->{test_file_prefix};
            $test = abs_path "$tests/$test";
            my $hash = {
                file => $self->rel($t, $base),
            };
            my $code = tt->data($hash)->render(\$template);
            if (not -f $test or $code ne io($test)->all) {
                my $action = -f $test ? 'Updating' : 'Creating';
                print "$action test file '${\$self->rel($test)}'\n";
                io($test)->print($code);
            }
        }
    }
}

sub rel {
    my ($self, $path, $base) = @_;
    $base ||= '.';
    $base = abs_path($base);
    File::Spec->abs2rel($path, $base);
}

1;
