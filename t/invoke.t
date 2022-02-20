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

    sub context {
        return(wantarray ? 'list' : 'scalar');
    }

    PERL5

my $foo = $p5.invoke('Foo', 'new');

for ^2 {
    is($foo.push, 'pushed');
    my @a = $foo.nothing;
    is($foo.count_args($foo.nothing), 1);
    is($foo.count_args($foo.empty_hash), 2);
    is($foo.count_args(:a(1), :b(2)), 5);
    is($foo.context, 'list');
    is($foo.context(1), 'list');
    is($foo.context(1, 2), 'list');
    is($foo.context(Any), 'list');
    is($foo.context(Scalar), 'scalar');
    is($foo.context(Scalar, 1), 'scalar');
    is($foo.context(Scalar, 1, 2), 'scalar');
    is($foo.context(Scalar, Any), 'scalar');
    is($foo.context(:named), 'list');
    is($foo.context(1, :named), 'list');
    is($foo.context(1, 2, :named), 'list');
    is($foo.context(Any, :named), 'list');
    is($foo.context(Scalar, :named), 'scalar');
    is($foo.context(Scalar, 1, :named), 'scalar');
    is($foo.context(Scalar, 1, 2, :named), 'scalar');
    is($foo.context(Scalar, Any, :named), 'scalar');
}

done-testing;

# vim: ft=raku
