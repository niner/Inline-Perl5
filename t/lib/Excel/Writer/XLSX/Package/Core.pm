package Excel::Writer::XLSX::Package::Core;
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
    $self->{_properties} = {};
    $self->{_createtime}  = [ gmtime() ];
    bless $self, $class;
    return $self;
}
sub _assemble_xml_file {
    my $self = shift;
    $self->xml_declaration;
    $self->_write_cp_core_properties();
    $self->_write_dc_title();
    $self->_write_dc_subject();
    $self->_write_dc_creator();
    $self->_write_cp_keywords();
    $self->_write_dc_description();
    $self->_write_cp_last_modified_by();
    $self->_write_dcterms_created();
    $self->_write_dcterms_modified();
    $self->_write_cp_category();
    $self->_write_cp_content_status();
    $self->xml_end_tag( 'cp:coreProperties' );
    $self->xml_get_fh()->close();
}
sub _set_properties {
    my $self       = shift;
    my $properties = shift;
    $self->{_properties} = $properties;
}
sub _datetime_to_iso8601_date {
    my $self = shift;
    my $gmtime = shift || $self->{_createtime};
    my ( $seconds, $minutes, $hours, $day, $month, $year ) = @$gmtime;
    $month++;
    $year += 1900;
    my $date = sprintf "%4d-%02d-%02dT%02d:%02d:%02dZ", $year, $month, $day,
      $hours, $minutes, $seconds;
}
sub _write_cp_core_properties {
    my $self = shift;
    my $xmlns_cp =
      'http://schemas.openxmlformats.org/package/2006/metadata/core-properties';
    my $xmlns_dc       = 'http://purl.org/dc/elements/1.1/';
    my $xmlns_dcterms  = 'http://purl.org/dc/terms/';
    my $xmlns_dcmitype = 'http://purl.org/dc/dcmitype/';
    my $xmlns_xsi      = 'http://www.w3.org/2001/XMLSchema-instance';
    my @attributes = (
        'xmlns:cp'       => $xmlns_cp,
        'xmlns:dc'       => $xmlns_dc,
        'xmlns:dcterms'  => $xmlns_dcterms,
        'xmlns:dcmitype' => $xmlns_dcmitype,
        'xmlns:xsi'      => $xmlns_xsi,
    );
    $self->xml_start_tag( 'cp:coreProperties', @attributes );
}
sub _write_dc_creator {
    my $self = shift;
    my $data = $self->{_properties}->{author} || '';
    $self->xml_data_element( 'dc:creator', $data );
}
sub _write_cp_last_modified_by {
    my $self = shift;
    my $data = $self->{_properties}->{author} || '';
    $self->xml_data_element( 'cp:lastModifiedBy', $data );
}
sub _write_dcterms_created {
    my $self     = shift;
    my $date     = $self->{_properties}->{created};
    my $xsi_type = 'dcterms:W3CDTF';
    $date = $self->_datetime_to_iso8601_date( $date );
    my @attributes = ( 'xsi:type' => $xsi_type, );
    $self->xml_data_element( 'dcterms:created', $date, @attributes );
}
sub _write_dcterms_modified {
    my $self     = shift;
    my $date     = $self->{_properties}->{created};
    my $xsi_type = 'dcterms:W3CDTF';
    $date = $self->_datetime_to_iso8601_date( $date );
    my @attributes = ( 'xsi:type' => $xsi_type, );
    $self->xml_data_element( 'dcterms:modified', $date, @attributes );
}
sub _write_dc_title {
    my $self = shift;
    my $data = $self->{_properties}->{title};
    return unless $data;
    $self->xml_data_element( 'dc:title', $data );
}
sub _write_dc_subject {
    my $self = shift;
    my $data = $self->{_properties}->{subject};
    return unless $data;
    $self->xml_data_element( 'dc:subject', $data );
}
sub _write_cp_keywords {
    my $self = shift;
    my $data = $self->{_properties}->{keywords};
    return unless $data;
    $self->xml_data_element( 'cp:keywords', $data );
}
sub _write_dc_description {
    my $self = shift;
    my $data = $self->{_properties}->{comments};
    return unless $data;
    $self->xml_data_element( 'dc:description', $data );
}
sub _write_cp_category {
    my $self = shift;
    my $data = $self->{_properties}->{category};
    return unless $data;
    $self->xml_data_element( 'cp:category', $data );
}
sub _write_cp_content_status {
    my $self = shift;
    my $data = $self->{_properties}->{status};
    return unless $data;
    $self->xml_data_element( 'cp:contentStatus', $data );
}
1;
