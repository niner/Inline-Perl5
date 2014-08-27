#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;

plan 1;

my $i = p5_init_perl();

throws_like { $i.call('dummy', 'main', Any.new) }, X::Inline::Perl5::Unmarshallable, object => Any;

$i.DESTROY;

# vim: ft=perl6
