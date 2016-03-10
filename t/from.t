#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;
BEGIN EVAL 'use lib qw(t/lib);', :lang<Perl5>;

use P5Import:from<Perl5> <tests 2>;

eval-dies-ok "use P5ModuleVersion:from<Perl5>:ver<2.1>;";

is(P5Import::p5_ok(1), 1);
is(p5_ok(1), 1, "importing subs works");
is(p5_ok2(1), 1, "importing manually created subs works");
is(P5Import::import_called(), 1);

done-testing;

# vim: ft=perl6
