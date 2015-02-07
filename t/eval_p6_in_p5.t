#!/usr/bin/env perl6

use v6;
use Inline::Perl5;
use Test;

my $p5 = Inline::Perl5.new;

is($p5.run(q:to/PERL5/), 2);
        v6::run('1 + 1');
    PERL5

done;

$p5.DESTROY;

# vim: ft=perl6
