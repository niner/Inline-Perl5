#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;

plan 11;

my $p5 = Inline::Perl5.new();
$p5.run(q:heredoc/PERL5/);
    sub identity {
        return $_[0]
    };
    PERL5

class Foo {
}

for ('abcö', Buf.new('äbc'.encode('latin-1')), 24, 2.4.Num, [1, 2], { a => 1, b => 2}, Any, Foo.new) -> $obj {
    is_deeply $p5.call('identity', $obj), $obj, "Can round-trip " ~ $obj.^name;
}

$p5.run(q/
    use utf8;
    sub check_utf8 {
        my ($str) = @_;

        return $str eq 'Töst';
    };
/);

ok($p5.call('check_utf8', 'Töst'), 'UTF-8 string recognized in Perl 5');

$p5.run(q/
    use utf8;
    use Encode qw(decode);
    sub check_latin1 {
        my ($str) = @_;

        return decode('latin-1', $str) eq 'Töst';
    };
/);

ok($p5.call('check_latin1', 'Töst'.encode('latin-1')), 'latin-1 works in Perl 5');

$p5.run(q/
    sub is_two_point_five {
        return $_[0] == 2.5;
    }
/);

ok($p5.call('is_two_point_five', Num.new(2.5)));

$p5.DESTROY;

# vim: ft=perl6
