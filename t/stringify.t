#!/usr/bin/env perl6

use v6;
use Inline::Perl5;
use Test;

class Foo {
    method Str {
        return 'Foo!';
    }
}

class Bar {
}

my $p5 = Inline::Perl5.new;
$p5.run(q:to/PERL5/);
    use strict;
    sub stringify {
        my ($obj) = @_;
        return "$obj";
    }
    sub test_eq {
        my ($obj) = @_;
        return $obj eq 'Foo!';
    }
    sub test_ne {
        my ($obj) = @_;
        return $obj ne 'Foo!';
    }
    sub test_lt {
        my ($obj) = @_;
        return $obj lt 'Fooz!';
    }
    sub test_gt {
        my ($obj) = @_;
        return $obj gt 'Fo!';
    }
    sub test_match {
        my ($obj, $str) = @_;
        return $obj =~ /$str/;
    }
    sub test_bool {
        my ($obj) = @_;
        return !!$obj;
    }
    sub test_not {
        my ($obj) = @_;
        return not $obj;
    }
    PERL5

is($p5.call('stringify', Foo.new), 'Foo!');
like($p5.call('stringify', Bar.new), /Bar\<\-?\d+\>/);
ok($p5.call('test_eq', Foo.new));
ok(not $p5.call('test_eq', Bar.new));
ok($p5.call('test_lt', Foo.new));
ok($p5.call('test_lt', Bar.new));
ok($p5.call('test_gt', Foo.new));
ok(not $p5.call('test_gt', Bar.new));
ok($p5.call('test_match', Foo.new, 'Foo'));
ok(not $p5.call('test_match', Foo.new, 'Bar'));
ok($p5.call('test_match', Bar.new, 'Bar'));
ok(not $p5.call('test_match', Bar.new, 'Foo'));
ok($p5.call('test_bool', Foo.new));
ok($p5.call('test_bool', Bar.new));
ok(not $p5.call('test_bool', Bar));
ok(not $p5.call('test_not', Foo.new));
ok(not $p5.call('test_not', Bar.new));
ok($p5.call('test_not', Bar));

done-testing;

# vim: ft=perl6
