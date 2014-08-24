p5helper.so: p5helper.c
	gcc p5helper.c `perl -MExtUtils::Embed -e ccopts -e ldopts` -shared -o p5helper.so -fPIC
