#!/usr/bin/env perl6
use v6;
use LibraryMake;

my %vars = get-vars('.');
process-makefile('.', %vars);
make('.', 'lib');

# vim: ft=perl6
