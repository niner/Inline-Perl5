#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

class Foo {
    method give_one() {
        return 1;
    }
}

my $p5 = Inline::Perl5.new();
$p5.run(q:to/PERL5/);
    use 5.10.0;
    use Test::More;

    ok(my $foo = v6::invoke('Foo', 'new'));
    is($foo->give_one, 1);

    done_testing;
    PERL5

# vim: ft=perl6
