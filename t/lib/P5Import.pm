package P5Import;

sub import {
    my ($self, @args) = @_;
    die scalar @args unless @args == 2;
}

sub ok {
    return $_[0] == 1;
}

1;
