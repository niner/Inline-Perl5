package Foo::Bar::TestV6;

sub new {
    my ($class, $foo) = @_;
    return bless {foo => $foo};
}

sub foo {
    my ($self) = @_;
    return $self->{foo};
}

use v6-inline;

has $.name;

our sub greet($me) {
    return "hello $me";
}

method hello {
    return "hello $.foo $.name";
}
