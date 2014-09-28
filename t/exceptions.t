#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;
use NativeCall;

my $p5 = Inline::Perl5.new();
{
    try $p5.run(q/
        die "foo";
    /);
    ok 1, 'survived P5 die';
    ok $!.isa('X::AdHoc'), 'got an exception';
    ok $!.Str() ~~ m/foo/, 'exception message found';
}
{
    $p5.run(q/
        sub perish {
            die "foo";
        }
    /);
    try $p5.call('perish');
    ok 1, 'survived P5 die in function call';
    ok $!.isa('X::AdHoc'), 'got an exception from function call';
    ok $!.Str() ~~ m/foo/, 'exception message found from function call';
}
{
    $p5.run(q/
        package Foo;
        sub depart {
            die "foo";
        }
    /);
    my $foo = $p5.invoke('Foo', 'depart');
    CATCH {
        ok 1, 'survived P5 die in method call';
        when X::AdHoc {
            ok $_.isa('X::AdHoc'), 'got an exception from method call';
            ok $_.Str() ~~ m/foo/, 'exception message found from method call';
        }
    }
}
{
    $p5.run(q/
        package Foo;
        sub new {
            return bless {};
        }
        sub depart {
            die "foo";
        }
    /);
    my $foo = $p5.invoke('Foo', 'new');
    $foo.depart;
    CATCH {
        ok 1, 'survived P5 die in method call';
        when X::AdHoc {
            ok $_.isa('X::AdHoc'), 'got an exception from method call';
            ok $_.Str() ~~ m/foo/, 'exception message found from method call';
        }
    }
}
{
    $p5.run(q/
        package Foo;
        sub new {
            return bless {};
        }
    /);
    my $foo = $p5.invoke('Foo', 'new');
    $foo.non_existing;
    CATCH {
        ok 1, 'survived P5 missing method';
        when X::AdHoc {
            ok $_.isa('X::AdHoc'), 'got an exception from method call';
            ok $_.Str().index('Could not find method "non_existing" of "Foo" object') == 0, 'exception message found from method call';
        }
    }
}


class Foo {
    method depart {
        die "foo";
    }
}

$p5.run(q/
    sub test_foo {
        my ($foo) = @_;

        eval {
            $foo->depart;
        };
        if ($@) {
            return $@;
        }
    }
/);

is $p5.call('test_foo', Foo.new), 'foo';

{
    $p5.run(q/
        sub pass_through {
            my ($foo) = @_;
            $foo->depart;
        }
    /);
    $p5.call('pass_through', Foo.new);
    CATCH {
        ok 1, 'P6 exception made it through P5 code';
        when X::AdHoc {
            ok $_.isa('X::AdHoc'), 'got an exception from method call';
            ok $_.Str() ~~ m/foo/, 'exception message found from method call';
        }
    }
}

done;

# vim: ft=perl6
