use inc::Module::Install;

name 'TestML';
all_from 'lib/TestML.pm';

requires 'Parse::Pegex';

WriteAll;
