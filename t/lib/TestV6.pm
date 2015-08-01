package Foo::Bar::TestV6;

use strict;
use warnings;

sub new {
    my ($class, $foo) = @_;
    return bless {foo => $foo};
}

sub foo {
    my ($self) = @_;
    return $self->{foo};
}

sub create {
    my ($class, %args) = @_;
    return v6::extend($class, $class->new($args{foo}), [], \%args);
}

use v6-inline;

has $.name;

our sub greet($me) {
    return "hello $me";
}

method hello {
    return "hello $.foo $.name";
}
