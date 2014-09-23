#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;

plan 1;

BEGIN {
    my $p5 = Inline::Perl5.new();
    $p5.run('use lib "t/lib";');
    $p5.use('TestV6');
}

is(TestV6::greet('world'), 'hello world');

# vim: ft=perl6
