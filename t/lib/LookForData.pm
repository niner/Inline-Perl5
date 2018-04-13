package LookForData;
use strict;
use warnings;

sub return_data {
    my $handle = do { no strict 'refs'; \*{"main::DATA"} };
    my $line = <$handle>;
    chomp $line;
    return $line;
}

1;
