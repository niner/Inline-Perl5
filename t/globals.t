use Test;

use Inline::Perl5;
my $p5 = Inline::Perl5.default_perl5;

try EVAL 'die "test\n"', :lang<Perl5>;
is $p5.global('$@'), "test\n";
is %*PERL5<$@>, "test\n";

EVAL '@a = (1, 2)', :lang<Perl5>;
is $p5.global('@a'), [1, 2];
is %*PERL5<@a>, [1, 2];

EVAL '%a = (a => 1)', :lang<Perl5>;
is $p5.global('%a'), {a => 1};
is %*PERL5<%a>, {a => 1};

done-testing;

# vim: ft=perl6
