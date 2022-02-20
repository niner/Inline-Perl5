#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

say "1..12";

my $p5 = Inline::Perl5.new();
say $p5.run: q:to<PERL>;
use 5.10.0;
$| = 1;

sub test {
    say "ok 1 - executing a parameterless function without return value";
    return;
}

sub test_int_params {
    if ($_[0] == 2 and $_[1] == 1) {
        say "ok 2 - int params";
    }
    else {
        say "not ok 2 - int params";
    }
    return;
}

sub test_str_params {
    if (@_ == 2 and $_[0] eq "Hello" and $_[1] eq "Perl 5") {
        say "ok 3 - str params";
    }
    else {
        say "not ok 3 - str params";
    }
    return;
}

sub test_int_retval {
    return 1;
}

sub test_int_retvals {
    return 3, 1, 2;
}

sub test_str_retval {
    return "Hello Raku!";
}

sub test_mixed_retvals {
    return ("Hello", "Perl", 6);
}

sub test_undef {
    my ($self, $undef) = @_;

    return (@_ == 2 and $self eq "main" and not defined $undef);
}

sub test_hash {
    my ($self, $h) = @_;

    return (
        ref $h eq "HASH"
        and %$h == 2
        and keys %$h == 2
        and exists $h->{a}
        and exists $h->{b}
        and $h->{a} == 2
        and ref $h->{b}
        and ref $h->{b} eq "HASH"
        and ref $h->{b}{c}
        and ref $h->{b}{c} eq "ARRAY"
        and @{ $h->{b}{c} } == 2
        and $h->{b}{c}[0] == 4
        and $h->{b}{c}[1] == 3
    );
}

sub test_foo {
    my ($self, $foo) = @_;
    return $foo->test;
}

package Foo;

sub new {
    my ($class, $val) = @_;
    return bless \$val, $class;
}

sub test {
    my ($self) = @_;
    return $$self;
}

sub sum {
    my ($self, $a, $b) = @_;
    return $a + $b;
}
PERL

$p5.call('test');
$p5.call('test_int_params', 2, 1);
$p5.call('test_str_params', 'Hello', 'Perl 5');
if ($p5.call('test_int_retval') == 1) {
    say "ok 4 - return one int";
}
else {
    say "not ok 4 - return one int";
}
my @retvals = $p5.call('test_int_retvals');
if (@retvals == 3 and @retvals[0] == 3 and @retvals[1] == 1 and @retvals[2] == 2) {
    say "ok 5 - return multiple ints";
}
else {
    say "not ok 5 - return multiple ints";
    say "    got: {@retvals} ({@retvals.elems} elems)";
    say "    expected: 3, 1, 2";
}
if ($p5.call('test_str_retval') eq 'Hello Raku!') {
    say "ok 6 - return one string";
}
else {
    say "not ok 6 - return one string";
}
@retvals = $p5.call('test_mixed_retvals');
if (@retvals == 3 and @retvals[0] eq 'Hello' and @retvals[1] eq 'Perl' and @retvals[2] == 6) {
    say "ok 7 - return mixed values";
}
else {
    say "not ok 7 - return mixed values";
    say "    got: {@retvals}";
    say "    expected: 'Hello', 'Perl', 6";
}

if ($p5.call('Foo::new', 'Foo', 1).test() == 1) {
    say "ok 8 - Perl 5 method call";
}
else {
    say "not ok 8 - Perl 5 method call";
}

if ($p5.call('Foo::new', 'Foo', 1).sum(3, 1) == 4) {
    say "ok 9 - Perl 5 method call with parameters";
}
else {
    say "not ok 9 - Perl 5 method call with parameters";
}

if ($p5.call('test_undef', 'main', Any) == 1) {
    say "ok 10 - Any converted to undef";
}
else {
    say "not ok 10 - Any converted to undef";
}

if ($p5.call('test_hash', 'main', {a => 2, b => {c => [4, 3]}}) == 1) {
    say "ok 11 - Passing hashes to Perl 5";
}
else {
    say "not ok 11 - Passing hashes to Perl 5";
}

if ($p5.call('test_foo', 'main', $p5.call('Foo::new', 'Foo', 6)) == 6) {
    say "ok 12 - Passing Perl 5 objects back from Raku";
}
else {
    say "not ok 12 - Passing Perl 5 objects back from Raku";
}

$p5.DESTROY;

# vim: ft=raku
