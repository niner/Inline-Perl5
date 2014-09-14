#!/usr/bin/env perl6

use v6;
use lib 'lib';
use Inline::Perl5;

my $p5 = Inline::Perl5.new();
say $p5.run('
use 5.10.0;

STDOUT->autoflush(1);

sub test {
    say scalar localtime;
}

print "Hello world from Perl ";
5');

print 'It is now ';
$p5.call('main::test');

$p5.DESTROY;

# vim: ft=perl6
