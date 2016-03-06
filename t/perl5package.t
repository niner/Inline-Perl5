#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;
BEGIN EVAL 'use lib qw(t/lib);', :lang<Perl5>;

use TestPerl5Package:from<Perl5>;

# test installed method wrappers
ok(TestPerl5Package.take_string('a string'));
ok(TestPerl5Package.take_strings('first string', 'second string'));
ok(TestPerl5Package.take_array($['a string']));
ok(TestPerl5Package.take_hash(${a => 'a string'}));

use TestPerl5Package::Sub:from<Perl5>;

# test FALLBACK
ok(TestPerl5Package::Sub.take_string('a string'));
ok(TestPerl5Package::Sub.take_strings('first string', 'second string'));
ok(TestPerl5Package::Sub.take_array($['a string']));
ok(TestPerl5Package::Sub.take_hash(${a => 'a string'}));

done-testing;

# vim: ft=perl6
