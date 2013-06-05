#!perl
use strict;
use warnings;

use Test::More 0.88;

use Path::Class;
my $lib = dir( file(__FILE__)->dir->parent, 'lib')->absolute;
unshift @INC, "$lib";
note '@INC: '; note explain \@INC;

use Test::DZil;
my $tzil = Builder->from_config(
  { dist_root => 'corpus/' },
  { },
);

$tzil->build;

my $dir = dir($tzil->tempdir, 'build');

ok -e, "$_ exists" for map { my $file = "$_.pm"; $dir->file('inc', split /::|'/, $file) } qw{
      Pegex::Grammar
      Pegex::Input
      Pegex::Parser
      Pegex::Tree
      Pegex::Receiver
      TestML
      TestML::Base
      TestML::AST
      TestML::Compiler
      TestML::Grammar
      TestML::Library::Debug
      TestML::Library::Standard
      TestML::Runtime
      TestML::Runtime::TAP
};
ok ! -e, "$_ doesn't exists" for map { my $file = "$_.pm"; $dir->file('inc', split /::|'/, $file) } qw{strict warnings Scalar::Util};

done_testing;
