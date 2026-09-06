package Excel::Writer::XLSX::Package::ContentTypes;
use 5.008002;
use strict;
use warnings;
use Carp;
use Excel::Writer::XLSX::Package::XMLwriter;
our @ISA     = qw(Excel::Writer::XLSX::Package::XMLwriter);
our $VERSION = '1.03';
my $app_package  = 'application/vnd.openxmlformats-package.';
my $app_document = 'application/vnd.openxmlformats-officedocument.';
our @defaults = (
    [ 'rels', $app_package . 'relationships+xml' ],
    [ 'xml',  'application/xml' ],
);
our @overrides = (
    [ '/docProps/app.xml',    $app_document . 'extended-properties+xml' ],
    [ '/docProps/core.xml',   $app_package . 'core-properties+xml' ],
    [ '/xl/styles.xml',       $app_document . 'spreadsheetml.styles+xml' ],
    [ '/xl/theme/theme1.xml', $app_document . 'theme+xml' ],
    [ '/xl/workbook.xml',     $app_document . 'spreadsheetml.sheet.main+xml' ],
);
sub new {
    my $class = shift;
    my $fh    = shift;
    my $self  = Excel::Writer::XLSX::Package::XMLwriter->new( $fh );
    $self->{_defaults}  = [@defaults];
    $self->{_overrides} = [@overrides];
    bless $self, $class;
    return $self;
}
sub _assemble_xml_file {
    my $self = shift;
    $self->xml_declaration;
    $self->_write_types();
    $self->_write_defaults();
    $self->_write_overrides();
    $self->xml_end_tag( 'Types' );
    $self->xml_get_fh()->close();
}
sub _add_default {
    my $self         = shift;
    my $part_name    = shift;
    my $content_type = shift;
    push @{ $self->{_defaults} }, [ $part_name, $content_type ];
}
sub _add_override {
    my $self         = shift;
    my $part_name    = shift;
    my $content_type = shift;
    push @{ $self->{_overrides} }, [ $part_name, $content_type ];
}
sub _add_worksheet_name {
    my $self           = shift;
    my $worksheet_name = shift;
    $worksheet_name = "/xl/worksheets/$worksheet_name.xml";
    $self->_add_override( $worksheet_name,
        $app_document . 'spreadsheetml.worksheet+xml' );
}
sub _add_chartsheet_name {
    my $self            = shift;
    my $chartsheet_name = shift;
    $chartsheet_name = "/xl/chartsheets/$chartsheet_name.xml";
    $self->_add_override( $chartsheet_name,
        $app_document . 'spreadsheetml.chartsheet+xml' );
}
sub _add_chart_name {
    my $self       = shift;
    my $chart_name = shift;
    $chart_name = "/xl/charts/$chart_name.xml";
    $self->_add_override( $chart_name, $app_document . 'drawingml.chart+xml' );
}
sub _add_drawing_name {
    my $self         = shift;
    my $drawing_name = shift;
    $drawing_name = "/xl/drawings/$drawing_name.xml";
    $self->_add_override( $drawing_name, $app_document . 'drawing+xml' );
}
sub _add_vml_name {
    my $self = shift;
    $self->_add_default( 'vml', $app_document . 'vmlDrawing' );
}
sub _add_comment_name {
    my $self         = shift;
    my $comment_name = shift;
    $comment_name = "/xl/$comment_name.xml";
    $self->_add_override( $comment_name,
        $app_document . 'spreadsheetml.comments+xml' );
}
sub _add_shared_strings {
    my $self = shift;
    $self->_add_override( '/xl/sharedStrings.xml',
        $app_document . 'spreadsheetml.sharedStrings+xml' );
}
sub _add_calc_chain {
    my $self = shift;
    $self->_add_override( '/xl/calcChain.xml',
        $app_document . 'spreadsheetml.calcChain+xml' );
}
sub _add_image_types {
    my $self  = shift;
    my %types = @_;
    for my $type ( keys %types ) {
        $self->_add_default( $type, 'image/' . $type );
    }
}
sub _add_table_name {
    my $self       = shift;
    my $table_name = shift;
    $table_name = "/xl/tables/$table_name.xml";
    $self->_add_override( $table_name,
        $app_document . 'spreadsheetml.table+xml' );
}
sub _add_vba_project {
    my $self = shift;
    for my $aref ( @{ $self->{_overrides} } ) {
        if ( $aref->[0] eq '/xl/workbook.xml' ) {
            $aref->[1] = 'application/vnd.ms-excel.sheet.macroEnabled.main+xml';
        }
    }
    $self->_add_default( 'bin', 'application/vnd.ms-office.vbaProject' );
}
sub _add_custom_properties {
    my $self   = shift;
    my $custom = "/docProps/custom.xml";
    $self->_add_override( $custom, $app_document . 'custom-properties+xml' );
}
sub _write_defaults {
    my $self = shift;
    for my $aref ( @{ $self->{_defaults} } ) {
        $self->xml_empty_tag(
            'Default',
            'Extension',   $aref->[0],
            'ContentType', $aref->[1] );
    }
}
sub _write_overrides {
    my $self = shift;
    for my $aref ( @{ $self->{_overrides} } ) {
        $self->xml_empty_tag(
            'Override',
            'PartName',    $aref->[0],
            'ContentType', $aref->[1] );
    }
}
sub _write_types {
    my $self  = shift;
    my $xmlns = 'http://schemas.openxmlformats.org/package/2006/content-types';
    my @attributes = ( 'xmlns' => $xmlns, );
    $self->xml_start_tag( 'Types', @attributes );
}
sub _write_default {
    my $self         = shift;
    my $extension    = shift;
    my $content_type = shift;
    my @attributes = (
        'Extension'   => $extension,
        'ContentType' => $content_type,
    );
    $self->xml_empty_tag( 'Default', @attributes );
}
sub _write_override {
    my $self         = shift;
    my $part_name    = shift;
    my $content_type = shift;
    my $writer       = $self;
    my @attributes = (
        'PartName'    => $part_name,
        'ContentType' => $content_type,
    );
    $self->xml_empty_tag( 'Override', @attributes );
}
1;
