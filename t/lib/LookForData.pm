package LookForData;
use strict;
use warnings;

sub return_data {
    my $handle = do { no strict 'refs'; \*{"main::DATA"} };
    (my $line = <$handle>) =~ s/\r?\n?$//;
    return $line;
}

1;
