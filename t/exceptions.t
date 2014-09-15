#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;
use NativeCall;

plan 6;

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
