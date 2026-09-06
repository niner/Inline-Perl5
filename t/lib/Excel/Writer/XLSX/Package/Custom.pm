package Excel::Writer::XLSX::Package::Custom;
use 5.008002;
use strict;
use warnings;
use Carp;
use Excel::Writer::XLSX::Package::XMLwriter;
our @ISA     = qw(Excel::Writer::XLSX::Package::XMLwriter);
our $VERSION = '1.03';
sub new {
    my $class = shift;
    my $fh    = shift;
    my $self  = Excel::Writer::XLSX::Package::XMLwriter->new( $fh );
    $self->{_properties} = [];
    $self->{_pid}        = 1;
    bless $self, $class;
    return $self;
}
sub _assemble_xml_file {
    my $self = shift;
    $self->xml_declaration;
    $self->_write_properties();
    $self->xml_end_tag( 'Properties' );
    $self->xml_get_fh()->close();
}
sub _set_properties {
    my $self       = shift;
    my $properties = shift;
    $self->{_properties} = $properties;
}
sub _write_properties {
    my $self     = shift;
    my $schema   = 'http://schemas.openxmlformats.org/officeDocument/2006/';
    my $xmlns    = $schema . 'custom-properties';
    my $xmlns_vt = $schema . 'docPropsVTypes';
    my @attributes = (
        'xmlns'    => $xmlns,
        'xmlns:vt' => $xmlns_vt,
    );
    $self->xml_start_tag( 'Properties', @attributes );
    for my $property ( @{ $self->{_properties} } ) {
        $self->_write_property( $property );
    }
}
sub _write_property {
    my $self     = shift;
    my $property = shift;
    my $fmtid    = '{D5CDD505-2E9C-101B-9397-08002B2CF9AE}';
    $self->{_pid}++;
    my ( $name, $value, $type ) = @$property;
    my @attributes = (
        'fmtid' => $fmtid,
        'pid'   => $self->{_pid},
        'name'  => $name,
    );
    $self->xml_start_tag( 'property', @attributes );
    if ( $type eq 'date' ) {
        $self->_write_vt_filetime( $value );
    }
    elsif ( $type eq 'number' ) {
        $self->_write_vt_r8( $value );
    }
    elsif ( $type eq 'number_int' ) {
        $self->_write_vt_i4( $value );
    }
    elsif ( $type eq 'bool' ) {
        $self->_write_vt_bool( $value );
    }
    else {
        $self->_write_vt_lpwstr( $value );
    }
    $self->xml_end_tag( 'property' );
}
sub _write_vt_lpwstr {
    my $self = shift;
    my $data = shift;
    $self->xml_data_element( 'vt:lpwstr', $data );
}
sub _write_vt_i4 {
    my $self = shift;
    my $data = shift;
    $self->xml_data_element( 'vt:i4', $data );
}
sub _write_vt_r8 {
    my $self = shift;
    my $data = shift;
    $self->xml_data_element( 'vt:r8', $data );
}
sub _write_vt_bool {
    my $self = shift;
    my $data = shift;
    if ( $data ) {
        $data = 'true';
    }
    else {
        $data = 'false';
    }
    $self->xml_data_element( 'vt:bool', $data );
}
sub _write_vt_filetime {
    my $self = shift;
    my $data = shift;
    $self->xml_data_element( 'vt:filetime', $data );
}
1;
