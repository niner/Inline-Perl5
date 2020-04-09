use strict;
use warnings;

package Foo::Bar::TestV6Base;

our $counter = 0;

my @objects;

sub create {
    my ($class, %args) = @_;
    $counter++;
    my $self = $class->new($args{foo});
    #push @objects, $self;
    $self;
}

our $destructor_runs = 0;

sub DESTROY {
    my ($self) = @_;
    $counter--;
    $destructor_runs++;
}

package Foo::Bar::TestV6;

use strict;
use warnings;

use base qw(Foo::Bar::TestV6Base);

sub new {
    my ($class, $foo) = @_;
    $Foo::Bar::TestV6Base::counter++;
    my $self = {foo => $foo};
    return bless $self, $class;
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

sub return_1 {
    return 1;
}

sub test_can {
    my ($self) = @_;

    die 'can returns positive result for non-existing method' if $self->can('non-existing');
    return $self->can('return_1')->($self);
}

sub test_can_subclass {
    my ($self) = @_;

    return $self->can('return_2')->($self);
}

sub test_package_can {
    my ($self) = @_;

    my $class = ref $self;
    die 'can returns positive result for non-existing method' if $class->can('non-existing');
    return $class->can('return_1')->($self);
}

sub test_package_can_subclass {
    my ($self) = @_;

    my $class = ref $self;
    return $class->can('return_2')->($self);
}

# yes, this happens in real code :/
sub test_breaking_encapsulation {
    my ($self, $obj) = @_;
    return $obj->{foo};
}

my @attributes;
sub MODIFY_CODE_ATTRIBUTES {
    my ($class, $code, @attrs) = @_;

    my @bad = grep { $_ ne 'Test1' and $_ ne 'Test2' } @attrs;
    push @attributes, @attrs;

    return @bad;
}

sub FETCH_CODE_ATTRIBUTES {
    return @attributes;
}

sub check_attrs {
    my ($self) = @_;

    use attributes();
    return attributes::get(\&hasattrs);
}

use v6-inline;

has $.name;

our sub greet($me) {
    return "hello $me";
}

method set_name($name) {
    $!name = $name;
    self
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

method return_2() {
    return 2;
}

multi trait_mod:<is>(Routine $declarand, :@p5attrs!) {
    unless $declarand.does(Inline::Perl5::Attributes) {
        $declarand does Inline::Perl5::Attributes;
    }
    $declarand.attributes.append(@p5attrs);
}

method hasattrs() is p5attrs['Test1', 'Test2'] {
    return 1;
}
