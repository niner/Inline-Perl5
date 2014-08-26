#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;

my $i = p5_init_perl();

is $i.run('5'), 5;
is $i.run('"Perl 5"'), 'Perl 5';
is_deeply $i.run('[1, 2]'), [1, 2];
is_deeply $i.run('[1, [2, 3]]'), [1, [2, 3]];

$i.DESTROY;

done;

# vim: ft=perl6
