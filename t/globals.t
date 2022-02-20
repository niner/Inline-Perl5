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

EVAL '$Foo::Bar::a = 1', :lang<Perl5>;
is $p5.global('$Foo::Bar::a'), 1;
is %*PERL5<$Foo::Bar::a>, 1;

use Data::Dumper:from<Perl5>;
EVAL '$Data::Dumper::Maxdepth = 1', :lang<Perl5>;
is $Data::Dumper::Maxdepth, 1;
$Data::Dumper::Maxdepth = 2;
is $Data::Dumper::Maxdepth, 2;
is EVAL('$Data::Dumper::Maxdepth', :lang<Perl5>), 2;

done-testing;

# vim: ft=raku
