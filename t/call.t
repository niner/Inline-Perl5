#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

say "1..2";

my $i = p5_init_perl();
say $i.run('
use 5.10.0;

sub test {
    say "ok 1 - executing a parameterless function without return value";
}

sub test_int_params {
    if ($_[0] == 2 and $_[1] == 1) {
        say "ok 2 - int params";
    }
    else {
        say "not ok 2 - int params";
    }
}
');

$i.call('main::test');
$i.call('main::test_int_params', 2, 1);

$i.DESTROY;

# vim: ft=perl6
