#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;
use NativeCall;

plan 1;

my $p5 = Inline::Perl5.new();
$p5.run(q/
    sub test {
    };
/);

my $destroyed = 0;

class Foo {
    has $.bar;
    method DESTROY {
        $destroyed++;
    }
}

# create new objects until the GC kicks in and destroys at least one of them
# this will loop endlessly if we leak all objects
until $destroyed {
    $p5.call('test', 'main', Foo.new);
}

ok(1, 'at least one destructor ran');

$p5.DESTROY;

# vim: ft=perl6


