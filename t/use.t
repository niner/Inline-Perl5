#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

my $p5 = Inline::Perl5.new();
$p5.use('Test::More', 'tests', 1);
$p5.call('Test::More::ok', 1);

$p5.DESTROY;

# vim: ft=perl6
