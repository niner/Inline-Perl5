#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;

plan 2;

my $i = Inline::Perl5.new();
is $i.run('5;'), 5;
is $i.run('"Perl 5";'), 'Perl 5';
$i.DESTROY;

# vim: ft=perl6
