use lib 't/lib';
use Test;
use Data;

is look_for_data(), "trailing data found in DATA handle\n";

done-testing;
