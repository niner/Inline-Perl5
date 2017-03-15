use Test;
use lib 't/lib';
use lib:from<Perl5> 't/lib';
use D:from<Perl5>;

ok(so('foo' ~~ D.regex_1));

# Make sure Perl 5 regex semantics are applied.
ok(so ("foo\n" ~~ D.regex_2));

done-testing;
