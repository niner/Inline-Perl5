use Data::Dumper:from<Perl5>;
#use TestPrecomp;

sub dumper() is export {
    Dumper([1, 2])
    #Data::Dumper.new([1, 2]);
}

#vim: ft=perl6
