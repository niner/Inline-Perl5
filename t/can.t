#!/usr/bin/env perl6

use v6;
use Inline::Perl5;
use Test;

my $p5 = Inline::Perl5.new();
$p5.run(q:heredoc/PERL5/);
    sub test_can_positive {
        my ($p6obj) = @_;
        return $p6obj->can('foo');
    }
    sub test_can_negative {
        my ($p6obj) = @_;
        return $p6obj->can('bar');
    }
    sub call_foo_via_can {
        my ($p6obj) = @_;
        return $p6obj->can('foo')->($p6obj);
    }
PERL5

class Foo {
    method foo {
        return 'foo';
    }
}

my $foo = Foo.new;
ok($p5.call('test_can_positive', $foo));
ok(not $p5.call('test_can_negative', $foo));
is($p5.call('call_foo_via_can', $foo), 'foo');

done;

# vim: ft=perl6
