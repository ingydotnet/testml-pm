use inc::Module::Package 'Ingy:modern 0.20';

requires 'Pegex' => '0.21';

# Pull in testml-tml stuff.
testml_setup 't/testml.yaml';
testml_setup 't/testml-lite.yaml';
