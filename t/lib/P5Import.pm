package P5Import;

my $import_called = 0;

sub import {
    my ($self, @args) = @_;
    die scalar @args unless @args == 2;
    $import_called = 1;
}

sub ok {
    return $_[0] == 1;
}

sub import_called {
    return $import_called;
}

1;
