use v6;
use lib 't/lib';
use Inline::Perl5::ClassHOW;
use UseRakuBlock;
use Test;

ok UseRakuBlock.new(:name<foo>);
ok UseRakuBlock.new(:name<foo>).^mro[1].HOW.^isa(Inline::Perl5::ClassHOW);
is UseRakuBlock.new(:name<foo>).^can('name')[0](UseRakuBlock.new(:name<foo>)), 'foo';
is UseRakuBlock.new(:name<foo>).name, "foo";
is UseRakuBlock.get_me_a_foo, "foo";
my $r = UseRakuBlock.new(:name<friend>);
is UseRakuBlock.^mro[1].get_me_a_foo, "foo", 'base class functional even when not loaded directly';
$r.set_greet("Hello");
is $r.greet_me, "Hello friend";

done-testing;
