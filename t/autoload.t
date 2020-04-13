#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

use Test;

my $p5 = Inline::Perl5.new;

$p5.run(q:heredoc/PERL5/);
    package Foo;
    sub new {
        return bless {};
    }
    sub AUTOLOAD {
        return 'autoload';
    }
    PERL5

is($p5.invoke('Foo', 'foo'), 'autoload', 'AUTOLOAD for package method');
is($p5.invoke('Foo', 'new').bar, 'autoload', 'AUTOLOAD for method');

done-testing;

# vim: ft=perl6
