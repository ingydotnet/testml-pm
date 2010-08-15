use inc::Module::Install;

name 'TestML';
all_from 'lib/TestML.pm';

requires 'Pegex';
use_gloom 'TestML::Base';

WriteAll;
