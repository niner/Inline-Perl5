#!/usr/bin/env perl6

use v6;
use Test;

use lib:from<Perl5> 't/lib';
use Shadow:from<Perl5>;

my constant @methods = <list end say print note put split>;

plan @methods.elems * 2;

for @methods -> $name {
    is(Shadow."$name"(), $name);
}

my $shadow = Shadow.new;
for @methods -> $name {
    is($shadow."$name"(), $name);
}

# vim: ft=raku
