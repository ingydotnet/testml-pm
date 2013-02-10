##
# name:      TestML::Setup
# author:    Ingy döt Net <ingy@cpan.org>
# abstract:  Generate Test Files for a TestML Suite
# license:   perl
# copyright: 2010-2013

package TestML::Setup;
use strict;
use warnings;

use YAML::XS;
use IO::All;
use Template::Toolkit::Simple;

use base 'Exporter';
@TestML::Setup::EXPORT = qw(setup);

my $config_file = 'testml.yaml';
my $base;
my $template;

sub setup {
    testml_setup(@ARGV);
}

sub testml_setup {
    my $conf = init(@_);
    my %data = %$conf;

    for my $file (io("$base/$conf->{source}")->all_files) {
        my $testml_file = $data{testml_file} = $file->filename;
        $data{testml_dir} = $conf->{target};
        my $name = $testml_file;
        $name =~ s/\.tml$// or next;

        my $src = "$base/$conf->{source}/$testml_file";
        my $dest = "$base/$conf->{target}/$testml_file";

        if (@{$conf->{include}}) {
            next unless grep {$name eq $_} @{$conf->{include}};
        }
        next if grep {$name eq $_} @{$conf->{skip}};

        my $testname = $conf->{testname};
        $testname =~ s/\$name/$name/;
        if (not -e "$base/$testname" or not -e $dest or -M $src < -M $dest) {

            if (not(-e $dest) or (-M $src < -M $dest) and (io($dest)->all ne io($src)->all)) {
                my $copy_cmd = "cp -f $src $dest";
                print "$copy_cmd\n";
                system($copy_cmd) == 0 or die "'$copy_cmd' failed";
            }

            next unless io($dest)->all =~ /^%TestML \d/m;
            next if -e "$base/$testname";

            print "Generating $testname\n";
            my $output = tt->render(\$template, \%data);
            io("$base/$testname")->print($output);
        }
    }
}

sub init {
    $config_file = shift;
    $config_file =~ /(.*)\//;
    $base = $1 || '.';
    my $conf = YAML::XS::LoadFile("$config_file");
    die "Missing or invalid 'source' directory in $config_file"
        unless $conf->{source} and -d "$base/$conf->{source}";
    die "Missing or invalid 'target' directory in $config_file"
        unless $conf->{target} and -d "$base/$conf->{target}";
    $conf->{testname} ||= '$name.t';

    if ($conf->{template}) {
        $template = io("$base/$conf->{template}")->all;
    }
    else {
        die "Missing 'lang' in $config_file"
            unless $conf->{lang};
        no strict 'refs';
        $template = &{"template_$conf->{lang}"}();
    }

    $conf->{include} ||= [];
    $conf->{skip} ||= [];

    return $conf;
}

1;

=head1 SYNOPSIS

    perl -MTestML::Setup -e setup testml.yaml

=head1 DESCRIPTION

A pure TestML suite contains no language specific code. Normally you
need to write a very small test program that points to a TestML document
and runs it.

This module does that for you. By providing a small YAML file, this
module will generate all your testml runtime programs for you.
