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

sub get_foo {
    my ($self) = @_;
    return $self->foo;
}

sub get_foo_indirect {
    my ($self) = @_;
    return $self->fetch_foo;
}

sub create {
    my ($class, %args) = @_;
    return v6::extend($class, $class->new($args{foo}), [], \%args);
}

sub context {
    return wantarray ? 'array' : 'scalar';
}

sub test_scalar_context {
    my ($self) = @_;
    my $context = $self->context;
    return $context;
}

sub test_array_context {
    my ($self) = @_;
    my @context = $self->context;
    return @context;
}

sub test_call_context {
    my ($self) = @_;
    my $context = $self->call_context;
    return $context;
}

sub test_isa {
    my ($self) = @_;

    return $self->isa(__PACKAGE__);
}

# yes, this happens in real code :/
sub test_breaking_encapsulation {
    my ($self, $obj) = @_;
    return $obj->{foo};
}


use v6-inline;

has $.name;

our sub greet($me) {
    return "hello $me";
}

method hello {
    return "hello $.foo $.name";
}

method call_context {
    return self.context;
}

method fetch_foo() {
    return self.foo;
}
