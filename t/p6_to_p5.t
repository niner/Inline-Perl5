#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;

plan 6;

my $i = Inline::Perl5.new();
$i.run(q[ sub identity { return $_[1] }; ]);

class Foo {
}

for ('abc', 24, [1, 2], { a=> 1, b => 2}, Any, Foo.new) -> $obj {
    is_deeply $i.call('identity', 'main', $obj), $obj, "Can round-trip " ~ $obj.^name;
}

$i.DESTROY;

# vim: ft=perl6
