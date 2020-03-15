use v6;
use lib:from<Perl5> <t/lib>;
use RakuBlock:from<Perl5>;
use Test;

#is RakuBlock.hello_from_raku, "hello from raku";
is RakuBlock.hello_from_perl5, "hello from perl5";

done-testing;
