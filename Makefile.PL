use inc::Module::Install;

name 'TestML';
all_from 'lib/TestML.pm';

requires 'Pegex' => '0.10';
use_gloom 'TestML::Base';

testml_setup 't/testml.yaml';

clean_files 'MANIFEST';

WriteAll;
