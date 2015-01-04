#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

my $p5;
BEGIN {
    $p5 = Inline::Perl5.new();
    $p5.use('Test::More', 'tests', 3);
    $p5.call('Test::More::ok', 1);
}

BEGIN {
    Test::More.ok(1);
    $p5.use('Data::Dumper');
}

my $dumper = Data::Dumper.new([1, 2]);
Test::More.is($dumper.Dump.Str, "\$VAR1 = 1;\n \$VAR2 = 2;\n");

# vim: ft=perl6
