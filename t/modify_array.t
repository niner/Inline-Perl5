use v6.c;

use Test;
use MONKEY-SEE-NO-EVAL;

plan 33;

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
    for @array {
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
    is(@array.Capture[1], 2);
});

is($array, [1, 2, 3, 4]);
is $array.pop, 4;
is($array, [1, 2, 3]);
$array.push: 4;
is($array, [1, 2, 3, 4]);
is $array.shift, 1;
is($array, [2, 3, 4]);
$array.unshift: 1;
is($array, [1, 2, 3, 4]);

is($array.splice(2), [3, 4]);
is $array, [1, 2];

$array.push: 3;
$array.push: 4;
is($array.splice(2, 1), [3]);
is $array, [1, 2, 4];

$array.splice(2, 0, [3]);
is($array.splice, [1, 2, 3, 4]);
is $array, [];

$array.splice: 0, 0, [1, 2, 3, 4];
is $array, [1, 2, 3, 4];

$array.splice: 1, 2, [7];
is $array, [1, 7, 4];

$array.splice: 1, 1, [2, 3, 5, 6];
is $array, [1, 2, 3, 5, 6, 4];

$array.splice: 3, 0, $array.splice: 4, 1;

ok(not EVAL("[1, 2]", :lang<Perl5>).perl.starts-with('$'), 'array not containerized');

# vim: ft=perl6
