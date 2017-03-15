use Test;
use lib 't/lib';
use lib:from<Perl5> 't/lib';
use C:from<Perl5>;

todo('Not yet implemented', 5);
is(C.blessed_hash<foo>, 42);
is(C.blessed_array[1], 42);
is($(C.blessed_scalar), 42);
ok("foo\n" ~~ C.blessed_regex);
is(C.blessed_sub, 42);

# Not sure how to do this.
# … C.blessed_typeglob …

done-testing;

