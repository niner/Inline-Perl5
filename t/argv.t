#!/usr/bin/env perl6

use v6;
use Test;

BEGIN @*ARGS.push: 'test1'; # must be before creating first Inline::Perl5 object

is(EVAL('@ARGV[0]', :lang<Perl5>), 'test1');

done-testing;

# vim: ft=perl6
