#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;
use NativeCall;

plan 3;

my $p5 = Inline::Perl5.new();

$p5.run(q/
    sub call_something {
        my ($something, $param) = @_;

        return $something->($param);
    }

    sub return_code {
        my ($name) = @_;
        return sub {
            my ($param) = @_;
            return "$name $param";
        }
    }
/);

sub something($suffix) {
    return 'Perl ' ~ $suffix;
}

is $p5.call('call_something', &something, 6), 'Perl 6';
is $p5.call('return_code', 'Perl')(5), 'Perl 5';
my $sub = $p5.call('return_code', 'Foo');
is $p5.call('call_something', $sub, 1), 'Foo 1';

# vim: ft=perl6
