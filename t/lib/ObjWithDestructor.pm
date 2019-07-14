package ObjWithDestructor;
use Devel::Peek;

our $count = 0;

sub new {
    my ($class, $run) = @_;

    $count++;

    return bless {a => 1, run => $run}, $class;
}

sub test {
    my ($self) = @_;
    return $self->{a};
}

sub call_test {
    my ($self) = @_;
    return $self->test;
}

our $destructor_runs = 0;
our %destructor_runs;

sub DESTROY {
    my ($self) = @_;
    $count--;
    $destructor_runs++;
    $destructor_runs{$self->{run}}++;
}

1;
