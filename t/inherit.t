#!/usr/bin/env perl6

use v6;
use Test;

BEGIN {
    plan 14; # adjust the skip as well!

    EVAL 'use lib qw(t/lib);', :lang<Perl5>;
    unless EVAL 'eval { require Moose; 1};', :lang<Perl5> {
        skip('Perl 5 Moose module not available', 14);
        exit;
    }
}

use Foo:from<Perl5>;
use Bar:from<Perl5>;

is(Foo.new(foo => 'custom').foo, 'custom');

class P6Bar is Foo {
    method bar {
        return "Perl6";
    }

}

is(P6Bar.new.test, 'Perl6');
is(P6Bar.new.test_inherited, 'Perl5');
is(P6Bar.new.foo, 'Moose!');
is(P6Bar.new(foo => 'custom').foo, 'custom');
is(P6Bar.new.call_end, 'end', 'Any methods not interfering with inheritance');
is(P6Bar.new.call_list, 'list', 'Any methods not interfering with inheritance');
is(P6Bar.new.say, 'say', 'say method not interfering with inheritance');
is(P6Bar.new.print, 'print', 'print method not interfering with inheritance');
is(P6Bar.new.note, 'note', 'print method not interfering with inheritance');
is(P6Bar.new.put, 'put', 'print method not interfering with inheritance');
is(P6Bar.new.split, 'split', 'print method not interfering with inheritance');

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

