#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;

BEGIN {
    %*ENV<PERL6LIB> = 'lib:blib/lib';
}

plan 2;

my $ipc = CompUnit.new('lib/Inline/Perl5.pm6');
my $already-precompiled = $ipc.precomp-path.IO.e;

if not $already-precompiled {
    $ipc.precomp;
}

my $first = CompUnit.new('t/Precomp/First.pm6');
my $second = CompUnit.new('t/Precomp/Second.pm6');

ok $first.precomp;
ok $second.precomp;

# clean up
sub rmpp($cu) {
    unlink($cu.precomp-path);
}

rmpp($first);
rmpp($second);

if not $already-precompiled {
    rmpp($ipc);
}

# vim: ft=perl6
