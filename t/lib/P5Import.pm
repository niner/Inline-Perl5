package P5Import;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(&p5_ok);

my $import_called = 0;

sub import {
    my ($self, @args) = @_;
    die scalar @args unless @args == 2;
    $import_called = 1;
    __PACKAGE__->export_to_level(1, $self, qw(p5_ok));
}

sub p5_ok {
    return $_[0] == 1;
}

sub import_called {
    return $import_called;
}

1;
