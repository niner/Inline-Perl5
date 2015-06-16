#!/usr/bin/env perl6
use v6;
use LibraryMake;

shell('perl -e "use v5.18;"')
    or die "\nPerl 5 version requirement not met\n";

shell('perl -MFilter::Simple -e ""')
    or die "\nPlease install the Filter::Simple Perl 5 module!\n";

my %vars = get-vars('.');
process-makefile('.', %vars);
make('.', 'lib');

# vim: ft=perl6
