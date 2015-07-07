#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;

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
my $i = 0;
until $destroyed {
    $p5.call('test', 'main', Foo.new(bar => 'bar'));
    last if $i++ > 100000;
}

ok($destroyed, 'at least one destructor ran');

$p5.DESTROY;

# vim: ft=perl6


