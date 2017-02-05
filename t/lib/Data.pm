use lib:from<Perl5> 't/lib';
use LookForData:from<Perl5>;

sub look_for_data() is export {
    return LookForData::return_data;
}

=finish
trailing data found in DATA handle

# vim: ft=perl6
