#!/usr/bin/env perl6

use v6;
use Inline::Perl5;
use Test;
use NativeCall;

plan 4;

my $i = Inline::Perl5.new();

my $has_moose =  $i.run('eval { require Moose; 1};');
if !$has_moose {
    skip('Perl 5 Moose module not available',2);
    exit;
}

$i.run(q:heredoc/PERL5/);

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
PERL5

class Bar does Inline::Perl5::Perl5Parent['Foo'] {
    method bar {
        return "Perl6";
    }

}

is(Bar.new(perl5 => $i).test, 'Perl6');
is(Bar.new(perl5 => $i).test_inherited, 'Perl5');
is(Bar.new(perl5 => $i).foo, 'Moose!');

class Baz does Inline::Perl5::Perl5Parent['Foo'] {
    method bar {
        return "Perl6!";
    }

}

is(Baz.new(perl5 => $i).test, 'Perl6!');

# vim: ft=perl6

