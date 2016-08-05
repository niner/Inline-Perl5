package Foo;

use Moose;

has foo => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Moose!',
);

sub test {
    my ($self) = @_;

    return $self->bar;
}

sub bar {
    return "Perl5";
}

sub test_inherited {
    my ($self) = @_;

    return $self->baz;
}

sub baz {
    return "Perl5";
}

sub call_list {
    my ($self) = @_;

    return $self->list(1, 2, 3);
}

sub list {
    return 'list';
}

sub call_end {
    my ($self) = @_;

    return $self->end(1, 2, 3);
}

sub end {
    return 'end';
}

sub say {
    return 'say';
}

sub print {
    return 'print';
}

sub note {
    return 'note';
}

sub put {
    return 'put';
}

sub split {
    return 'split';
}

1;
