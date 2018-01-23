#!/usr/bin/env perl6

use v6.c;

use Inline::Perl5;

my $fun = sub ($p5) {
    for 1..100 {
	$p5.run("print('foo')" );
    }    
};

my $p5_1 = Inline::Perl5.new;
my $first = start {
    $fun($p5_1);
};
my $p5_2 = Inline::Perl5.new;
my $second = start {
    $fun($p5_2);
};

await($first);
await($second);
