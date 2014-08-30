#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

my $i = p5_init_perl();
$i.init_callbacks();
$i.run(q/
    use Test::More;

    sub test {
        my ($self, $perl6) = @_;
        my @retval = $perl6->test('Perl6');
        is_deeply \@retval, ['Perl6'];
        my @retval = $perl6->test('Perl', 6);
        is_deeply \@retval, ['Perl', 6];
    };
/);

class Foo {
    method test(*@args) {
        return @args;
    }
}

my $foo = Foo.new;

$i.call('test', 'main', $foo);

$i.run(q/
    done_testing;
/);

$i.DESTROY;

# vim: ft=perl6

