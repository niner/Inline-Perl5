#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

my $p5;
BEGIN {
    $p5 = Inline::Perl5.new();
    $p5.use('Test::More', 'tests', 5);
    $p5.call('Test::More::ok', 1, 'use loaded the module');
}

use Test::More:from<Perl5>;

BEGIN {
    Test::More::ok(1, 'package functions work');
}

use Data::Dumper:from<Perl5>;

my $dumper = Data::Dumper.new([1, 2]);
Test::More::is($dumper.Dump.Str, "\$VAR1 = 1;\n \$VAR2 = 2;\n", 'constructor works');
Test::More::is(Data::Dumper.Dump([1, 2]).Str, "\$VAR1 = 1;\n \$VAR2 = 2;\n", 'package methods work');

# Should be safe to load a module more than once.
$p5.use('Test::More');
$p5.use('Test::More');

Test::More::pass('loaded module more than once');

# Only the first interpreter should create a Perl 6 package
{
    my @p5 = Inline::Perl5.new xx 10;
    $_.use('File::Temp') for @p5;
    CATCH {
        when X::Inline::Perl5::NoMultiplicity {
        }
    }
}

# vim: ft=perl6
