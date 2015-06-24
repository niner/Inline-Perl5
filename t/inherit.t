#!/usr/bin/env perl6

use v6;
use Test;

BEGIN {
    plan 6; # adjust the skip as well!

    EVAL 'use lib qw(t/lib);', :lang<perl5>;
    unless EVAL 'eval { require Moose; 1};', :lang<perl5> {
        skip('Perl 5 Moose module not available', 6);
        exit;
    }
}

use Foo:from<Perl5>;
use Bar:from<Perl5>;

class P6Bar is Foo {
    method bar {
        return "Perl6";
    }

}

is(P6Bar.new.test, 'Perl6');
is(P6Bar.new.test_inherited, 'Perl5');
is(P6Bar.new.foo, 'Moose!');
is(P6Bar.new(foo => 'custom').foo, 'custom');

class Baz is Foo {
    method bar {
        return "Perl6!";
    }

}

is(Baz.new.test, 'Perl6!');

class Qux is Bar {
    method qux {
        return "Perl6!!";
    }

}

is(Qux.new.test, 'Perl6!!');

# vim: ft=perl6

