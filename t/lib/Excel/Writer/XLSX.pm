package Excel::Writer::XLSX;
use 5.008002;
use strict;
use warnings;
use Exporter;
use Excel::Writer::XLSX::Workbook;
our @ISA     = qw(Excel::Writer::XLSX::Workbook Exporter);
our $VERSION = '1.03';
sub new {
    my $class = shift;
    my $self  = Excel::Writer::XLSX::Workbook->new( @_ );
    bless $self, $class if defined $self;
    return $self;
}
1;
