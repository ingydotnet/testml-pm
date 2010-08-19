SRC = ../../../testml-tml
ALL = $(shell ls $(SRC) | grep '\.tml$$')

all: $(ALL)

$(ALL):
	ln -s $(SRC)/$@ $@
