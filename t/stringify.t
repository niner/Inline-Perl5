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
    sub stringify {
        my ($obj) = @_;
        return "$obj";
    }
    PERL5

is($p5.call('stringify', Foo.new), 'Foo!');
like($p5.call('stringify', Bar.new), /Bar\<\-?\d+\>/);

done-testing;

# vim: ft=perl6
