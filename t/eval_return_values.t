#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;

plan 2;

my $p5 = Inline::Perl5.new();
is $p5.run('5;'), 5;
is $p5.run('"Perl 5";'), 'Perl 5';
$p5.DESTROY;

# vim: ft=perl6
