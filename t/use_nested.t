use Test;
use lib 't/lib';
use lib:from<Perl5> 't/lib';
use A:from<Perl5>;
use B;

ok($B::a);
ok(A.new);

done-testing;
