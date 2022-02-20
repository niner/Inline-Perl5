use Test;
#
# DATA handle is only initialized if Inline::Perl5 is loaded at compile time of a compilation unit
use Data::Dumper:from<Perl5>;

is EVAL('<DATA>', :lang<Perl5>), "Azərbaycan trailing data found in DATA handle\n";

done-testing;

=finish
Azərbaycan trailing data found in DATA handle

# vim: ft=raku
