#!/usr/bin/env perl6
use v6;
use LibraryMake;

shell('perl -e "use v5.18;"')
    or die "Perl 5 version requirement not met";

my %vars = get-vars('.');
process-makefile('.', %vars);
make('.', 'lib');

# vim: ft=perl6
