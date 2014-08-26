.PHONY: clean
all: Inline/p5helper.so
clean:
	rm Inline/p5helper.so
Inline/p5helper.so: p5helper.c
	gcc p5helper.c `perl -MExtUtils::Embed -e ccopts -e ldopts` -shared -o Inline/p5helper.so -fPIC
