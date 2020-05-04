package Excel::Writer::XLSX::Package::App;
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
    $self->{_part_names}    = [];
    $self->{_heading_pairs} = [];
    $self->{_properties}    = {};
    bless $self, $class;
    return $self;
}
sub _assemble_xml_file {
    my $self = shift;
    $self->xml_declaration;
    $self->_write_properties();
    $self->_write_application();
    $self->_write_doc_security();
    $self->_write_scale_crop();
    $self->_write_heading_pairs();
    $self->_write_titles_of_parts();
    $self->_write_manager();
    $self->_write_company();
    $self->_write_links_up_to_date();
    $self->_write_shared_doc();
    $self->_write_hyperlink_base();
    $self->_write_hyperlinks_changed();
    $self->_write_app_version();
    $self->xml_end_tag( 'Properties' );
    $self->xml_get_fh()->close();
}
sub _add_part_name {
    my $self      = shift;
    my $part_name = shift;
    push @{ $self->{_part_names} }, $part_name;
}
sub _add_heading_pair {
    my $self         = shift;
    my $heading_pair = shift;
    return unless $heading_pair->[1];  
    my @vector = (
        [ 'lpstr', $heading_pair->[0] ],    
        [ 'i4',    $heading_pair->[1] ],    
    );
    push @{ $self->{_heading_pairs} }, @vector;
}
sub _set_properties {
    my $self       = shift;
    my $properties = shift;
    $self->{_properties} = $properties;
}
sub _write_properties {
    my $self     = shift;
    my $schema   = 'http://schemas.openxmlformats.org/officeDocument/2006/';
    my $xmlns    = $schema . 'extended-properties';
    my $xmlns_vt = $schema . 'docPropsVTypes';
    my @attributes = (
        'xmlns'    => $xmlns,
        'xmlns:vt' => $xmlns_vt,
    );
    $self->xml_start_tag( 'Properties', @attributes );
}
sub _write_application {
    my $self = shift;
    my $data = 'Microsoft Excel';
    $self->xml_data_element( 'Application', $data );
}
sub _write_doc_security {
    my $self = shift;
    my $data = 0;
    $self->xml_data_element( 'DocSecurity', $data );
}
sub _write_scale_crop {
    my $self = shift;
    my $data = 'false';
    $self->xml_data_element( 'ScaleCrop', $data );
}
sub _write_heading_pairs {
    my $self = shift;
    $self->xml_start_tag( 'HeadingPairs' );
    $self->_write_vt_vector( 'variant', $self->{_heading_pairs} );
    $self->xml_end_tag( 'HeadingPairs' );
}
sub _write_titles_of_parts {
    my $self = shift;
    $self->xml_start_tag( 'TitlesOfParts' );
    my @parts_data;
    for my $part_name ( @{ $self->{_part_names} } ) {
        push @parts_data, [ 'lpstr', $part_name ];
    }
    $self->_write_vt_vector( 'lpstr', \@parts_data );
    $self->xml_end_tag( 'TitlesOfParts' );
}
sub _write_vt_vector {
    my $self      = shift;
    my $base_type = shift;
    my $data      = shift;
    my $size      = @$data;
    my @attributes = (
        'size'     => $size,
        'baseType' => $base_type,
    );
    $self->xml_start_tag( 'vt:vector', @attributes );
    for my $aref ( @$data ) {
        $self->xml_start_tag( 'vt:variant' ) if $base_type eq 'variant';
        $self->_write_vt_data( @$aref );
        $self->xml_end_tag( 'vt:variant' ) if $base_type eq 'variant';
    }
    $self->xml_end_tag( 'vt:vector' );
}
sub _write_vt_data {
    my $self = shift;
    my $type = shift;
    my $data = shift;
    $self->xml_data_element( "vt:$type", $data );
}
sub _write_company {
    my $self = shift;
    my $data = $self->{_properties}->{company} || '';
    $self->xml_data_element( 'Company', $data );
}
sub _write_manager {
    my $self = shift;
    my $data = $self->{_properties}->{manager};
    return unless $data;
    $self->xml_data_element( 'Manager', $data );
}
sub _write_links_up_to_date {
    my $self = shift;
    my $data = 'false';
    $self->xml_data_element( 'LinksUpToDate', $data );
}
sub _write_shared_doc {
    my $self = shift;
    my $data = 'false';
    $self->xml_data_element( 'SharedDoc', $data );
}
sub _write_hyperlink_base {
    my $self = shift;
    my $data = $self->{_properties}->{hyperlink_base};
    return unless $data;
    $self->xml_data_element( 'HyperlinkBase', $data );
}
sub _write_hyperlinks_changed {
    my $self = shift;
    my $data = 'false';
    $self->xml_data_element( 'HyperlinksChanged', $data );
}
sub _write_app_version {
    my $self = shift;
    my $data = '12.0000';
    $self->xml_data_element( 'AppVersion', $data );
}
1;
