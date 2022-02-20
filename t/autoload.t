#!/usr/bin/env perl6

use v6;
use Inline::Perl5;

use Test;

my $p5 = Inline::Perl5.default_perl5;

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

use lib:from<Perl5> 't/lib';
use HasAutoload:from<Perl5>;
is(HasAutoload.bar, 'autoload');

done-testing;

# vim: ft=raku
