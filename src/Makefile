BASE=../lib/TestML/Parser

$(BASE)/Grammar.pm: testml.pgx grammar.pl Makefile $(BASE)
	perl grammar.pl $< > $@

$(BASE):
	mkdir -p $@

clean:
	rm -fr $(BASE)
