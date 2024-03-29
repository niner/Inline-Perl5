use Test;
use lib:from<Perl5> <t/lib>;
BEGIN {
    plan 23; # adjust the skip as well!

    unless EVAL 'eval { require Moose; 1};', :lang<Perl5> {
        skip('Perl 5 Moose module not available', 23);
        exit;
    }
}

use Foo:from<Perl5>;

my $p5obj = Foo.new;
is Foo.^name, 'Foo';
is $p5obj.^name, 'Foo';

is $p5obj.foo, 'Moose!';

is($p5obj.context, 'list');
is($p5obj.context(1), 'list');
is($p5obj.context(1, 2), 'list');
is($p5obj.context(Any), 'list');
is($p5obj.context(Scalar), 'scalar');
is($p5obj.context(Scalar, 1), 'scalar');
is($p5obj.context(Scalar, 1, 2), 'scalar');
is($p5obj.context(Scalar, Any), 'scalar');
is($p5obj.context(:named), 'list');
is($p5obj.context(1, :named), 'list');
is($p5obj.context(1, 2, :named), 'list');
is($p5obj.context(Any, :named), 'list');
is($p5obj.context(Scalar, :named), 'scalar');
is($p5obj.context(Scalar, 1, :named), 'scalar');
is($p5obj.context(Scalar, 1, 2, :named), 'scalar');
is($p5obj.context(Scalar, Any, :named), 'scalar');

is("$p5obj", 'overloaded string');
is(+$p5obj, 42);

ok $p5obj.^methods>>.name.Set<context>:exists;
ok $p5obj.^method_table.Map<context>:exists;

done-testing;

# vim: ft=raku
