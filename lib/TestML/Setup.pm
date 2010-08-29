package TestML::Setup;
use strict;
use warnings;

use base 'Exporter';

our @EXPORT = 'setup';

use YAML::XS;
use IO::All;
use Template::Toolkit::Simple;
use XXX;

my $config_file = 'testml.yaml';
my $config = {};
my $path = '.';

sub setup {
    load_config(@ARGV);
    my $template = get_template();
    for my $file (get_tml_files()) {
        print "> $file\n";
    }
}

sub load_config {
    $config_file = shift(@ARGV)
        or die 'Setup requires a yaml file';
    $path = $config_file;
    $path =~ s/(.+)\/.+/$1/
        or $path = '.';
    $config = YAML::XS::LoadFile($config_file);
}

sub get_template {
    no strict 'refs';
    if (my $template = $config->{template}) {
        return io("$path/$template")->all;
    }
    my $lang = $config->{lang}
        or die "Config must define 'template' or 'lang'";
    $lang =~ /^(pm5|pm6)$/
        or die "'lang' must be 'pm5' or 'pm6'";
    return &{"template_$lang"}();
}

sub get_tml_files {
    my $dir = $config->{src}
        or die "No 'src' directory in '$config_file'";
    return io($dir)->all_files;
}

sub template_pm5 {
    return <<'...';
use TestML -run,
    -testml => '[% src %]/[% test_file %]',
    -bridge => '[% bridge %]';
...
}

1;

=head1 NAME

TestML::Setup - Generate Test Files for a TestML Suite

=head1 SYNOPSIS

    perl -MTestML::Setup -e setup testml.yaml

=head1 DESCRIPTION

A pure TestML suite contains no language specific code. Normally you
need to write a very small test program that points to a TestML document
and runs it.

This module does that for you. By providing a small YAML file, this
module will generate all your testml runtime programs for you.

