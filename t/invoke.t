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

    sub nothing {
        return;
    }

    sub empty_hash {
        return {};
    }

    sub count_args {
        return scalar @_;
    }

    PERL5

my $foo = $p5.invoke('Foo', 'new');

is($foo.push, 'pushed');
my @a = $foo.nothing;
is($foo.count_args($foo.nothing), 1);
is($foo.count_args($foo.empty_hash), 2);

done-testing;

# vim: ft=perl6
