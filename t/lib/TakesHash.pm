package TakesHash;

use strict;
use warnings;

sub give_hash {
    my ($class, %args) = @_;

    return $args{foo};
}

1;
