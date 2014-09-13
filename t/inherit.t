#!/usr/bin/env perl6

use v6;
use Inline::Perl5;
use Test;
use NativeCall;

plan 3;

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

class Bar {
    has $.parent is rw;

    method BUILD() {
        $.parent = $i.invoke('Foo', 'new');
        $i.rebless($.parent);
    }

    method bar {
        return "Perl6";
    }

    Bar.^add_fallback(-> $, $ { True },
        method ($name) {
            -> \self, |args {
                $.parent.perl5.invoke('Foo', $.parent.ptr, $name, self, args.list);
            }
        }
    );
}

is(Bar.new.test, 'Perl6');
is(Bar.new.test_inherited, 'Perl5');
is(Bar.new.foo, 'Moose!');

# vim: ft=perl6

