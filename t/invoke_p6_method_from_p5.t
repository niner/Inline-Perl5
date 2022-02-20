#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

class Foo {
    method give_one() {
        return 1;
    }
    method take_named(*@args, :$foo, :$bar) {
        return @args[1] ~ $foo ~ $bar;
    }
}

my $p5 = Inline::Perl5.new();
$p5.run(q:to/PERL5/);
    use 5.10.0;
    use Test::More;

    ok(my $foo = v6::invoke('Foo', 'new'));
    is($foo->give_one, 1);
    is(
        v6::invoke('Foo', 'take_named', 'pos0', 'pos1', v6::named foo => "bar", baz => "qux", bar => "baz"),
        "pos1barbaz",
    );

    done_testing;
    PERL5

# vim: ft=raku
