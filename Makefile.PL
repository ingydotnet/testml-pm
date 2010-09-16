use inc::Module::Install;

name 'TestML';
all_from 'lib/TestML.pm';
readme_from;
manifest_skip
ack_xxx;

requires 'Pegex' => '0.10';
use_gloom 'TestML::Base';

testml_setup 't/testml.yaml';

clean_files 'MANIFEST';

WriteAll;
