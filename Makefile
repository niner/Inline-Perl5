.PHONY: clean test
all: lib/Inline/p5helper.so
clean:
	rm lib/Inline/p5helper.so
lib/Inline/p5helper.so: p5helper.c
	gcc p5helper.c `perl -MExtUtils::Embed -e ccopts -e ldopts` -shared -o lib/Inline/p5helper.so -fPIC -g
test: all
	prove -e 'perl6 -Ilib' t
