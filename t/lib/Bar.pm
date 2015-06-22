package Bar;

use Moose;

sub test {
    my ($self) = @_;

    return $self->qux;
}

1;
