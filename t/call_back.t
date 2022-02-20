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
            @retval = $raku->test('Raku', 42);
            is_deeply \@retval, ['Raku', 42];
            @retval = $raku->test(['Raku', 42]);
            is_deeply \@retval, [['Raku', 42]];
            my $retval = $raku->test(['Raku', 42]);
            is_deeply $retval, ['Raku', 42];
            @retval = $raku->multi_value;
            is_deeply \@retval, [1, 2, [3, 4]];
            @retval = $raku->array;
            is_deeply \@retval, [1, 2, [3, 4]];
            $retval = $raku->array_ref;
            is_deeply $retval, [1, 2, [3, 4]];
            @retval = $raku->lists;
            is_deeply \@retval, [1, 2, [3, 4]];
        }
    };
/);

class Foo {
    method test(*@args) {
        @args
    }
    method multi_value() {
        1, 2, [3, 4]
    }
    method array() {
        [1, 2, [3, 4]]
    }
    method array_ref() {
        $[1, 2, [3, 4]]
    }
    method lists() is raw {
        my @l := 1, 2, [3, 4];
        @l
    }
}

my $foo = Foo.new;

$p5.call('test', $foo);

$p5.run(q/
    done_testing;
/);

$p5.DESTROY;

# vim: ft=raku

