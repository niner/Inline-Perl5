unit module Precomp;

use Data::Dumper:from<Perl5>;

our sub test-dumper() {
    Dumper($[1, 2])
}

our sub test-class() {
    Data::Dumper.new($[1, 2])
}

# vim: ft=perl6
