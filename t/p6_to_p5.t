#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;

plan 6;

my $i = p5_init_perl();
$i.run(q[ sub identity { return $_[1] }; ]);

for ('abc', 24, [1, 2], { a=> 1, b => 2}, Any) -> $obj {
    is_deeply $i.call('identity', 'main', $obj), $obj, "Can round-trip " ~ $obj.^name;
}

throws_like { $i.call('dummy', 'main', Any.new) }, X::Inline::Perl5::Unmarshallable, object => Any;

$i.DESTROY;

# vim: ft=perl6
