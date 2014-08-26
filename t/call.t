#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

say '1..1';

my $i = p5_init_perl();
say $i.run('
use 5.10.0;

sub test {
    say "ok 1 - executing a parameterless function without return value";
}
');

$i.call('main::test');

$i.DESTROY;

# vim: ft=perl6
