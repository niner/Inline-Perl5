#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;

my $p5 = Inline::Perl5.new();

ok(not $p5.invoke('Foo', 'can', 'bar'));

done;

# vim: ft=perl6
