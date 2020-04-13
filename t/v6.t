#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;

use lib:from<Perl5> <t/lib>;
use Foo::Bar::TestV6:from<Perl5>;
use Foo::Bar::TestV6Sub:from<Perl5>;

is(Foo::Bar::TestV6::greet('world'), 'hello world', 'greet works');
is(Foo::Bar::TestV6.new('nice').set_name('world').hello, 'hello nice world', 'hello works');
is(
    EVAL(q/Foo::Bar::TestV6->create(foo => 'bar')->set_name('world')/, :lang<Perl5>).hello,
    'hello bar world',
);
is(Foo::Bar::TestV6.new.context, 'array');
is(Foo::Bar::TestV6.new.test_scalar_context, 'scalar');
is(Foo::Bar::TestV6.new.test_array_context, 'array');
is(Foo::Bar::TestV6.new.test_call_context, 'array');
is(Foo::Bar::TestV6.new.test_isa, 1);
is(Foo::Bar::TestV6.new('bar').test_can, 1, "can finds the base class' methods");
is(Foo::Bar::TestV6.new('bar').test_can_subclass, 2, "can finds the subclass' methods");
is(Foo::Bar::TestV6.new('bar').test_package_can, 1, "can finds the base class' methods via package");
is(Foo::Bar::TestV6.new('bar').test_package_can_subclass, 2, "can finds the subclass' methods via package");
is(Foo::Bar::TestV6.new('bar').foo, 'bar');
is(Foo::Bar::TestV6.new('bar').get_foo, 'bar');
is(Foo::Bar::TestV6.new('bar').get_foo_indirect, 'bar');
is(Foo::Bar::TestV6.new.test_breaking_encapsulation(Foo::Bar::TestV6.new('bar')), 'bar');
is(Foo::Bar::TestV6.new.check_attrs, <Test1 Test2>);

is(
    EVAL(q/Foo::Bar::TestV6Sub->create(foo => 'bar')->set_name('world')/, :lang<Perl5>).hello,
    'hello bar world',
);
ok(
    EVAL(q/Foo::Bar::TestV6Sub->create(foo => 'bar')->set_name('world')->isa('Foo::Bar::TestV6Sub')/, :lang<Perl5>),
    'P5 subclass of P6 extended P5 class isa P5 subclass',
) or diag (
    EVAL(q/ref Foo::Bar::TestV6Sub->create(foo => 'bar')/, :lang<Perl5>);
);

use nqp;
nqp::force_gc;

ok(%*PERL5<$Foo::Bar::TestV6Base::destructor_runs>, "Destructor ran");

use TestV6Directly:from<Perl5>;

ok(TestV6Directly.new.foo);

done-testing;

# vim: ft=perl6
