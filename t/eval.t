#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

say '1..2';

my $p5 = Inline::Perl5.new();

$p5.run('
    use 5.10.0;
    say "ok 1 - basic eval";
');

$p5.run('
    use 5.10.0;
    use Fcntl;
    say "ok 2 - loading XS modules";
');

$p5.DESTROY;

# vim: ft=perl6
