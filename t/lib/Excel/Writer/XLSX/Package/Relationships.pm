package Excel::Writer::XLSX::Package::Relationships;
use 5.008002;
use strict;
use warnings;
use Carp;
use Excel::Writer::XLSX::Package::XMLwriter;
our @ISA     = qw(Excel::Writer::XLSX::Package::XMLwriter);
our $VERSION = '1.03';
our $schema_root     = 'http://schemas.openxmlformats.org';
our $package_schema  = $schema_root . '/package/2006/relationships';
our $document_schema = $schema_root . '/officeDocument/2006/relationships';
sub new {
    my $class = shift;
    my $fh    = shift;
    my $self  = Excel::Writer::XLSX::Package::XMLwriter->new( $fh );
    $self->{_rels} = [];
    $self->{_id}   = 1;
    bless $self, $class;
    return $self;
}
sub _assemble_xml_file {
    my $self = shift;
    $self->xml_declaration;
    $self->_write_relationships();
}
sub _add_document_relationship {
    my $self        = shift;
    my $type        = shift;
    my $target      = shift;
    my $target_mode = shift;
    $type   = $document_schema . $type;
    push @{ $self->{_rels} }, [ $type, $target, $target_mode ];
}
sub _add_package_relationship {
    my $self   = shift;
    my $type   = shift;
    my $target = shift;
    $type   = $package_schema . $type;
    push @{ $self->{_rels} }, [ $type, $target ];
}
sub _add_ms_package_relationship {
    my $self   = shift;
    my $type   = shift;
    my $target = shift;
    my $schema = 'http://schemas.microsoft.com/office/2006/relationships';
    $type   = $schema . $type;
    push @{ $self->{_rels} }, [ $type, $target ];
}
sub _add_worksheet_relationship {
    my $self        = shift;
    my $type        = shift;
    my $target      = shift;
    my $target_mode = shift;
    $type   = $document_schema . $type;
    push @{ $self->{_rels} }, [ $type, $target, $target_mode ];
}
sub _write_relationships {
    my $self = shift;
    my @attributes = ( 'xmlns' => $package_schema, );
    $self->xml_start_tag( 'Relationships', @attributes );
    for my $rel ( @{ $self->{_rels} } ) {
        $self->_write_relationship( @$rel );
    }
    $self->xml_end_tag( 'Relationships' );
    $self->xml_get_fh()->close();
}
sub _write_relationship {
    my $self        = shift;
    my $type        = shift;
    my $target      = shift;
    my $target_mode = shift;
    my @attributes = (
        'Id'     => 'rId' . $self->{_id}++,
        'Type'   => $type,
        'Target' => $target,
    );
    push @attributes, ( 'TargetMode' => $target_mode ) if $target_mode;
    $self->xml_empty_tag( 'Relationship', @attributes );
}
1;
