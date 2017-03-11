#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;

plan 20;

BEGIN my $p5 = Inline::Perl5.new();
$p5.run(q:heredoc/PERL5/);
    sub identity {
        return $_[0]
    };
    PERL5

class Foo {
}

for (
    '',
    'abcö',
    'äbc'.encode('latin-1'),
    24,
    2.4.Num,
#    [1, 2], #TODO - will return as Perl5Array
    { a => 1, b => 2},
    Any,
    \('foo'),
    Foo.new,
) -> $obj {
    is-deeply $p5.call('identity', $obj), $obj, "Can round-trip " ~ $obj.^name;
}

$p5.run(q/
    use utf8;
    sub check_utf8 {
        my ($str) = @_;

        return $str eq 'Töst';
    };
    sub check_null {
        my ($str) = @_;

        return $str eq "foo\0bar";
    }
/);

ok($p5.call('check_utf8', 'Töst'), 'UTF-8 string recognized in Perl 5');
ok($p5.call('check_null', "foo\0bar"), 'Null safe conversion of Str from P6 to P5');

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

$p5.run(q/
    sub is_string_ref {
        my ($ref) = @_;
        return (ref $ref eq 'SCALAR' and $$ref eq 'foo');
    }
/);

ok($p5.call('is_string_ref', \('foo')));

$p5.run(q/
    sub is_hash_ref {
        my ($ref) = @_;
        return (ref $ref eq 'HASH' and %$ref == 1 and $ref->{a} == 1);
    }
/);

ok($p5.call('is_hash_ref', Map.new((a => 1)).item), 'Map arrives as a HashRef');

$p5.run(q/
    use warnings;
    sub test_named {
        my (%params) = @_;
        return $params{a} + $params{b};
    }
    package Foo;
    sub new {
        return bless {};
    }
    sub test_named {
        my ($self, %params) = @_;
        return $params{a} + $params{b};
    }
/);

is($p5.call('test_named', a => 1, b => 2), 3);
is($p5.invoke('Foo', 'test_named', a => 1, b => 2), 3);
is($p5.invoke('Foo', 'new').test_named('a', 1, 'b', 2), 3, 'positional args on object method');
is($p5.invoke('Foo', 'new').test_named(a => 1, b => 2), 3, 'named args on object method');

class Bar does Inline::Perl5::Perl5Parent['Foo', $p5] {
}

is(Bar.new.test_named(a => 1, b => 2), 3, 'named args on parent object method');

$p5.DESTROY;

# vim: ft=perl6
