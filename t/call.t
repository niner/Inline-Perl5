#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

say "1..3";

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

sub test_str_params {
    if (@_ == 2 and $_[0] eq "Hello" and $_[1] eq "Perl 5") {
        say "ok 3 - str params";
    }
    else {
        say "not ok 3 - str params";
    }
}
');

$i.call('main::test');
$i.call('main::test_int_params', 2, 1);
$i.call('main::test_str_params', 'Hello', 'Perl 5');

$i.DESTROY;

# vim: ft=perl6
