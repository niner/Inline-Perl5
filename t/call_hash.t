use v6;

use Test;

use Inline::Perl5;

use lib:from<Perl5> <t/lib>;
use TakesHash:from<Perl5>;

is(TakesHash.give_hash(:foo<bar>), 'bar');

done-testing;
