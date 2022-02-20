#!/usr/bin/env perl6

use v6;
use Inline::Perl5;
use Test;
use lib:from<Perl5> 't/lib';
use A:from<Perl5>;

my $p5 = Inline::Perl5.default_perl5;

$p5.run: q:to/PERL5/;
    package Foo;

    sub new {
        return bless {a => 1, b => 2};
    }

    PERL5

my $foo = $p5.invoke('Foo', 'new');

is($foo<a>, 1);
is($foo<b>, 2);

my $a = A.new;
is($a<a>, 1);
is($a<b>, 2);

done-testing;

# vim: ft=raku
