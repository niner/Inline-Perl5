use v6.c;

use Test;
use MONKEY-SEE-NO-EVAL;

plan 20;

my &hash-creator = EVAL q:to<PERL5>, :lang<Perl5>;
    sub {
        my ($hash_filler) = @_;
        my $hash = {
            a => 1,
            b => 2,
        };
        $hash_filler->($hash);
        return $hash;
    }
    PERL5

my $hash = hash-creator(sub (%hash) {
    is(%hash.elems, 2, 'Perl5Hash.elems works');
    for %hash {
        ok($_.key);
        ok($_.value);
    }
    for %hash.list {
        ok($_.key);
        ok($_.value);
    }
    for %hash.pairs {
        ok($_.key);
        ok($_.value);
    }
    for %hash.kv -> $k, $v {
        ok($k);
        ok($v);
    }
    ok(%hash.Bool);
    is(%hash<b>, 2);
    %hash<c> = 3;
    %hash<d> = 4;
});

is($hash, {a => 1, b => 2, c => 3, d => 4});

# vim: ft=raku
