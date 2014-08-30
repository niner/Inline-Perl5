#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;

plan 2;

my $i = p5_init_perl();
$i.init_callbacks();
$i.run(q/
    sub test {
        $_[1]->test('Perl6');
        $_[1]->test('Perl6');
    };
/);

class Foo {
    method test(Str $name) {
        is $name, 'Perl6';
    }
}

$i.call('test', 'main', Foo.new);

$i.DESTROY;

# vim: ft=perl6

