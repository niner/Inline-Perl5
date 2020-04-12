package RakuBlock;
use v5.10.0;

my @arr;

raku {
    has $.name;

    method greet_me() {
        "{self<greet>} $!name"
    }
}

$arr[0]; # declaration survived

sub set_greet {
    my ($self, $bar) = @_;

    $self->{greet} = $bar;
}

sub get_me_a_foo {
    RakuBlock->new(v6::named(name => "foo"))->name
}

1;
