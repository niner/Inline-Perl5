#!/usr/bin/env perl6

use v6;
use Inline::Perl5;
use Test;
use NativeCall;

plan 2;

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
PERL5

class Bar {
    has $.parent is rw;

    method BUILD() {
        $.parent = $i.invoke('Foo', 'new');
    }

    method bar {
        return "Perl6";
    }

    Bar.^add_fallback(-> $, $ { True },
        method ($name) {
            -> \self, |args {
                $.parent.perl5.invoke($.parent.ptr, $name, self, args.list);
            }
        }
    );
}

is(Bar.new.foo, 'Moose!');
is(Bar.new.test, 'Perl6');

# vim: ft=perl6

