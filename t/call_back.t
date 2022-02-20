#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

my $p5 = Inline::Perl5.new();
$p5.run(q/
    use Test::More;

    sub test {
        my ($raku) = @_;
        for (1 .. 100) {
            my @retval = $raku->test('Raku');
            is_deeply \@retval, ['Raku'];
            my @retval = $raku->test('Raku', 42);
            is_deeply \@retval, ['Raku', 42];
        }
    };
/);

class Foo {
    method test(*@args) {
        return @args;
    }
}

my $foo = Foo.new;

$p5.call('test', $foo);

$p5.run(q/
    done_testing;
/);

$p5.DESTROY;

# vim: ft=raku

