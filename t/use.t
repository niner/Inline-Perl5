#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

my $i = Inline::Perl5.new();
$i.use('Test::More');
$i.call('Test::More::ok', 1);
$i.call('Test::More::done_testing');

$i.DESTROY;

# vim: ft=perl6
