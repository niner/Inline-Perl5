#!/usr/bin/env perl6

use v6;
use Inline::Perl5;
use Test;
use NativeCall;

plan 2;

my $i = Inline::Perl5.new();
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
PERL5

class Bar {
    has $.parent is rw;

    method BUILD() {
        $.parent = $i.call('new', 'Foo');
    }

    method bar {
        return "Perl6";
    }

    Bar.^add_fallback(-> $, $ { True },
        method ($name) {
            -> \self, |args {
                $.parent.perl5.invoke($name, $.parent.ptr, self, args.list);
            }
        }
    );
}

is(Bar.new.foo, 'Moose!');
is(Bar.new.test, 'Perl6');

# vim: ft=perl6

