package Excel::Writer::XLSX::Package::Table;
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
    bless $self, $class;
    return $self;
}
sub _assemble_xml_file {
    my $self = shift;
    $self->xml_declaration;
    $self->_write_table();
    $self->_write_auto_filter();
    $self->_write_table_columns();
    $self->_write_table_style_info();
    $self->xml_end_tag( 'table' );
    $self->xml_get_fh()->close();
}
sub _set_properties {
    my $self       = shift;
    my $properties = shift;
    $self->{_properties} = $properties;
}
sub _write_table {
    my $self             = shift;
    my $schema           = 'http://schemas.openxmlformats.org/';
    my $xmlns            = $schema . 'spreadsheetml/2006/main';
    my $id               = $self->{_properties}->{_id};
    my $name             = $self->{_properties}->{_name};
    my $display_name     = $self->{_properties}->{_name};
    my $ref              = $self->{_properties}->{_range};
    my $totals_row_shown = $self->{_properties}->{_totals_row_shown};
    my $header_row_count = $self->{_properties}->{_header_row_count};
    my @attributes = (
        'xmlns'       => $xmlns,
        'id'          => $id,
        'name'        => $name,
        'displayName' => $display_name,
        'ref'         => $ref,
    );
    push @attributes, ( 'headerRowCount' => 0 ) if !$header_row_count;
    if ( $totals_row_shown ) {
        push @attributes, ( 'totalsRowCount' => 1 );
    }
    else {
        push @attributes, ( 'totalsRowShown' => 0 );
    }
    $self->xml_start_tag( 'table', @attributes );
}
sub _write_auto_filter {
    my $self       = shift;
    my $autofilter = $self->{_properties}->{_autofilter};
    return unless $autofilter;
    my @attributes = ( 'ref' => $autofilter, );
    $self->xml_empty_tag( 'autoFilter', @attributes );
}
sub _write_table_columns {
    my $self    = shift;
    my @columns = @{ $self->{_properties}->{_columns} };
    my $count = scalar @columns;
    my @attributes = ( 'count' => $count, );
    $self->xml_start_tag( 'tableColumns', @attributes );
    for my $col_data ( @columns ) {
        $self->_write_table_column( $col_data );
    }
    $self->xml_end_tag( 'tableColumns' );
}
sub _write_table_column {
    my $self     = shift;
    my $col_data = shift;
    my @attributes = (
        'id'   => $col_data->{_id},
        'name' => $col_data->{_name},
    );
    if ( $col_data->{_total_string} ) {
        push @attributes, ( totalsRowLabel => $col_data->{_total_string} );
    }
    elsif ( $col_data->{_total_function} ) {
        push @attributes, ( totalsRowFunction => $col_data->{_total_function} );
    }
    if ( defined $col_data->{_format} ) {
        push @attributes, ( dataDxfId => $col_data->{_format} );
    }
    if ( $col_data->{_formula} ) {
        $self->xml_start_tag( 'tableColumn', @attributes );
        $self->_write_calculated_column_formula( $col_data->{_formula} );
        $self->xml_end_tag( 'tableColumn' );
    }
    else {
        $self->xml_empty_tag( 'tableColumn', @attributes );
    }
}
sub _write_table_style_info {
    my $self  = shift;
    my $props = $self->{_properties};
    my @attributes          = ();
    my $name                = $props->{_style};
    my $show_first_column   = $props->{_show_first_col};
    my $show_last_column    = $props->{_show_last_col};
    my $show_row_stripes    = $props->{_show_row_stripes};
    my $show_column_stripes = $props->{_show_col_stripes};
    if ( $name && $name ne '' && $name ne 'None' ) {
        push @attributes, ( 'name' => $name );
    }
    push @attributes, ( 'showFirstColumn'   => $show_first_column );
    push @attributes, ( 'showLastColumn'    => $show_last_column );
    push @attributes, ( 'showRowStripes'    => $show_row_stripes );
    push @attributes, ( 'showColumnStripes' => $show_column_stripes );
    $self->xml_empty_tag( 'tableStyleInfo', @attributes );
}
sub _write_calculated_column_formula {
    my $self    = shift;
    my $formula = shift;
    $self->xml_data_element( 'calculatedColumnFormula', $formula );
}
1;
