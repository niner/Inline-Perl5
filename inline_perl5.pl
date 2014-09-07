#!/usr/bin/env perl6

use v6;
use lib 'lib';
use Inline::Perl5;

my $i = Inline::Perl5.new();
say $i.run('
use 5.10.0;

STDOUT->autoflush(1);

sub test {
    say scalar localtime;
}

print "Hello world from Perl ";
5');

print 'It is now ';
$i.call('main::test');

$i.DESTROY;

# vim: ft=perl6
