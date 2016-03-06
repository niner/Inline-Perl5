package TestPerl5Package;

use strict;
use warnings;

sub take_string {
    return (@_ == 2 and substr($_[0], 0, 16) eq 'TestPerl5Package' and $_[1] eq 'a string');
}

sub take_strings {
    return (@_ == 3 and substr($_[0], 0, 16) eq 'TestPerl5Package' and $_[1] eq 'first string' and $_[2] eq 'second string');
}

sub take_array {
    return (@_ == 2 and substr($_[0], 0, 16) eq 'TestPerl5Package' and ref $_[1] eq 'ARRAY' and $_[1][0] eq 'a string');
}

sub take_hash {
    return (@_ == 2 and substr($_[0], 0, 16) eq 'TestPerl5Package' and ref $_[1] eq 'HASH' and $_[1]{a} eq 'a string');
}

1;
