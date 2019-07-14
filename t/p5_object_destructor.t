#!/usr/bin/env perl6

use v6;
use Test;
use lib:from<Perl5> <t/lib>;
use ObjWithDestructor:from<Perl5>;

# create new objects until the GC kicks in and destroys at least one of them
# this will loop endlessly if we leak all objects

plan 20;

{

my $i;

sub is($a, $b, $desc) {
    die $desc unless $a eqv $b;
}

$ObjWithDestructor::destructor_runs = 0;
$ObjWithDestructor::count = 0;
$i = 0;
until %*PERL5<%ObjWithDestructor::destructor_runs><1> {
    {
        my $obj = ObjWithDestructor.new(1);
        is $obj.test(), 1, 'obj survives birth' for ^5;
    }

    for 1 .. 100 { Blob.allocate(10) }

    use nqp;
    nqp::force_gc;

    last if $i++ >= 10;
}

ok(%*PERL5<%ObjWithDestructor::destructor_runs><1>, 'at least one destructor ran');
ok($ObjWithDestructor::count < $i, 'at least one destructor ran');

$ObjWithDestructor::destructor_runs = 0;
$ObjWithDestructor::count = 0;
$i = 0;
until %*PERL5<%ObjWithDestructor::destructor_runs><2> {
    {
        my $obj = ObjWithDestructor.new(2);
        is $obj.test(1), 1, 'obj survives birth' for ^5;
    }

    for 1 .. 100 { Blob.allocate(10) }

    use nqp;
    nqp::force_gc;

    last if $i++ >= 10000;
}

ok(%*PERL5<%ObjWithDestructor::destructor_runs><2>, 'at least one destructor ran after call with 1 arg');
ok($ObjWithDestructor::count < $i, 'at least one destructor ran after call with 1 arg');

$ObjWithDestructor::destructor_runs = 0;
$ObjWithDestructor::count = 0;
$i = 0;
until %*PERL5<%ObjWithDestructor::destructor_runs><3> {
    {
        my $obj = ObjWithDestructor.new(3);
        is $obj.test(1, 1), 1, 'obj survives birth' for ^5;
    }

    for 1 .. 100 { Blob.allocate(10) }

    use nqp;
    nqp::force_gc;

    last if $i++ >= 10000;
}

ok(%*PERL5<%ObjWithDestructor::destructor_runs><3>, 'at least one destructor ran after call with 2 args');
ok($ObjWithDestructor::count < $i, 'at least one destructor ran after call with 2 args');

$ObjWithDestructor::destructor_runs = 0;
$ObjWithDestructor::count = 0;
$i = 0;
until %*PERL5<%ObjWithDestructor::destructor_runs><4> {
    {
        my $obj = ObjWithDestructor.new(4);
        is $obj.test(1, 1, 1), 1, 'obj survives birth' for ^5;
    }

    for 1 .. 100 { Blob.allocate(10) }

    use nqp;
    nqp::force_gc;

    last if $i++ >= 10000;
}

ok(%*PERL5<%ObjWithDestructor::destructor_runs><4>, 'at least one destructor ran after call with 3 args');
ok($ObjWithDestructor::count < $i, 'at least one destructor ran after call with 3 args');

class Foo is ObjWithDestructor { };

$ObjWithDestructor::destructor_runs = 0;
$ObjWithDestructor::count = 0;
$i = 0;
until %*PERL5<%ObjWithDestructor::destructor_runs><5> {
    {
        my $foo = Foo.new(5);
        is $foo.call_test(), 1, 'obj survives' for ^2;
    }

    for 1 .. 100 { Blob.allocate(10) }

    use nqp;
    nqp::force_gc;

    last if $i++ >= 10000;
}

ok(%*PERL5<%ObjWithDestructor::destructor_runs><5>, 'at least one destructor ran after nested subclass call');
ok($ObjWithDestructor::count < $i, 'at least one destructor ran after nested subclass call');

$ObjWithDestructor::destructor_runs = 0;
$ObjWithDestructor::count = 0;
$i = 0;
until %*PERL5<%ObjWithDestructor::destructor_runs><6> {
    {
        my $foo = Foo.new(6);
        is $foo.test(1), 1, 'obj survives' for ^5;
    }

    for 1 .. 100 { Blob.allocate(10) }

    use nqp;
    nqp::force_gc;

    last if $i++ >= 10000;
}

ok(%*PERL5<%ObjWithDestructor::destructor_runs><6>, 'at least one destructor ran after nested subclass call with 1 arg');
ok($ObjWithDestructor::count < $i, 'at least one destructor ran after nested subclass call with 1 arg');

$ObjWithDestructor::destructor_runs = 0;
$ObjWithDestructor::count = 0;
$i = 0;
until %*PERL5<%ObjWithDestructor::destructor_runs><7> {
    {
        my $foo = Foo.new(7);
        is $foo.call_test(1,2), 1, 'obj survives' for ^5;
    }

    for 1 .. 100 { Blob.allocate(10) }

    use nqp;
    nqp::force_gc;

    last if $i++ >= 10000;
}

ok(%*PERL5<%ObjWithDestructor::destructor_runs><7>, 'at least one destructor ran after nested subclass call with 2 args');
ok($ObjWithDestructor::count < $i, 'at least one destructor ran after nested subclass call with 2 args');

$ObjWithDestructor::destructor_runs = 0;
$ObjWithDestructor::count = 0;
$i = 0;
until %*PERL5<%ObjWithDestructor::destructor_runs><8> {
    {
        my $foo = Foo.new(8);
        is $foo.call_test(1,2,3), 1, 'obj survives' for ^5;
    }

    for 1 .. 100 { Blob.allocate(10) }

    use nqp;
    nqp::force_gc;

    last if $i++ >= 10000;
}

ok(%*PERL5<%ObjWithDestructor::destructor_runs><8>, 'at least one destructor ran after nested subclass call with 3 args');
ok($ObjWithDestructor::count < $i, 'at least one destructor ran after nested subclass call with 3 args');

{
    my $foo = Foo.new(0);

    $ObjWithDestructor::destructor_runs = 0;
    $ObjWithDestructor::count = 0;
    $i = 0;
    until %*PERL5<%ObjWithDestructor::destructor_runs><9> {
        {
            my $param = Foo.new(9);
            is $foo.call_test($param), 1, 'obj survives' for ^5;
        }

        for 1 .. 100 { Blob.allocate(10) }

        use nqp;
        nqp::force_gc;

        last if $i++ >= 10000;
    }

    ok(%*PERL5<%ObjWithDestructor::destructor_runs><9>, 'at least one destructor ran after nested subclass call with object arg');
    ok($ObjWithDestructor::count < $i, 'at least one destructor ran after nested subclass call with object arg');

    $ObjWithDestructor::destructor_runs = 0;
    $ObjWithDestructor::count = 0;
    $i = 0;
    until %*PERL5<%ObjWithDestructor::destructor_runs><10> {
        {
            my $param = Foo.new(10);
            is $foo.call_test($param, $param), 1, 'obj survives' for ^5;
            is $param.test, 1, 'obj passed as arg survived intact' for ^2;
        }

        for 1 .. 100 { Blob.allocate(10) }

        use nqp;
        nqp::force_gc;

        last if $i++ >= 10000;
    }

    ok(
        %*PERL5<%ObjWithDestructor::destructor_runs><10>,
        'at least one destructor ran after nested subclass call with object passed as arg twice'
    );
    ok(
        $ObjWithDestructor::count < $i,
        'at least one destructor ran after nested subclass call with object passed as arg twice'
    );
}

}

#done-testing;

# vim: ft=perl6
