#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;

plan 2;

BEGIN {
    my $p5 = Inline::Perl5.new();
    $p5.run('use lib "t/lib";');
    $p5.use('TestV6');
}

is(Foo::Bar::TestV6::greet('world'), 'hello world');
is(Foo::Bar::TestV6.new(name => 'world').hello, 'hello world');

# vim: ft=perl6
