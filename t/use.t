#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

my $p5;
BEGIN {
    $p5 = Inline::Perl5.new();
    $p5.use('Test::More', 'tests', 4);
    $p5.call('Test::More::ok', 1, 'use loaded the module');
}

BEGIN {
    Test::More::ok(1, 'package functions work');
    $p5.use('Data::Dumper');
}

my $dumper = Data::Dumper.new([1, 2]);
Test::More::is($dumper.Dump.Str, "\$VAR1 = 1;\n \$VAR2 = 2;\n", 'constructor works');
Test::More::is(Data::Dumper.Dump([1, 2]).Str, "\$VAR1 = 1;\n \$VAR2 = 2;\n", 'package methods work');

# vim: ft=perl6
