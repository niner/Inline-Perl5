#!/usr/bin/env perl6

use v6;
use Test;
use Inline::Perl5;
BEGIN {
    my $p5 = Inline::Perl5.new;
    $p5.run('use lib qw(t/lib);');
}

use P5Import:from<Perl5> <tests 2>;

eval-dies-ok "use P5ModuleVersion:from<Perl5>:ver<2.1>;";

is(P5Import::ok(1), 1);

done;

# vim: ft=perl6
