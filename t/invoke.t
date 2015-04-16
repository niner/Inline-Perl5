#!/usr/bin/env perl6

use v6;
use Inline::Perl5;
use Test;

my $p5 = Inline::Perl5.new;

$p5.run: q:heredoc/PERL5/;
    package Foo;

    sub new {
        return bless {};
    }

    sub push {
        return 'pushed';
    }
    PERL5

my $foo = $p5.invoke('Foo', 'new');

is($foo.push, 'pushed');

done;
