#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

my $p5;
BEGIN {
    $p5 = Inline::Perl5.new();
    $p5.use('Test::More', 'tests', 2);
    $p5.call('Test::More::ok', 1);
    $p5.use('Data::Dumper');
}
my $dumper = Data::Dumper.new(perl5 => $p5, [1, 2]);
$p5.call('Test::More::is', $dumper.Dump.Str, "\$VAR1 = 1;\n \$VAR2 = 2;\n");

# vim: ft=perl6
