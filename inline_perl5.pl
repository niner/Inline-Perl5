#!/home/nine/install/rakudo/install/bin/perl6

use v6;
use lib '.';
use Inline::Perl5;

my $i = init_perl();
say $i.run('
$| = 1;
print "Hello world from Perl ";
5');

# vim: ft=perl6
