use v6.c;

use Test;
use MONKEY-SEE-NO-EVAL;

plan 16;

my &array-creator = EVAL q:to<PERL5>, :lang<Perl5>;
    sub {
        my ($array_filler) = @_;
        my $array = [ 1, 2 ];
        $array_filler->($array);
        return $array;
    }
    PERL5

my $array = array-creator(sub (@array) {
    is(@array.elems, 2, 'Perl5Hash.elems works');
    for @array {
        ok($_);
    }
    for @array.list {
        ok($_);
    }
    for @array.pairs {
        ok($_.key.defined);
        ok($_.value);
    }
    for @array.kv -> $k, $v {
        ok($k.defined);
        ok($v);
    }
    ok(@array.Bool);
    is(@array[1], 2);
    @array[2] = 3;
    @array[3] = 4;
});

is($array, [1, 2, 3, 4]);

# vim: ft=perl6
