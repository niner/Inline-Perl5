#!/usr/bin/env perl6

use v6;
use Inline::Perl5;
use Test;
use NativeCall;

plan 5;

my $p5 = Inline::Perl5.new();

my $has_moose =  $p5.run('eval { require Moose; 1};');
if !$has_moose {
    skip('Perl 5 Moose module not available',2);
    exit;
}

$p5.run(q:heredoc/PERL5/);

package Foo;

use Moose;

has foo => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Moose!',
);

sub test {
    my ($self) = @_;

    return $self->bar;
}

sub bar {
    return "Perl5";
}

sub test_inherited {
    my ($self) = @_;

    return $self->baz;
}

sub baz {
    return "Perl5";
}

package Bar;

use Moose;

sub test {
    my ($self) = @_;

    return $self->qux;
}

PERL5

class Bar does Inline::Perl5::Perl5Parent['Foo'] {
    method bar {
        return "Perl6";
    }

}

is(Bar.new(perl5 => $p5).test, 'Perl6');
is(Bar.new(perl5 => $p5).test_inherited, 'Perl5');
is(Bar.new(perl5 => $p5).foo, 'Moose!');

class Baz does Inline::Perl5::Perl5Parent['Foo'] {
    method bar {
        return "Perl6!";
    }

}

is(Baz.new(perl5 => $p5).test, 'Perl6!');

class Qux does Inline::Perl5::Perl5Parent['Bar'] {
    method qux {
        return "Perl6!!";
    }

}

is(Qux.new(perl5 => $p5).test, 'Perl6!!');

# vim: ft=perl6

