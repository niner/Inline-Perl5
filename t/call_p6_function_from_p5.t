#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

my $p5 = Inline::Perl5.new();
$p5.run(q:to/PERL5/);
    use 5.10.0;

    STDOUT->autoflush(1);
    say '1..2';

    v6::call('say', 'ok 1');
    PERL5

say 'ok 2';

# vim: ft=raku
