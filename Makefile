all: grammar.json

grammar.json: grammar.yaml
	perl -MYAML::XS -MJSON::XS -e 'print encode_json YAML::XS::LoadFile("$<")' > $@
