#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;

my $p5 = Inline::Perl5.new();

$p5.run('
    package SpecialArray;
    sub TIEARRAY {
        my ($class) = @_;
        my $self;
        return bless \$self, $class;
    }
    sub FETCH {
        my ($self) = @_;
        return "Tied!";
    }
    sub FETCHSIZE {
        my ($self) = @_;
        return 2;
    }
    package main;
    tie my @arr, SpecialArray;
    sub get_array {
        \@arr;
    }
');

my $array = $p5.call('get_array');
#my $array = $p5.test_tie();

is($array[0], 'Tied!');
is($array[1], 'Tied!');
is($array.elems, 2);

$p5.DESTROY;

done-testing;

# vim: ft=perl6
