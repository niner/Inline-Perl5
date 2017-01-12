use strict;
use warnings;

package TestV6Directly;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub search {
    1
}

use v6-inline;

method foo() {
    self.search;
}
