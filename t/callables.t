#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;
use NativeCall;

plan 1;

my $p5 = Inline::Perl5.new();

$p5.run(q/
    sub call_something {
        my ($something, $param) = @_;

        return $something->($param);
    }
/);

sub something($suffix) {
    return 'Perl ' ~ $suffix;
}

is $p5.call('call_something', &something, 6), 'Perl 6';

# vim: ft=perl6
