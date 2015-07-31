#!/usr/bin/env perl6

use v6;
use Test;

plan 2;

use lib:from<Perl5> <t/lib>;
use TestV6:from<Perl5>;

is(Foo::Bar::TestV6::greet('world'), 'hello world');
is(Foo::Bar::TestV6.new('nice', name => 'world').hello, 'hello nice world');

# vim: ft=perl6
