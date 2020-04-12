use v6;
use lib:from<Perl5> <t/lib>;
use RakuBlock:from<Perl5>;
use Test;

is RakuBlock.new(:name<foo>).name, "foo";
is RakuBlock.get_me_a_foo, "foo";
my $r = RakuBlock.new(:name<friend>);
$r.set_greet("Hello");
is $r.greet_me, "Hello friend";

done-testing;
