SPEC := Specification.kwim

default: doc

doc: README.rdoc

README.rdoc: $(SPEC)
	stardoc convert {input: $< output: $@}
