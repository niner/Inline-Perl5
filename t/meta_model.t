use Test;
use lib:from<Perl5> <t/lib>;
BEGIN {
    plan 3; # adjust the skip as well!

    unless EVAL 'eval { require Moose; 1};', :lang<Perl5> {
        skip('Perl 5 Moose module not available', 3);
        exit;
    }
}

use Foo:from<Perl5>;

my $p5obj = Foo.new;
is Foo.^name, 'Foo';
is $p5obj.^name, 'Foo';

is $p5obj.foo, 'Moose!';

done-testing;

# vim: ft=perl6
