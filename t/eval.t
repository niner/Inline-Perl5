#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

say '1..2';

my $i = Inline::Perl5.new();

$i.run('
    use 5.10.0;
    say "ok 1 - basic eval";
');

$i.run('
    use 5.10.0;
    use Fcntl;
    say "ok 2 - loading XS modules";
');

$i.DESTROY;

# vim: ft=perl6
