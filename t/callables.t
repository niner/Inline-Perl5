#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;

plan 4;

my $p5 = Inline::Perl5.new();

$p5.run(q/
    use strict;
    use warnings;

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

    sub return_array_checker {
        return sub {
            my ($array) = @_;
            return scalar @$array;
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
is($p5.call('return_array_checker')([1, 2, 3].item), 3);
my &callable := $p5.call('return_code', 'Foo');

# vim: ft=perl6
