#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

my $i;
BEGIN { $i = Inline::Perl5.new(); }
$i.use('Test::More');

sub ok(Int)              is p5($i) { ... }
sub is(Any, Any, Str $?) is p5($i) { ... }
sub done_testing()       is p5($i) { ... }

ok(1);
is('foo', 'foo');

done_testing;

$i.DESTROY;

# vim: ft=perl6
