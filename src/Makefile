SRC=../../testml-pgx
BASE=../lib/TestML

$(BASE)/Grammar.pm: testml.pgx grammar.pl Makefile $(BASE)
	perl grammar.pl $< > $@

testml.pgx: $(SRC)/testml.pgx
	cp $< $@

$(BASE):
	mkdir -p $@

clean:
	rm -fr $(BASE)
