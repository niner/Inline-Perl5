#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;

plan 7;

my $p5 = Inline::Perl5.new();
$p5.run(q[ sub identity { return $_[1] }; ]);

class Foo {
}

for ('abcö', 24, [1, 2], { a=> 1, b => 2}, Any, Foo.new) -> $obj {
    is_deeply $p5.call('identity', 'main', $obj), $obj, "Can round-trip " ~ $obj.^name;
}

$p5.run(q/
    use utf8;
    sub check_utf8 {
        my ($str) = @_;

        return $str eq 'Töst';
    };
/);

ok($p5.call('check_utf8', 'Töst'), 'UTF-8 string recognized in Perl 5');

$p5.DESTROY;

# vim: ft=perl6
