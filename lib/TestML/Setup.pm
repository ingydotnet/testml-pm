package TestML::Setup;
use strict;
use warnings;

use YAML::XS;
use IO::All;
use Template::Toolkit::Simple;

my $config_file = 'testml.yaml';
my $base;
my $config = {};
my $template;
my $testml;
my $local;
my $lang;
my $skip;

sub testml_setup {
    init(@_);
    my %data = %$config;
    $data{testml_dir} = $local;
    for my $file (io("$base/$testml")->all_files) {
        my $testml_file = $data{testml_file} = $file->filename;
        my $name = $testml_file;
        $name =~ s/\.tml$// or next;

        my $src = "$base/$testml/$testml_file";
        my $dest = "$base/$local/$testml_file";
        
        if (not -e $dest or -M $src < -M $dest) {
            system("cp -f $src $dest") == 0
                or die "copy $src to $dest failed";

            next if grep {$name eq $_} @$skip;
            my $filename = "$name.t";
            print "Generating $filename\n";
            my $output = tt->render(\$template, \%data);
            io("$base/$filename")->print($output);
        }
    }
}

sub init {
    $config_file = shift;
    $config_file =~ /(.*)\//;
    $base = $1 || '.';
    $config = YAML::XS::LoadFile("$config_file");
    die "Missing or invalid 'testml' directory in $config_file"
        unless $config->{testml} and -d "$base/$config->{testml}";
    die "Missing or invalid 'local' directory in $config_file"
        unless $config->{local} and -d "$base/$config->{local}";
    die "Missing 'lang' in $config_file"
        unless $config->{lang};
    die "'lang' must be 'pm5' or 'pm6' in $config_file"
        unless $config->{lang} =~ /^(pm5|pm6)$/;
    ($testml, $local, $lang, $skip) =
        @{$config}{qw(testml local lang skip)};
    $skip ||= [];
    $config->{bridge} ||= '';
    no strict 'refs';
    $template = &{"template_$lang"}();
}

sub template_pm5 {
    return <<'...';
use TestML -run,
    -testml => '[% testml_dir %]/[% testml_file %]',
    -bridge => '[% bridge %]';
...
}

sub template_pm6 {
    return <<'...';
use v6;
use TestML::Runner::TAP;

TestML::Runner::TAP.new(
    document => '[% testml_dir %]/[% testml_file %]',
    bridge => '[% bridge %]',
).run();
...
}

1;

=encoding utf-8

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

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2010. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
