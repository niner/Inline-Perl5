#!/usr/bin/env perl6
use v6;
use LibraryMake;

shell('perl -e "use v5.18;"')
    or die "\nPerl 5 version requirement not met\n";

shell('perl -MFilter::Simple -e ""')
    or die "\nPlease install the Filter::Simple Perl 5 module!\n";

my %vars = get-vars('.');
%vars<p5helper> = %vars<DESTDIR>.IO.child('resources').child('libraries')
    .child($*VM.platform-library-name('p5helper'.IO)).Str;
%vars<perlopts> = run(<perl -MExtUtils::Embed -e ccopts -e ldopts>, :out).out.lines.join('');
mkdir "resources" unless "resources".IO.e;
mkdir "resources/libraries" unless "resources/libraries".IO.e;
process-makefile('.', %vars);
shell(%vars<MAKE>);

# vim: ft=perl6
