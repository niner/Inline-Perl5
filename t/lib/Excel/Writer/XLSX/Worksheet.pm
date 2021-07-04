package Excel::Writer::XLSX::Worksheet;
use 5.008002;
use strict;
use warnings;
use Carp;
use File::Temp 'tempfile';
use List::Util qw(max min);
use Excel::Writer::XLSX::Format;
use Excel::Writer::XLSX::Drawing;
use Excel::Writer::XLSX::Package::XMLwriter;
use Excel::Writer::XLSX::Utility qw(xl_cell_to_rowcol
                                    xl_rowcol_to_cell
                                    xl_col_to_name
                                    xl_range
                                    quote_sheetname);
our @ISA     = qw(Excel::Writer::XLSX::Package::XMLwriter);
our $VERSION = '1.03';
sub new {
    my $class  = shift;
    my $fh     = shift;
    my $self   = Excel::Writer::XLSX::Package::XMLwriter->new( $fh );
    my $rowmax = 1_048_576;
    my $colmax = 16_384;
    my $strmax = 32767;
    $self->{_name}               = $_[0];
    $self->{_index}              = $_[1];
    $self->{_activesheet}        = $_[2];
    $self->{_firstsheet}         = $_[3];
    $self->{_str_total}          = $_[4];
    $self->{_str_unique}         = $_[5];
    $self->{_str_table}          = $_[6];
    $self->{_date_1904}          = $_[7];
    $self->{_palette}            = $_[8];
    $self->{_optimization}       = $_[9] || 0;
    $self->{_tempdir}            = $_[10];
    $self->{_excel2003_style}    = $_[11];
    $self->{_default_url_format} = $_[12];
    $self->{_max_url_length}     = $_[13] || 2079;
    $self->{_ext_sheets}    = [];
    $self->{_fileclosed}    = 0;
    $self->{_excel_version} = 2007;
    $self->{_xls_rowmax} = $rowmax;
    $self->{_xls_colmax} = $colmax;
    $self->{_xls_strmax} = $strmax;
    $self->{_dim_rowmin} = undef;
    $self->{_dim_rowmax} = undef;
    $self->{_dim_colmin} = undef;
    $self->{_dim_colmax} = undef;
    $self->{_colinfo}    = {};
    $self->{_selections} = [];
    $self->{_hidden}     = 0;
    $self->{_active}     = 0;
    $self->{_tab_color}  = 0;
    $self->{_panes}                = [];
    $self->{_active_pane}          = 3;
    $self->{_selected}             = 0;
    $self->{_hide_row_col_headers} = 0;
    $self->{_page_setup_changed} = 0;
    $self->{_paper_size}         = 0;
    $self->{_orientation}        = 1;
    $self->{_print_options_changed} = 0;
    $self->{_hcenter}               = 0;
    $self->{_vcenter}               = 0;
    $self->{_print_gridlines}       = 0;
    $self->{_screen_gridlines}      = 1;
    $self->{_print_headers}         = 0;
    $self->{_header_footer_changed} = 0;
    $self->{_header}                = '';
    $self->{_footer}                = '';
    $self->{_header_footer_aligns}  = 1;
    $self->{_header_footer_scales}  = 1;
    $self->{_header_images}         = [];
    $self->{_footer_images}         = [];
    $self->{_margin_left}   = 0.7;
    $self->{_margin_right}  = 0.7;
    $self->{_margin_top}    = 0.75;
    $self->{_margin_bottom} = 0.75;
    $self->{_margin_header} = 0.3;
    $self->{_margin_footer} = 0.3;
    $self->{_repeat_rows} = '';
    $self->{_repeat_cols} = '';
    $self->{_print_area}  = '';
    $self->{_page_order}     = 0;
    $self->{_black_white}    = 0;
    $self->{_draft_quality}  = 0;
    $self->{_print_comments} = 0;
    $self->{_page_start}     = 0;
    $self->{_fit_page}   = 0;
    $self->{_fit_width}  = 0;
    $self->{_fit_height} = 0;
    $self->{_hbreaks} = [];
    $self->{_vbreaks} = [];
    $self->{_protect}  = 0;
    $self->{_password} = undef;
    $self->{_set_cols} = {};
    $self->{_set_rows} = {};
    $self->{_zoom}              = 100;
    $self->{_zoom_scale_normal} = 1;
    $self->{_print_scale}       = 100;
    $self->{_right_to_left}     = 0;
    $self->{_show_zeros}        = 1;
    $self->{_leading_zeros}     = 0;
    $self->{_outline_row_level} = 0;
    $self->{_outline_col_level} = 0;
    $self->{_outline_style}     = 0;
    $self->{_outline_below}     = 1;
    $self->{_outline_right}     = 1;
    $self->{_outline_on}        = 1;
    $self->{_outline_changed}   = 0;
    $self->{_original_row_height} = 15;
    $self->{_default_row_height}  = 15;
    $self->{_default_row_pixels}  = 20;
    $self->{_default_col_width}   = 8.43;
    $self->{_default_col_pixels}  = 64;
    $self->{_default_row_zeroed}  = 0;
    $self->{_names} = {};
    $self->{_write_match} = [];
    $self->{_table} = {};
    $self->{_merge} = [];
    $self->{_has_vml}             = 0;
    $self->{_has_header_vml}      = 0;
    $self->{_has_comments}        = 0;
    $self->{_comments}            = {};
    $self->{_comments_array}      = [];
    $self->{_comments_author}     = '';
    $self->{_comments_visible}    = 0;
    $self->{_vml_shape_id}        = 1024;
    $self->{_buttons_array}       = [];
    $self->{_header_images_array} = [];
    $self->{_autofilter}   = '';
    $self->{_filter_on}    = 0;
    $self->{_filter_range} = [];
    $self->{_filter_cols}  = {};
    $self->{_col_sizes}        = {};
    $self->{_row_sizes}        = {};
    $self->{_col_formats}      = {};
    $self->{_col_size_changed} = 0;
    $self->{_row_size_changed} = 0;
    $self->{_last_shape_id}          = 1;
    $self->{_rel_count}              = 0;
    $self->{_hlink_count}            = 0;
    $self->{_hlink_refs}             = [];
    $self->{_external_hyper_links}   = [];
    $self->{_external_drawing_links} = [];
    $self->{_external_comment_links} = [];
    $self->{_external_vml_links}     = [];
    $self->{_external_table_links}   = [];
    $self->{_drawing_links}          = [];
    $self->{_vml_drawing_links}      = [];
    $self->{_charts}                 = [];
    $self->{_images}                 = [];
    $self->{_tables}                 = [];
    $self->{_sparklines}             = [];
    $self->{_shapes}                 = [];
    $self->{_shape_hash}             = {};
    $self->{_has_shapes}             = 0;
    $self->{_drawing}                = 0;
    $self->{_drawing_rels}           = {};
    $self->{_drawing_rels_id}        = 0;
    $self->{_vml_drawing_rels}           = {};
    $self->{_vml_drawing_rels_id}        = 0;
    $self->{_horizontal_dpi} = 0;
    $self->{_vertical_dpi}   = 0;
    $self->{_rstring}      = '';
    $self->{_previous_row} = 0;
    if ( $self->{_optimization} == 1 ) {
        my $fh = tempfile( DIR => $self->{_tempdir} );
        binmode $fh, ':utf8';
        $self->{_cell_data_fh} = $fh;
        $self->{_fh}           = $fh;
    }
    $self->{_validations}        = [];
    $self->{_cond_formats}       = {};
    $self->{_data_bars_2010}     = [];
    $self->{_use_data_bars_2010} = 0;
    $self->{_dxf_priority}       = 1;
    if ( $self->{_excel2003_style} ) {
        $self->{_original_row_height}  = 12.75;
        $self->{_default_row_height}   = 12.75;
        $self->{_default_row_pixels}   = 17;
        $self->{_margin_left}          = 0.75;
        $self->{_margin_right}         = 0.75;
        $self->{_margin_top}           = 1;
        $self->{_margin_bottom}        = 1;
        $self->{_margin_header}        = 0.5;
        $self->{_margin_footer}        = 0.5;
        $self->{_header_footer_aligns} = 0;
    }
    bless $self, $class;
    return $self;
}
sub _set_xml_writer {
    my $self     = shift;
    my $filename = shift;
    if ( $self->{_optimization} == 1 ) {
        $self->_write_single_row();
    }
    $self->SUPER::_set_xml_writer( $filename );
}
sub _assemble_xml_file {
    my $self = shift;
    $self->xml_declaration();
    $self->_write_worksheet();
    $self->_write_sheet_pr();
    $self->_write_dimension();
    $self->_write_sheet_views();
    $self->_write_sheet_format_pr();
    $self->_write_cols();
    if ( $self->{_optimization} == 0 ) {
        $self->_write_sheet_data();
    }
    else {
        $self->_write_optimized_sheet_data();
    }
    $self->_write_sheet_protection();
    if ($self->{_excel2003_style}) {
        $self->_write_phonetic_pr();
    }
    $self->_write_auto_filter();
    $self->_write_merge_cells();
    $self->_write_conditional_formats();
    $self->_write_data_validations();
    $self->_write_hyperlinks();
    $self->_write_print_options();
    $self->_write_page_margins();
    $self->_write_page_setup();
    $self->_write_header_footer();
    $self->_write_row_breaks();
    $self->_write_col_breaks();
    $self->_write_drawings();
    $self->_write_legacy_drawing();
    $self->_write_legacy_drawing_hf();
    $self->_write_table_parts();
    $self->_write_ext_list();
    $self->xml_end_tag( 'worksheet' );
    $self->xml_get_fh()->close();
}
sub _close {
    my $self       = shift;
    my $sheetnames = shift;
    my $num_sheets = scalar @$sheetnames;
}
sub get_name {
    my $self = shift;
    return $self->{_name};
}
sub select {
    my $self = shift;
    $self->{_hidden}   = 0;
    $self->{_selected} = 1;
}
sub activate {
    my $self = shift;
    $self->{_hidden}   = 0;
    $self->{_selected} = 1;
    ${ $self->{_activesheet} } = $self->{_index};
}
sub hide {
    my $self = shift;
    $self->{_hidden} = 1;
    $self->{_selected} = 0;
    ${ $self->{_activesheet} } = 0;
    ${ $self->{_firstsheet} }  = 0;
}
sub set_first_sheet {
    my $self = shift;
    $self->{_hidden} = 0;
    ${ $self->{_firstsheet} } = $self->{_index};
}
sub protect {
    my $self     = shift;
    my $password = shift || '';
    my $options  = shift || {};
    if ( $password ne '' ) {
        $password = $self->_encode_password( $password );
    }
    my %defaults = (
        sheet                 => 1,
        content               => 0,
        objects               => 0,
        scenarios             => 0,
        format_cells          => 0,
        format_columns        => 0,
        format_rows           => 0,
        insert_columns        => 0,
        insert_rows           => 0,
        insert_hyperlinks     => 0,
        delete_columns        => 0,
        delete_rows           => 0,
        select_locked_cells   => 1,
        sort                  => 0,
        autofilter            => 0,
        pivot_tables          => 0,
        select_unlocked_cells => 1,
    );
    for my $key ( keys %{$options} ) {
        if ( exists $defaults{$key} ) {
            $defaults{$key} = $options->{$key};
        }
        else {
            carp "Unknown protection object: $key\n";
        }
    }
    $defaults{password} = $password;
    $self->{_protect} = \%defaults;
}
sub _encode_password {
    use integer;
    my $self      = shift;
    my $plaintext = $_[0];
    my $password;
    my $count;
    my @chars;
    my $i = 0;
    $count = @chars = split //, $plaintext;
    foreach my $char ( @chars ) {
        my $low_15;
        my $high_15;
        $char    = ord( $char ) << ++$i;
        $low_15  = $char & 0x7fff;
        $high_15 = $char & 0x7fff << 15;
        $high_15 = $high_15 >> 15;
        $char    = $low_15 | $high_15;
    }
    $password = 0x0000;
    $password ^= $_ for @chars;
    $password ^= $count;
    $password ^= 0xCE4B;
    return sprintf "%X", $password;
}
sub set_column {
    my $self = shift;
    my @data = @_;
    my $cell = $data[0];
    if ( $cell =~ /^\D/ ) {
        @data = $self->_substitute_cellref( @_ );
        shift @data;
        splice @data, 1, 1;
    }
    return if @data < 3;
    return if not defined $data[0];
    return if not defined $data[1];
    $data[1] = $data[0] if $data[1] == 0;
    ( $data[0], $data[1] ) = ( $data[1], $data[0] ) if $data[0] > $data[1];
    my $ignore_row = 1;
    my $ignore_col = 1;
    $ignore_col = 0 if ref $data[3];
    $ignore_col = 0 if $data[2] && $data[4];
    return -2
      if $self->_check_dimensions( 0, $data[0], $ignore_row, $ignore_col );
    return -2
      if $self->_check_dimensions( 0, $data[1], $ignore_row, $ignore_col );
    $data[5] = 0 unless defined $data[5];
    $data[5] = 0 if $data[5] < 0;
    $data[5] = 7 if $data[5] > 7;
    if ( $data[5] > $self->{_outline_col_level} ) {
        $self->{_outline_col_level} = $data[5];
    }
    $self->{_colinfo}->{ sprintf "%05d", $data[0] } = [@data];
    $self->{_col_size_changed} = 1;
    my $width  = $data[2];
    my $format = $data[3];
    my $hidden = $data[4] || 0;
    $width = $self->{_default_col_width} if !defined $width;
    my ( $firstcol, $lastcol ) = @data;
    foreach my $col ( $firstcol .. $lastcol ) {
        $self->{_col_sizes}->{$col}   = [$width, $hidden];
        $self->{_col_formats}->{$col} = $format if $format;
    }
}
sub set_selection {
    my $self = shift;
    my $pane;
    my $active_cell;
    my $sqref;
    return unless @_;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    if ( @_ == 2 ) {
        $active_cell = xl_rowcol_to_cell( $_[0], $_[1] );
        $sqref = $active_cell;
    }
    elsif ( @_ == 4 ) {
        $active_cell = xl_rowcol_to_cell( $_[0], $_[1] );
        my ( $row_first, $col_first, $row_last, $col_last ) = @_;
        if ( $row_first > $row_last ) {
            ( $row_first, $row_last ) = ( $row_last, $row_first );
        }
        if ( $col_first > $col_last ) {
            ( $col_first, $col_last ) = ( $col_last, $col_first );
        }
        if ( ( $row_first == $row_last ) && ( $col_first == $col_last ) ) {
            $sqref = $active_cell;
        }
        else {
            $sqref = xl_range( $row_first, $row_last, $col_first, $col_last );
        }
    }
    else {
        return;
    }
    return if $sqref eq 'A1';
    $self->{_selections} = [ [ $pane, $active_cell, $sqref ] ];
}
sub freeze_panes {
    my $self = shift;
    return unless @_;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    my $row      = shift;
    my $col      = shift || 0;
    my $top_row  = shift || $row;
    my $left_col = shift || $col;
    my $type     = shift || 0;
    $self->{_panes} = [ $row, $col, $top_row, $left_col, $type ];
}
sub split_panes {
    my $self = shift;
    $self->freeze_panes( @_[ 0 .. 3 ], 2 );
}
*thaw_panes = *split_panes;
sub set_portrait {
    my $self = shift;
    $self->{_orientation}        = 1;
    $self->{_page_setup_changed} = 1;
}
sub set_landscape {
    my $self = shift;
    $self->{_orientation}        = 0;
    $self->{_page_setup_changed} = 1;
}
sub set_page_view {
    my $self = shift;
    $self->{_page_view} = defined $_[0] ? $_[0] : 1;
}
sub set_tab_color {
    my $self  = shift;
    my $color = &Excel::Writer::XLSX::Format::_get_color( $_[0] );
    $self->{_tab_color} = $color;
}
sub set_paper {
    my $self       = shift;
    my $paper_size = shift;
    if ( $paper_size ) {
        $self->{_paper_size}         = $paper_size;
        $self->{_page_setup_changed} = 1;
    }
}
sub set_header {
    my $self    = shift;
    my $string  = $_[0] || '';
    my $margin  = $_[1] || 0.3;
    my $options = $_[2] || {};
    $string =~ s/&\[Picture\]/&G/g;
    if ( length $string >= 255 ) {
        carp 'Header string must be less than 255 characters';
        return;
    }
    if ( defined $options->{align_with_margins} ) {
        $self->{_header_footer_aligns} = $options->{align_with_margins};
    }
    if ( defined $options->{scale_with_doc} ) {
        $self->{_header_footer_scales} = $options->{scale_with_doc};
    }
    $self->{_header_images} = [];
    if ( $options->{image_left} ) {
        push @{ $self->{_header_images} }, [ $options->{image_left}, 'LH' ];
    }
    if ( $options->{image_center} ) {
        push @{ $self->{_header_images} }, [ $options->{image_center}, 'CH' ];
    }
    if ( $options->{image_right} ) {
        push @{ $self->{_header_images} }, [ $options->{image_right}, 'RH' ];
    }
    my $placeholder_count = () = $string =~ /&G/g;
    my $image_count = @{ $self->{_header_images} };
    if ( $image_count != $placeholder_count ) {
        warn "Number of header images ($image_count) doesn't match placeholder "
          . "count ($placeholder_count) in string: $string\n";
        $self->{_header_images} = [];
        return;
    }
    if ( $image_count ) {
        $self->{_has_header_vml} = 1;
    }
    $self->{_header}                = $string;
    $self->{_margin_header}         = $margin;
    $self->{_header_footer_changed} = 1;
}
sub set_footer {
    my $self    = shift;
    my $string  = $_[0] || '';
    my $margin  = $_[1] || 0.3;
    my $options = $_[2] || {};
    $string =~ s/&\[Picture\]/&G/g;
    if ( length $string >= 255 ) {
        carp 'Footer string must be less than 255 characters';
        return;
    }
    if ( defined $options->{align_with_margins} ) {
        $self->{_header_footer_aligns} = $options->{align_with_margins};
    }
    if ( defined $options->{scale_with_doc} ) {
        $self->{_header_footer_scales} = $options->{scale_with_doc};
    }
    $self->{_footer_images} = [];
    if ( $options->{image_left} ) {
        push @{ $self->{_footer_images} }, [ $options->{image_left}, 'LF' ];
    }
    if ( $options->{image_center} ) {
        push @{ $self->{_footer_images} }, [ $options->{image_center}, 'CF' ];
    }
    if ( $options->{image_right} ) {
        push @{ $self->{_footer_images} }, [ $options->{image_right}, 'RF' ];
    }
    my $placeholder_count = () = $string =~ /&G/g;
    my $image_count = @{ $self->{_footer_images} };
    if ( $image_count != $placeholder_count ) {
        warn "Number of footer images ($image_count) doesn't match placeholder "
          . "count ($placeholder_count) in string: $string\n";
        $self->{_footer_images} = [];
        return;
    }
    if ( $image_count ) {
        $self->{_has_header_vml} = 1;
    }
    $self->{_footer}                = $string;
    $self->{_margin_footer}         = $margin;
    $self->{_header_footer_changed} = 1;
}
sub center_horizontally {
    my $self = shift;
    $self->{_print_options_changed} = 1;
    $self->{_hcenter}               = 1;
}
sub center_vertically {
    my $self = shift;
    $self->{_print_options_changed} = 1;
    $self->{_vcenter}               = 1;
}
sub set_margins {
    my $self = shift;
    $self->set_margin_left( $_[0] );
    $self->set_margin_right( $_[0] );
    $self->set_margin_top( $_[0] );
    $self->set_margin_bottom( $_[0] );
}
sub set_margins_LR {
    my $self = shift;
    $self->set_margin_left( $_[0] );
    $self->set_margin_right( $_[0] );
}
sub set_margins_TB {
    my $self = shift;
    $self->set_margin_top( $_[0] );
    $self->set_margin_bottom( $_[0] );
}
sub set_margin_left {
    my $self    = shift;
    my $margin  = shift;
    my $default = 0.7;
    if   ( defined $margin ) { $margin = 0 + $margin }
    else                     { $margin = $default }
    $self->{_margin_left} = $margin;
}
sub set_margin_right {
    my $self    = shift;
    my $margin  = shift;
    my $default = 0.7;
    if   ( defined $margin ) { $margin = 0 + $margin }
    else                     { $margin = $default }
    $self->{_margin_right} = $margin;
}
sub set_margin_top {
    my $self    = shift;
    my $margin  = shift;
    my $default = 0.75;
    if   ( defined $margin ) { $margin = 0 + $margin }
    else                     { $margin = $default }
    $self->{_margin_top} = $margin;
}
sub set_margin_bottom {
    my $self    = shift;
    my $margin  = shift;
    my $default = 0.75;
    if   ( defined $margin ) { $margin = 0 + $margin }
    else                     { $margin = $default }
    $self->{_margin_bottom} = $margin;
}
sub repeat_rows {
    my $self = shift;
    my $row_min = $_[0];
    my $row_max = $_[1] || $_[0];
    $row_min++;
    $row_max++;
    my $area = '$' . $row_min . ':' . '$' . $row_max;
    my $sheetname = quote_sheetname( $self->{_name} );
    $area = $sheetname . "!" . $area;
    $self->{_repeat_rows} = $area;
}
sub repeat_columns {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
        shift @_;
        splice @_, 1, 1;
    }
    my $col_min = $_[0];
    my $col_max = $_[1] || $_[0];
    $col_min = xl_col_to_name( $_[0], 1 );
    $col_max = xl_col_to_name( $_[1], 1 );
    my $area = $col_min . ':' . $col_max;
    my $sheetname = quote_sheetname( $self->{_name} );
    $area = $sheetname . "!" . $area;
    $self->{_repeat_cols} = $area;
}
sub print_area {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    return if @_ != 4;
    my ( $row1, $col1, $row2, $col2 ) = @_;
    if (    $row1 == 0
        and $col1 == 0
        and $row2 == $self->{_xls_rowmax} - 1
        and $col2 == $self->{_xls_colmax} - 1 )
    {
        return;
    }
    my $area = $self->_convert_name_area( $row1, $col1, $row2, $col2 );
    $self->{_print_area} = $area;
}
sub autofilter {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    return if @_ != 4;
    my ( $row1, $col1, $row2, $col2 ) = @_;
    ( $row1, $row2 ) = ( $row2, $row1 ) if $row2 < $row1;
    ( $col1, $col2 ) = ( $col2, $col1 ) if $col2 < $col1;
    my $area = $self->_convert_name_area( $row1, $col1, $row2, $col2 );
    my $ref = xl_range( $row1, $row2, $col1, $col2 );
    $self->{_autofilter}     = $area;
    $self->{_autofilter_ref} = $ref;
    $self->{_filter_range}   = [ $col1, $col2 ];
}
sub filter_column {
    my $self       = shift;
    my $col        = $_[0];
    my $expression = $_[1];
    croak "Must call autofilter() before filter_column()"
      unless $self->{_autofilter};
    croak "Incorrect number of arguments to filter_column()"
      unless @_ == 2;
    if ( $col =~ /^\D/ ) {
        my $col_letter = $col;
        ( undef, $col ) = $self->_substitute_cellref( $col . '1' );
        croak "Invalid column '$col_letter'" if $col >= $self->{_xls_colmax};
    }
    my ( $col_first, $col_last ) = @{ $self->{_filter_range} };
    if ( $col < $col_first or $col > $col_last ) {
        croak "Column '$col' outside autofilter() column range "
          . "($col_first .. $col_last)";
    }
    my @tokens = $self->_extract_filter_tokens( $expression );
    croak "Incorrect number of tokens in expression '$expression'"
      unless ( @tokens == 3 or @tokens == 7 );
    @tokens = $self->_parse_filter_expression( $expression, @tokens );
    if ( @tokens == 2 && $tokens[0] == 2 ) {
        $self->filter_column_list( $col, $tokens[1] );
    }
    elsif (@tokens == 5
        && $tokens[0] == 2
        && $tokens[2] == 1
        && $tokens[3] == 2 )
    {
        $self->filter_column_list( $col, $tokens[1], $tokens[4] );
    }
    else {
        $self->{_filter_cols}->{$col} = [@tokens];
        $self->{_filter_type}->{$col} = 0;
    }
    $self->{_filter_on} = 1;
}
sub filter_column_list {
    my $self   = shift;
    my $col    = shift;
    my @tokens = @_;
    croak "Must call autofilter() before filter_column_list()"
      unless $self->{_autofilter};
    croak "Incorrect number of arguments to filter_column_list()"
      unless @tokens;
    if ( $col =~ /^\D/ ) {
        my $col_letter = $col;
        ( undef, $col ) = $self->_substitute_cellref( $col . '1' );
        croak "Invalid column '$col_letter'" if $col >= $self->{_xls_colmax};
    }
    my ( $col_first, $col_last ) = @{ $self->{_filter_range} };
    if ( $col < $col_first or $col > $col_last ) {
        croak "Column '$col' outside autofilter() column range "
          . "($col_first .. $col_last)";
    }
    $self->{_filter_cols}->{$col} = [@tokens];
    $self->{_filter_type}->{$col} = 1;
    $self->{_filter_on}           = 1;
}
sub _extract_filter_tokens {
    my $self       = shift;
    my $expression = $_[0];
    return unless $expression;
    my @tokens = ( $expression =~ /"(?:[^"]|"")*"|\S+/g );
    for ( @tokens ) {
        s/^"//;
        s/"$//;
        s/""/"/g;
    }
    return @tokens;
}
sub _parse_filter_expression {
    my $self       = shift;
    my $expression = shift;
    my @tokens     = @_;
    if ( @tokens == 7 ) {
        my $conditional = $tokens[3];
        if ( $conditional =~ /^(and|&&)$/ ) {
            $conditional = 0;
        }
        elsif ( $conditional =~ /^(or|\|\|)$/ ) {
            $conditional = 1;
        }
        else {
            croak "Token '$conditional' is not a valid conditional "
              . "in filter expression '$expression'";
        }
        my @expression_1 =
          $self->_parse_filter_tokens( $expression, @tokens[ 0, 1, 2 ] );
        my @expression_2 =
          $self->_parse_filter_tokens( $expression, @tokens[ 4, 5, 6 ] );
        return ( @expression_1, $conditional, @expression_2 );
    }
    else {
        return $self->_parse_filter_tokens( $expression, @tokens );
    }
}
sub _parse_filter_tokens {
    my $self       = shift;
    my $expression = shift;
    my @tokens     = @_;
    my %operators = (
        '==' => 2,
        '='  => 2,
        '=~' => 2,
        'eq' => 2,
        '!=' => 5,
        '!~' => 5,
        'ne' => 5,
        '<>' => 5,
        '<'  => 1,
        '<=' => 3,
        '>'  => 4,
        '>=' => 6,
    );
    my $operator = $operators{ $tokens[1] };
    my $token    = $tokens[2];
    if ( $tokens[0] =~ /^top|bottom$/i ) {
        my $value = $tokens[1];
        if (   $value =~ /\D/
            or $value < 1
            or $value > 500 )
        {
            croak "The value '$value' in expression '$expression' "
              . "must be in the range 1 to 500";
        }
        $token = lc $token;
        if ( $token ne 'items' and $token ne '%' ) {
            croak "The type '$token' in expression '$expression' "
              . "must be either 'items' or '%'";
        }
        if ( $tokens[0] =~ /^top$/i ) {
            $operator = 30;
        }
        else {
            $operator = 32;
        }
        if ( $tokens[2] eq '%' ) {
            $operator++;
        }
        $token = $value;
    }
    if ( not $operator and $tokens[0] ) {
        croak "Token '$tokens[1]' is not a valid operator "
          . "in filter expression '$expression'";
    }
    if ( $token =~ /^blanks|nonblanks$/i ) {
        if ( $operator != 2 and $operator != 5 ) {
            croak "The operator '$tokens[1]' in expression '$expression' "
              . "is not valid in relation to Blanks/NonBlanks'";
        }
        $token = lc $token;
        if ( $token eq 'blanks' ) {
            if ( $operator == 5 ) {
                $token = ' ';
            }
        }
        else {
            if ( $operator == 5 ) {
                $operator = 2;
                $token    = 'blanks';
            }
            else {
                $operator = 5;
                $token    = ' ';
            }
        }
    }
    if ( $operator == 2 and $token =~ /[*?]/ ) {
        $operator = 22;
    }
    return ( $operator, $token );
}
sub _convert_name_area {
    my $self = shift;
    my $row_num_1 = $_[0];
    my $col_num_1 = $_[1];
    my $row_num_2 = $_[2];
    my $col_num_2 = $_[3];
    my $range1       = '';
    my $range2       = '';
    my $row_col_only = 0;
    my $area;
    my $col_char_1 = xl_col_to_name( $col_num_1, 1 );
    my $col_char_2 = xl_col_to_name( $col_num_2, 1 );
    my $row_char_1 = '$' . ( $row_num_1 + 1 );
    my $row_char_2 = '$' . ( $row_num_2 + 1 );
    if ( $row_num_1 == 0 and $row_num_2 == $self->{_xls_rowmax} - 1 ) {
        $range1       = $col_char_1;
        $range2       = $col_char_2;
        $row_col_only = 1;
    }
    elsif ( $col_num_1 == 0 and $col_num_2 == $self->{_xls_colmax} - 1 ) {
        $range1       = $row_char_1;
        $range2       = $row_char_2;
        $row_col_only = 1;
    }
    else {
        $range1 = $col_char_1 . $row_char_1;
        $range2 = $col_char_2 . $row_char_2;
    }
    if ( $range1 eq $range2 && !$row_col_only ) {
        $area = $range1;
    }
    else {
        $area = $range1 . ':' . $range2;
    }
    my $sheetname = quote_sheetname( $self->{_name} );
    $area = $sheetname . "!" . $area;
    return $area;
}
sub hide_gridlines {
    my $self = shift;
    my $option =
      defined $_[0] ? $_[0] : 1;
    if ( $option == 0 ) {
        $self->{_print_gridlines}       = 1;
        $self->{_screen_gridlines}      = 1;
        $self->{_print_options_changed} = 1;
    }
    elsif ( $option == 1 ) {
        $self->{_print_gridlines}  = 0;
        $self->{_screen_gridlines} = 1;
    }
    else {
        $self->{_print_gridlines}  = 0;
        $self->{_screen_gridlines} = 0;
    }
}
sub print_row_col_headers {
    my $self = shift;
    my $headers = defined $_[0] ? $_[0] : 1;
    if ( $headers ) {
        $self->{_print_headers}         = 1;
        $self->{_print_options_changed} = 1;
    }
    else {
        $self->{_print_headers} = 0;
    }
}
sub hide_row_col_headers {
    my $self = shift;
    $self->{_hide_row_col_headers} = 1;
}
sub fit_to_pages {
    my $self = shift;
    $self->{_fit_page}           = 1;
    $self->{_fit_width}          = defined $_[0] ? $_[0] : 1;
    $self->{_fit_height}         = defined $_[1] ? $_[1] : 1;
    $self->{_page_setup_changed} = 1;
}
sub set_h_pagebreaks {
    my $self = shift;
    push @{ $self->{_hbreaks} }, @_;
}
sub set_v_pagebreaks {
    my $self = shift;
    push @{ $self->{_vbreaks} }, @_;
}
sub set_zoom {
    my $self = shift;
    my $scale = $_[0] || 100;
    if ( $scale < 10 or $scale > 400 ) {
        carp "Zoom factor $scale outside range: 10 <= zoom <= 400";
        $scale = 100;
    }
    $self->{_zoom} = int $scale;
}
sub set_print_scale {
    my $self = shift;
    my $scale = $_[0] || 100;
    if ( $scale < 10 or $scale > 400 ) {
        carp "Print scale $scale outside range: 10 <= zoom <= 400";
        $scale = 100;
    }
    $self->{_fit_page} = 0;
    $self->{_print_scale}        = int $scale;
    $self->{_page_setup_changed} = 1;
}
sub print_black_and_white {
    my $self = shift;
    $self->{_black_white} = 1;
}
sub keep_leading_zeros {
    my $self = shift;
    if ( defined $_[0] ) {
        $self->{_leading_zeros} = $_[0];
    }
    else {
        $self->{_leading_zeros} = 1;
    }
}
sub show_comments {
    my $self = shift;
    $self->{_comments_visible} = defined $_[0] ? $_[0] : 1;
}
sub set_comments_author {
    my $self = shift;
    $self->{_comments_author} = $_[0] if defined $_[0];
}
sub right_to_left {
    my $self = shift;
    $self->{_right_to_left} = defined $_[0] ? $_[0] : 1;
}
sub hide_zero {
    my $self = shift;
    $self->{_show_zeros} = defined $_[0] ? not $_[0] : 0;
}
sub print_across {
    my $self = shift;
    my $page_order = defined $_[0] ? $_[0] : 1;
    if ( $page_order ) {
        $self->{_page_order}         = 1;
        $self->{_page_setup_changed} = 1;
    }
    else {
        $self->{_page_order} = 0;
    }
}
sub set_start_page {
    my $self = shift;
    return unless defined $_[0];
    $self->{_page_start}   = $_[0];
}
sub set_first_row_column {
    my $self = shift;
    my $row = $_[0] || 0;
    my $col = $_[1] || 0;
    $row = $self->{_xls_rowmax} if $row > $self->{_xls_rowmax};
    $col = $self->{_xls_colmax} if $col > $self->{_xls_colmax};
    $self->{_first_row} = $row;
    $self->{_first_col} = $col;
}
sub add_write_handler {
    my $self = shift;
    return unless @_ == 2;
    return unless ref $_[1] eq 'CODE';
    push @{ $self->{_write_match} }, [@_];
}
sub write {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    my $token = $_[2];
    $token = '' unless defined $token;
    for my $aref ( @{ $self->{_write_match} } ) {
        my $re  = $aref->[0];
        my $sub = $aref->[1];
        if ( $token =~ /$re/ ) {
            my $match = &$sub( $self, @_ );
            return $match if defined $match;
        }
    }
    if ( ref $token eq "ARRAY" ) {
        return $self->write_row( @_ );
    }
    elsif ( $self->{_leading_zeros} and $token =~ /^0\d+$/ ) {
        return $self->write_string( @_ );
    }
    elsif ( $token =~ /^([+-]?)(?=[0-9]|\.[0-9])[0-9]*(\.[0-9]*)?([Ee]([+-]?[0-9]+))?$/ ) {
        return $self->write_number( @_ );
    }
    elsif ( $token =~ m|^[fh]tt?ps?://| ) {
        return $self->write_url( @_ );
    }
    elsif ( $token =~ m/^mailto:/ ) {
        return $self->write_url( @_ );
    }
    elsif ( $token =~ m[^(?:in|ex)ternal:] ) {
        return $self->write_url( @_ );
    }
    elsif ( $token =~ /^=/ ) {
        return $self->write_formula( @_ );
    }
    elsif ( $token =~ /^{=.*}$/ ) {
        return $self->write_formula( @_ );
    }
    elsif ( $token eq '' ) {
        splice @_, 2, 1;
        return $self->write_blank( @_ );
    }
    else {
        return $self->write_string( @_ );
    }
}
sub write_row {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    if ( ref $_[2] ne 'ARRAY' ) {
        croak "Not an array ref in call to write_row()$!";
    }
    my $row     = shift;
    my $col     = shift;
    my $tokens  = shift;
    my @options = @_;
    my $error   = 0;
    my $ret;
    for my $token ( @$tokens ) {
        if ( ref $token eq "ARRAY" ) {
            $ret = $self->write_col( $row, $col, $token, @options );
        }
        else {
            $ret = $self->write( $row, $col, $token, @options );
        }
        $error ||= $ret;
        $col++;
    }
    return $error;
}
sub write_col {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    if ( ref $_[2] ne 'ARRAY' ) {
        croak "Not an array ref in call to write_col()$!";
    }
    my $row     = shift;
    my $col     = shift;
    my $tokens  = shift;
    my @options = @_;
    my $error   = 0;
    my $ret;
    for my $token ( @$tokens ) {
        $ret = $self->write( $row, $col, $token, @options );
        $error ||= $ret;
        $row++;
    }
    return $error;
}
sub write_comment {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    if ( @_ < 3 ) { return -1 }
    my $row = $_[0];
    my $col = $_[1];
    croak "Uneven number of additional arguments" unless @_ % 2;
    return -2 if $self->_check_dimensions( $row, $col );
    $self->{_has_vml}      = 1;
    $self->{_has_comments} = 1;
    $self->{_comments}->{$row}->{$col} = [ @_ ];
}
sub write_number {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    if ( @_ < 3 ) { return -1 }
    my $row  = $_[0];
    my $col  = $_[1];
    my $num  = $_[2] + 0;
    my $xf   = $_[3];
    my $type = 'n';
    return -2 if $self->_check_dimensions( $row, $col );
    if ( $self->{_optimization} == 1 && $row > $self->{_previous_row} ) {
        $self->_write_single_row( $row );
    }
    $self->{_table}->{$row}->{$col} = [ $type, $num, $xf ];
    return 0;
}
sub write_string {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    if ( @_ < 3 ) { return -1 }
    my $row  = $_[0];
    my $col  = $_[1];
    my $str  = $_[2];
    my $xf   = $_[3];
    my $type = 's';
    my $index;
    my $str_error = 0;
    return -4 if !defined $str;
    return -2 if $self->_check_dimensions( $row, $col );
    if ( length $str > $self->{_xls_strmax} ) {
        $str = substr( $str, 0, $self->{_xls_strmax} );
        $str_error = -3;
    }
    if ( $self->{_optimization} == 0 ) {
        $index = $self->_get_shared_string_index( $str );
    }
    else {
        $index = $str;
    }
    if ( $self->{_optimization} == 1 && $row > $self->{_previous_row} ) {
        $self->_write_single_row( $row );
    }
    $self->{_table}->{$row}->{$col} = [ $type, $index, $xf ];
    return $str_error;
}
sub write_rich_string {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    if ( @_ < 3 ) { return -1 }
    my $row    = shift;
    my $col    = shift;
    my $str    = '';
    my $xf     = undef;
    my $type   = 's';
    my $length = 0;
    my $index;
    my $str_error = 0;
    return -2 if $self->_check_dimensions( $row, $col );
    if ( ref $_[-1] ) {
        $xf = pop @_;
    }
    open my $str_fh, '>', \$str or die "Failed to open filehandle: $!";
    binmode $str_fh, ':utf8';
    my $writer = Excel::Writer::XLSX::Package::XMLwriter->new( $str_fh );
    $self->{_rstring} = $writer;
    my $default = Excel::Writer::XLSX::Format->new();
    my @fragments;
    my $last = 'format';
    my $pos  = 0;
    for my $token ( @_ ) {
        if ( !ref $token ) {
            if ( $last ne 'format' ) {
                push @fragments, ( $default, $token );
            }
            else {
                push @fragments, $token;
            }
            $length += length $token;
            $last = 'string';
        }
        else {
            if ( $last eq 'format' && $pos > 0 ) {
                return -4;
            }
            push @fragments, $token;
            $last = 'format';
        }
        $pos++;
    }
    if ( !ref $fragments[0] ) {
        $self->{_rstring}->xml_start_tag( 'r' );
    }
    for my $token ( @fragments ) {
        if ( ref $token ) {
            $self->{_rstring}->xml_start_tag( 'r' );
            $self->_write_font( $token );
        }
        else {
            my @attributes = ();
            if ( $token =~ /^\s/ || $token =~ /\s$/ ) {
                push @attributes, ( 'xml:space' => 'preserve' );
            }
            $self->{_rstring}->xml_data_element( 't', $token, @attributes );
            $self->{_rstring}->xml_end_tag( 'r' );
        }
    }
    if ( $length > $self->{_xls_strmax} ) {
        return -3;
    }
    if ( $self->{_optimization} == 0 ) {
        $index = $self->_get_shared_string_index( $str );
    }
    else {
        $index = $str;
    }
    if ( $self->{_optimization} == 1 && $row > $self->{_previous_row} ) {
        $self->_write_single_row( $row );
    }
    $self->{_table}->{$row}->{$col} = [ $type, $index, $xf ];
    return 0;
}
sub write_blank {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    return -1 if @_ < 2;
    return 0 if not defined $_[2];
    my $row  = $_[0];
    my $col  = $_[1];
    my $xf   = $_[2];
    my $type = 'b';
    return -2 if $self->_check_dimensions( $row, $col );
    if ( $self->{_optimization} == 1 && $row > $self->{_previous_row} ) {
        $self->_write_single_row( $row );
    }
    $self->{_table}->{$row}->{$col} = [ $type, undef, $xf ];
    return 0;
}
sub write_formula {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    if ( @_ < 3 ) { return -1 }
    my $row     = $_[0];
    my $col     = $_[1];
    my $formula = $_[2];
    my $xf      = $_[3];
    my $value   = $_[4];
    my $type    = 'f';
    if ( $formula =~ /^{=.*}$/ ) {
        return $self->write_array_formula( $row, $col, $row, $col, $formula,
            $xf, $value );
    }
    return -2 if $self->_check_dimensions( $row, $col );
    $formula =~ s/^=//;
    if ( $self->{_optimization} == 1 && $row > $self->{_previous_row} ) {
        $self->_write_single_row( $row );
    }
    $self->{_table}->{$row}->{$col} = [ $type, $formula, $xf, $value ];
    return 0;
}
sub write_array_formula {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    if ( @_ < 5 ) { return -1 }
    my $row1    = $_[0];
    my $col1    = $_[1];
    my $row2    = $_[2];
    my $col2    = $_[3];
    my $formula = $_[4];
    my $xf      = $_[5];
    my $value   = $_[6];
    my $type    = 'a';
    ( $row1, $row2 ) = ( $row2, $row1 ) if $row1 > $row2;
    ( $col1, $col2 ) = ( $col1, $col2 ) if $col1 > $col2;
    return -2 if $self->_check_dimensions( $row2, $col2 );
    my $range;
    if ( $row1 == $row2 and $col1 == $col2 ) {
        $range = xl_rowcol_to_cell( $row1, $col1 );
    }
    else {
        $range =
            xl_rowcol_to_cell( $row1, $col1 ) . ':'
          . xl_rowcol_to_cell( $row2, $col2 );
    }
    $formula =~ s/^{(.*)}$/$1/;
    $formula =~ s/^=//;
    my $row = $row1;
    if ( $self->{_optimization} == 1 && $row > $self->{_previous_row} ) {
        $self->_write_single_row( $row );
    }
    $self->{_table}->{$row1}->{$col1} =
      [ $type, $formula, $xf, $range, $value ];
    if ( !$self->{_optimization} ) {
        for my $row ( $row1 .. $row2 ) {
            for my $col ( $col1 .. $col2 ) {
                next if $row == $row1 and $col == $col1;
                $self->write_number( $row, $col, 0, $xf );
            }
        }
    }
    return 0;
}
sub write_boolean {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    my $row  = $_[0];
    my $col  = $_[1];
    my $val  = $_[2] ? 1 : 0;
    my $xf   = $_[3];
    my $type = 'l';
    return -2 if $self->_check_dimensions( $row, $col );
    if ( $self->{_optimization} == 1 && $row > $self->{_previous_row} ) {
        $self->_write_single_row( $row );
    }
    $self->{_table}->{$row}->{$col} = [ $type, $val, $xf ];
    return 0;
}
sub outline_settings {
    my $self = shift;
    $self->{_outline_on}    = defined $_[0] ? $_[0] : 1;
    $self->{_outline_below} = defined $_[1] ? $_[1] : 1;
    $self->{_outline_right} = defined $_[2] ? $_[2] : 1;
    $self->{_outline_style} = $_[3] || 0;
    $self->{_outline_changed} = 1;
}
sub _escape_url {
    my $url = shift;
    return $url if $url =~ /%[0-9a-fA-F]{2}/;
    $url =~ s/%/%25/g;
    $url =~ s/[\s\x00]/%20/g;
    $url =~ s/(["<>[\]`^{}])/sprintf '%%%x', ord $1/eg;
    return $url;
}
sub write_url {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    if ( @_ < 3 ) { return -1 }
    my @args = @_;
    if (defined $args[3] and !ref $args[3]) {
        ( $args[3], $args[4] ) = ( $args[4], $args[3] );
    }
    my $row       = $args[0];
    my $col       = $args[1];
    my $url       = $args[2];
    my $xf        = $args[3];
    my $str       = $args[4];
    my $tip       = $args[5];
    my $type      = 'l';
    my $link_type = 1;
    my $external  = 0;
    $str = $url unless defined $str;
    if ( $url =~ s/^internal:// ) {
        $str =~ s/^internal://;
        $link_type = 2;
    }
    if ( $url =~ s/^external:// ) {
        $str =~ s/^external://;
        $url =~ s[/][\\]g;
        $str =~ s[/][\\]g;
        $external = 1;
    }
    $str =~ s/^mailto://;
    return -2 if $self->_check_dimensions( $row, $col );
    my $str_error = 0;
    if ( length $str > $self->{_xls_strmax} ) {
        $str = substr( $str, 0, $self->{_xls_strmax} );
        $str_error = -3;
    }
    my $url_str = $str;
    if ( $link_type == 1 ) {
        ( $url, $url_str ) = split /#/, $url, 2;
        $url = _escape_url( $url );
        if ( $url_str && !$external ) {
            $url_str = _escape_url( $url_str );
        }
        if ( $url =~ m{^\w:} || $url =~ m{^\\\\} ) {
            $url = 'file:///' . $url;
        }
        $url =~ s{^.\\}{};
    }
    my $tmp_url_str = $url_str || '';
    my $max_url     = $self->{_max_url_length};
    if ( length $url > $max_url || length $tmp_url_str > $max_url ) {
        carp "Ignoring URL '$url' where link or anchor > $max_url characters "
          . "since it exceeds Excel's limit for URLS. See LIMITATIONS "
          . "section of the Excel::Writer::XLSX documentation.";
        return -4;
    }
    $self->{_hlink_count}++;
    if ( $self->{_hlink_count} > 65_530 ) {
        carp "Ignoring URL '$url' since it exceeds Excel's limit of 65,530 "
          . "URLs per worksheet. See LIMITATIONS section of the "
          . "Excel::Writer::XLSX documentation.";
        return -5;
    }
    if ( $self->{_optimization} == 1 && $row > $self->{_previous_row} ) {
        $self->_write_single_row( $row );
    }
    if ( !defined $xf ) {
        $xf = $self->{_default_url_format};
    }
    $self->write_string( $row, $col, $str, $xf );
    $self->{_hyperlinks}->{$row}->{$col} = {
        _link_type => $link_type,
        _url       => $url,
        _str       => $url_str,
        _tip       => $tip
    };
    return $str_error;
}
sub write_date_time {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    if ( @_ < 3 ) { return -1 }
    my $row  = $_[0];
    my $col  = $_[1];
    my $str  = $_[2];
    my $xf   = $_[3];
    my $type = 'n';
    return -2 if $self->_check_dimensions( $row, $col );
    my $str_error = 0;
    my $date_time = $self->convert_date_time( $str );
    if ( !defined $date_time ) {
        return $self->write_string( @_ );
    }
    if ( $self->{_optimization} == 1 && $row > $self->{_previous_row} ) {
        $self->_write_single_row( $row );
    }
    $self->{_table}->{$row}->{$col} = [ $type, $date_time, $xf ];
    return $str_error;
}
sub convert_date_time {
    my $self      = shift;
    my $date_time = $_[0];
    my $days    = 0;
    my $seconds = 0;
    my ( $year, $month, $day );
    my ( $hour, $min,   $sec );
    $date_time =~ s/^\s+//;
    $date_time =~ s/\s+$//;
    return if $date_time =~ /[^0-9T:\-\.Z]/;
    return unless $date_time =~ /\dT|T\d/;
    $date_time =~ s/Z$//;
    my ( $date, $time ) = split /T/, $date_time;
    if ( $time ne '' ) {
        if ( $time =~ /^(\d\d):(\d\d)(:(\d\d(\.\d+)?))?/ ) {
            $hour = $1;
            $min  = $2;
            $sec  = $4 || 0;
        }
        else {
            return undef;
        }
        return if $hour >= 24;
        return if $min >= 60;
        return if $sec >= 60;
        $seconds = ( $hour * 60 * 60 + $min * 60 + $sec ) / ( 24 * 60 * 60 );
    }
    return $seconds if $date eq '';
    if ( $date =~ /^(\d\d\d\d)-(\d\d)-(\d\d)$/ ) {
        $year  = $1;
        $month = $2;
        $day   = $3;
    }
    else {
        return undef;
    }
    my $date_1904 = $self->{_date_1904};
    if ( not $date_1904 ) {
        return $seconds      if $date eq '1899-12-31';
        return $seconds      if $date eq '1900-01-00';
        return 60 + $seconds if $date eq '1900-02-29';
    }
    my $epoch  = $date_1904 ? 1904 : 1900;
    my $offset = $date_1904 ? 4    : 0;
    my $norm   = 300;
    my $range  = $year - $epoch;
    my @mdays = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
    my $leap = 0;
    $leap = 1 if $year % 4 == 0 and $year % 100 or $year % 400 == 0;
    $mdays[1] = 29 if $leap;
    return if $year < $epoch or $year > 9999;
    return if $month < 1     or $month > 12;
    return if $day < 1       or $day > $mdays[ $month - 1 ];
    $days = $day;
    $days += $mdays[$_] for 0 .. $month - 2;
    $days += $range * 365;
    $days += int( ( $range ) / 4 );
    $days -= int( ( $range + $offset ) / 100 );
    $days += int( ( $range + $offset + $norm ) / 400 );
    $days -= $leap;
    $days++ if $date_1904 == 0 and $days > 59;
    return $days + $seconds;
}
sub set_row {
    my $self      = shift;
    my $row       = shift;
    my $height    = shift;
    my $xf        = shift;
    my $hidden    = shift || 0;
    my $level     = shift || 0;
    my $collapsed = shift || 0;
    my $min_col   = 0;
    return unless defined $row;
    my $default_height = $self->{_default_row_height};
    if ( defined $self->{_dim_colmin} ) {
        $min_col = $self->{_dim_colmin};
    }
    return -2 if $self->_check_dimensions( $row, $min_col );
    $height = $default_height if !defined $height;
    if ( $height == 0 ) {
        $hidden = 1;
        $height = $default_height;
    }
    $level = 0 if $level < 0;
    $level = 7 if $level > 7;
    if ( $level > $self->{_outline_row_level} ) {
        $self->{_outline_row_level} = $level;
    }
    $self->{_set_rows}->{$row} = [ $height, $xf, $hidden, $level, $collapsed ];
    $self->{_row_size_changed} = 1;
    $self->{_row_sizes}->{$row} = [$height, $hidden];
}
sub set_default_row {
    my $self        = shift;
    my $height      = shift || $self->{_original_row_height};
    my $zero_height = shift || 0;
    if ( $height != $self->{_original_row_height} ) {
        $self->{_default_row_height} = $height;
        $self->{_row_size_changed} = 1;
    }
    if ( $zero_height ) {
        $self->{_default_row_zeroed} = 1;
    }
}
sub merge_range {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    croak "Incorrect number of arguments" if @_ < 6;
    croak "Fifth parameter must be a format object" unless ref $_[5];
    my $row_first  = shift;
    my $col_first  = shift;
    my $row_last   = shift;
    my $col_last   = shift;
    my $string     = shift;
    my $format     = shift;
    my @extra_args = @_;
    if ( $row_first == $row_last and $col_first == $col_last ) {
        croak "Can't merge single cell";
    }
    ( $row_first, $row_last ) = ( $row_last, $row_first )
      if $row_first > $row_last;
    ( $col_first, $col_last ) = ( $col_last, $col_first )
      if $col_first > $col_last;
    return if $self->_check_dimensions( $row_last, $col_last );
    push @{ $self->{_merge} }, [ $row_first, $col_first, $row_last, $col_last ];
    $self->write( $row_first, $col_first, $string, $format, @extra_args );
    for my $row ( $row_first .. $row_last ) {
        for my $col ( $col_first .. $col_last ) {
            next if $row == $row_first and $col == $col_first;
            $self->write_blank( $row, $col, $format );
        }
    }
}
sub merge_range_type {
    my $self = shift;
    my $type = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    my $row_first = shift;
    my $col_first = shift;
    my $row_last  = shift;
    my $col_last  = shift;
    my $format;
    if (   $type eq 'array_formula'
        || $type eq 'blank'
        || $type eq 'rich_string' )
    {
        $format = $_[-1];
    }
    else {
        $format = $_[1];
    }
    croak "Format object missing or in an incorrect position"
      unless ref $format;
    if ( $row_first == $row_last and $col_first == $col_last ) {
        croak "Can't merge single cell";
    }
    ( $row_first, $row_last ) = ( $row_last, $row_first )
      if $row_first > $row_last;
    ( $col_first, $col_last ) = ( $col_last, $col_first )
      if $col_first > $col_last;
    return if $self->_check_dimensions( $row_last, $col_last );
    push @{ $self->{_merge} }, [ $row_first, $col_first, $row_last, $col_last ];
    if ( $type eq 'string' ) {
        $self->write_string( $row_first, $col_first, @_ );
    }
    elsif ( $type eq 'number' ) {
        $self->write_number( $row_first, $col_first, @_ );
    }
    elsif ( $type eq 'blank' ) {
        $self->write_blank( $row_first, $col_first, @_ );
    }
    elsif ( $type eq 'date_time' ) {
        $self->write_date_time( $row_first, $col_first, @_ );
    }
    elsif ( $type eq 'rich_string' ) {
        $self->write_rich_string( $row_first, $col_first, @_ );
    }
    elsif ( $type eq 'url' ) {
        $self->write_url( $row_first, $col_first, @_ );
    }
    elsif ( $type eq 'formula' ) {
        $self->write_formula( $row_first, $col_first, @_ );
    }
    elsif ( $type eq 'array_formula' ) {
        $self->write_formula_array( $row_first, $col_first, @_ );
    }
    else {
        croak "Unknown type '$type'";
    }
    for my $row ( $row_first .. $row_last ) {
        for my $col ( $col_first .. $col_last ) {
            next if $row == $row_first and $col == $col_first;
            $self->write_blank( $row, $col, $format );
        }
    }
}
sub data_validation {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    if ( @_ != 5 && @_ != 3 ) { return -1 }
    my $param = pop;
    my ( $row1, $col1, $row2, $col2 ) = @_;
    if ( !defined $row2 ) {
        $row2 = $row1;
        $col2 = $col1;
    }
    return -2 if $self->_check_dimensions( $row1, $col1, 1, 1 );
    return -2 if $self->_check_dimensions( $row2, $col2, 1, 1 );
    if ( ref $param ne 'HASH' ) {
        carp "Last parameter '$param' in data_validation() must be a hash ref";
        return -3;
    }
    my %valid_parameter = (
        validate      => 1,
        criteria      => 1,
        value         => 1,
        source        => 1,
        minimum       => 1,
        maximum       => 1,
        ignore_blank  => 1,
        dropdown      => 1,
        show_input    => 1,
        input_title   => 1,
        input_message => 1,
        show_error    => 1,
        error_title   => 1,
        error_message => 1,
        error_type    => 1,
        other_cells   => 1,
    );
    for my $param_key ( keys %$param ) {
        if ( not exists $valid_parameter{$param_key} ) {
            carp "Unknown parameter '$param_key' in data_validation()";
            return -3;
        }
    }
    $param->{value} = $param->{source}  if defined $param->{source};
    $param->{value} = $param->{minimum} if defined $param->{minimum};
    if ( not exists $param->{validate} ) {
        carp "Parameter 'validate' is required in data_validation()";
        return -3;
    }
    my %valid_type = (
        'any'          => 'none',
        'any value'    => 'none',
        'whole number' => 'whole',
        'whole'        => 'whole',
        'integer'      => 'whole',
        'decimal'      => 'decimal',
        'list'         => 'list',
        'date'         => 'date',
        'time'         => 'time',
        'text length'  => 'textLength',
        'length'       => 'textLength',
        'custom'       => 'custom',
    );
    if ( not exists $valid_type{ lc( $param->{validate} ) } ) {
        carp "Unknown validation type '$param->{validate}' for parameter "
          . "'validate' in data_validation()";
        return -3;
    }
    else {
        $param->{validate} = $valid_type{ lc( $param->{validate} ) };
    }
    if (   $param->{validate} eq 'none'
        && !defined $param->{input_message}
        && !defined $param->{input_title} )
    {
        return 0;
    }
    if (   $param->{validate} eq 'none'
        || $param->{validate} eq 'list'
        || $param->{validate} eq 'custom' )
    {
        $param->{criteria} = 'between';
        $param->{maximum}  = undef;
    }
    if ( not exists $param->{criteria} ) {
        carp "Parameter 'criteria' is required in data_validation()";
        return -3;
    }
    my %criteria_type = (
        'between'                  => 'between',
        'not between'              => 'notBetween',
        'equal to'                 => 'equal',
        '='                        => 'equal',
        '=='                       => 'equal',
        'not equal to'             => 'notEqual',
        '!='                       => 'notEqual',
        '<>'                       => 'notEqual',
        'greater than'             => 'greaterThan',
        '>'                        => 'greaterThan',
        'less than'                => 'lessThan',
        '<'                        => 'lessThan',
        'greater than or equal to' => 'greaterThanOrEqual',
        '>='                       => 'greaterThanOrEqual',
        'less than or equal to'    => 'lessThanOrEqual',
        '<='                       => 'lessThanOrEqual',
    );
    if ( not exists $criteria_type{ lc( $param->{criteria} ) } ) {
        carp "Unknown criteria type '$param->{criteria}' for parameter "
          . "'criteria' in data_validation()";
        return -3;
    }
    else {
        $param->{criteria} = $criteria_type{ lc( $param->{criteria} ) };
    }
    if ( $param->{criteria} eq 'between' || $param->{criteria} eq 'notBetween' )
    {
        if ( not exists $param->{maximum} ) {
            carp "Parameter 'maximum' is required in data_validation() "
              . "when using 'between' or 'not between' criteria";
            return -3;
        }
    }
    else {
        $param->{maximum} = undef;
    }
    my %error_type = (
        'stop'        => 0,
        'warning'     => 1,
        'information' => 2,
    );
    if ( not exists $param->{error_type} ) {
        $param->{error_type} = 0;
    }
    elsif ( not exists $error_type{ lc( $param->{error_type} ) } ) {
        carp "Unknown criteria type '$param->{error_type}' for parameter "
          . "'error_type' in data_validation()";
        return -3;
    }
    else {
        $param->{error_type} = $error_type{ lc( $param->{error_type} ) };
    }
    if ( $param->{validate} eq 'date' || $param->{validate} eq 'time' ) {
        my $date_time = $self->convert_date_time( $param->{value} );
        if ( defined $date_time ) {
            $param->{value} = $date_time;
        }
        if ( defined $param->{maximum} ) {
            my $date_time = $self->convert_date_time( $param->{maximum} );
            if ( defined $date_time ) {
                $param->{maximum} = $date_time;
            }
        }
    }
    if ( $param->{input_title} and length $param->{input_title} > 32 ) {
        carp "Length of input title '$param->{input_title}'"
          . " exceeds Excel's limit of 32";
        return -3;
    }
    if ( $param->{error_title} and length $param->{error_title} > 32 ) {
        carp "Length of error title '$param->{error_title}'"
          . " exceeds Excel's limit of 32";
        return -3;
    }
    if ( $param->{input_message} and length $param->{input_message} > 255 ) {
        carp "Length of input message '$param->{input_message}'"
          . " exceeds Excel's limit of 255";
        return -3;
    }
    if ( $param->{error_message} and length $param->{error_message} > 255 ) {
        carp "Length of error message '$param->{error_message}'"
          . " exceeds Excel's limit of 255";
        return -3;
    }
    if ( $param->{validate} eq 'list' ) {
        if ( ref $param->{value} eq 'ARRAY' ) {
            my $formula = join ',', @{ $param->{value} };
            if ( length $formula > 255 ) {
                carp "Length of list items '$formula' exceeds Excel's "
                  . "limit of 255, use a formula range instead";
                return -3;
            }
        }
    }
    $param->{ignore_blank} = 1 if !defined $param->{ignore_blank};
    $param->{dropdown}     = 1 if !defined $param->{dropdown};
    $param->{show_input}   = 1 if !defined $param->{show_input};
    $param->{show_error}   = 1 if !defined $param->{show_error};
    $param->{cells} = [ [ $row1, $col1, $row2, $col2 ] ];
    if ( exists $param->{other_cells} ) {
        push @{ $param->{cells} }, @{ $param->{other_cells} };
    }
    push @{ $self->{_validations} }, $param;
}
sub conditional_formatting {
    my $self       = shift;
    my $user_range = '';
    if ( $_[0] =~ /^\D/ ) {
        if ( $_[0] =~ /,/ ) {
            $user_range = $_[0];
            $user_range =~ s/^=//;
            $user_range =~ s/\s*,\s*/ /g;
            $user_range =~ s/\$//g;
        }
        @_ = $self->_substitute_cellref( @_ );
    }
    my $options = pop;
    my ( $row1, $col1, $row2, $col2 ) = @_;
    if ( !defined $row2 ) {
        $row2 = $row1;
        $col2 = $col1;
    }
    return -2 if $self->_check_dimensions( $row1, $col1, 1, 1 );
    return -2 if $self->_check_dimensions( $row2, $col2, 1, 1 );
    if ( ref $options ne 'HASH' ) {
        carp "Last parameter in conditional_formatting() "
          . "must be a hash ref";
        return -3;
    }
    my $param = {%$options};
    my %valid_parameter = (
        type                           => 1,
        format                         => 1,
        criteria                       => 1,
        value                          => 1,
        minimum                        => 1,
        maximum                        => 1,
        stop_if_true                   => 1,
        min_type                       => 1,
        mid_type                       => 1,
        max_type                       => 1,
        min_value                      => 1,
        mid_value                      => 1,
        max_value                      => 1,
        min_color                      => 1,
        mid_color                      => 1,
        max_color                      => 1,
        bar_color                      => 1,
        bar_negative_color             => 1,
        bar_negative_color_same        => 1,
        bar_solid                      => 1,
        bar_border_color               => 1,
        bar_negative_border_color      => 1,
        bar_negative_border_color_same => 1,
        bar_no_border                  => 1,
        bar_direction                  => 1,
        bar_axis_position              => 1,
        bar_axis_color                 => 1,
        bar_only                       => 1,
        icon_style                     => 1,
        reverse_icons                  => 1,
        icons_only                     => 1,
        icons                          => 1,
        data_bar_2010                  => 1,
    );
    for my $param_key ( keys %$param ) {
        if ( not exists $valid_parameter{$param_key} ) {
            carp "Unknown parameter '$param_key' in conditional_formatting()";
            return -3;
        }
    }
    if ( not exists $param->{type} ) {
        carp "Parameter 'type' is required in conditional_formatting()";
        return -3;
    }
    my %valid_type = (
        'cell'          => 'cellIs',
        'date'          => 'date',
        'time'          => 'time',
        'average'       => 'aboveAverage',
        'duplicate'     => 'duplicateValues',
        'unique'        => 'uniqueValues',
        'top'           => 'top10',
        'bottom'        => 'top10',
        'text'          => 'text',
        'time_period'   => 'timePeriod',
        'blanks'        => 'containsBlanks',
        'no_blanks'     => 'notContainsBlanks',
        'errors'        => 'containsErrors',
        'no_errors'     => 'notContainsErrors',
        '2_color_scale' => '2_color_scale',
        '3_color_scale' => '3_color_scale',
        'data_bar'      => 'dataBar',
        'formula'       => 'expression',
        'icon_set'      => 'iconSet',
    );
    if ( not exists $valid_type{ lc( $param->{type} ) } ) {
        carp "Unknown validation type '$param->{type}' for parameter "
          . "'type' in conditional_formatting()";
        return -3;
    }
    else {
        $param->{direction} = 'bottom' if $param->{type} eq 'bottom';
        $param->{type} = $valid_type{ lc( $param->{type} ) };
    }
    my %criteria_type = (
        'between'                  => 'between',
        'not between'              => 'notBetween',
        'equal to'                 => 'equal',
        '='                        => 'equal',
        '=='                       => 'equal',
        'not equal to'             => 'notEqual',
        '!='                       => 'notEqual',
        '<>'                       => 'notEqual',
        'greater than'             => 'greaterThan',
        '>'                        => 'greaterThan',
        'less than'                => 'lessThan',
        '<'                        => 'lessThan',
        'greater than or equal to' => 'greaterThanOrEqual',
        '>='                       => 'greaterThanOrEqual',
        'less than or equal to'    => 'lessThanOrEqual',
        '<='                       => 'lessThanOrEqual',
        'containing'               => 'containsText',
        'not containing'           => 'notContains',
        'begins with'              => 'beginsWith',
        'ends with'                => 'endsWith',
        'yesterday'                => 'yesterday',
        'today'                    => 'today',
        'last 7 days'              => 'last7Days',
        'last week'                => 'lastWeek',
        'this week'                => 'thisWeek',
        'next week'                => 'nextWeek',
        'last month'               => 'lastMonth',
        'this month'               => 'thisMonth',
        'next month'               => 'nextMonth',
    );
    if ( defined $param->{criteria}
        && exists $criteria_type{ lc( $param->{criteria} ) } )
    {
        $param->{criteria} = $criteria_type{ lc( $param->{criteria} ) };
    }
    if ( $param->{type} eq 'date' || $param->{type} eq 'time' ) {
        $param->{type} = 'cellIs';
        if ( defined $param->{value} && $param->{value} =~ /T/ ) {
            my $date_time = $self->convert_date_time( $param->{value} );
            if ( !defined $date_time ) {
                carp "Invalid date/time value '$param->{value}' "
                  . "in conditional_formatting()";
                return -3;
            }
            else {
                $param->{value} = $date_time;
            }
        }
        if ( defined $param->{minimum} && $param->{minimum} =~ /T/ ) {
            my $date_time = $self->convert_date_time( $param->{minimum} );
            if ( !defined $date_time ) {
                carp "Invalid date/time value '$param->{minimum}' "
                  . "in conditional_formatting()";
                return -3;
            }
            else {
                $param->{minimum} = $date_time;
            }
        }
        if ( defined $param->{maximum} && $param->{maximum} =~ /T/ ) {
            my $date_time = $self->convert_date_time( $param->{maximum} );
            if ( !defined $date_time ) {
                carp "Invalid date/time value '$param->{maximum}' "
                  . "in conditional_formatting()";
                return -3;
            }
            else {
                $param->{maximum} = $date_time;
            }
        }
    }
    my %icon_set_styles = (
        "3_arrows"                => "3Arrows",
        "3_flags"                 => "3Flags",
        "3_traffic_lights_rimmed" => "3TrafficLights2",
        "3_symbols_circled"       => "3Symbols",
        "4_arrows"                => "4Arrows",
        "4_red_to_black"          => "4RedToBlack",
        "4_traffic_lights"        => "4TrafficLights",
        "5_arrows_gray"           => "5ArrowsGray",
        "5_quarters"              => "5Quarters",
        "3_arrows_gray"           => "3ArrowsGray",
        "3_traffic_lights"        => "3TrafficLights",
        "3_signs"                 => "3Signs",
        "3_symbols"               => "3Symbols2",
        "4_arrows_gray"           => "4ArrowsGray",
        "4_ratings"               => "4Rating",
        "5_arrows"                => "5Arrows",
        "5_ratings"               => "5Rating",
    );
    if ( $param->{type} eq 'iconSet' ) {
        if ( !defined $param->{icon_style} ) {
            carp "The 'icon_style' parameter must be specified when "
              . "'type' == 'icon_set' in conditional_formatting()";
            return -3;
        }
        if ( not exists $icon_set_styles{ $param->{icon_style} } ) {
            carp "Unknown icon style '$param->{icon_style}' for parameter "
              . "'icon_style' in conditional_formatting()";
            return -3;
        }
        else {
            $param->{icon_style} = $icon_set_styles{ $param->{icon_style} };
        }
        $param->{total_icons} = 3;
        if ( $param->{icon_style} =~ /^4/ ) {
            $param->{total_icons} = 4;
        }
        elsif ( $param->{icon_style} =~ /^5/ ) {
            $param->{total_icons} = 5;
        }
        $param->{icons} =
          $self->_set_icon_properties( $param->{total_icons}, $param->{icons} );
    }
    my $range      = '';
    my $start_cell = '';
    if ( $row1 > $row2 ) {
        ( $row1, $row2 ) = ( $row2, $row1 );
    }
    if ( $col1 > $col2 ) {
        ( $col1, $col2 ) = ( $col2, $col1 );
    }
    if ( ( $row1 == $row2 ) && ( $col1 == $col2 ) ) {
        $range = xl_rowcol_to_cell( $row1, $col1 );
        $start_cell = $range;
    }
    else {
        $range = xl_range( $row1, $row2, $col1, $col2 );
        $start_cell = xl_rowcol_to_cell( $row1, $col1 );
    }
    if ( $user_range ) {
        $range = $user_range;
    }
    if ( defined $param->{format} && ref $param->{format} ) {
        $param->{format} = $param->{format}->get_dxf_index();
    }
    $param->{priority} = $self->{_dxf_priority}++;
    if (   $self->{_use_data_bars_2010}
        || $param->{data_bar_2010}
        || $param->{bar_solid}
        || $param->{bar_border_color}
        || $param->{bar_negative_color}
        || $param->{bar_negative_color_same}
        || $param->{bar_negative_border_color}
        || $param->{bar_negative_border_color_same}
        || $param->{bar_no_border}
        || $param->{bar_axis_position}
        || $param->{bar_axis_color}
        || $param->{bar_direction} )
    {
        $param->{_is_data_bar_2010} = 1;
    }
    if ( $param->{type} eq 'text' ) {
        if ( $param->{criteria} eq 'containsText' ) {
            $param->{type}    = 'containsText';
            $param->{formula} = sprintf 'NOT(ISERROR(SEARCH("%s",%s)))',
              $param->{value}, $start_cell;
        }
        elsif ( $param->{criteria} eq 'notContains' ) {
            $param->{type}    = 'notContainsText';
            $param->{formula} = sprintf 'ISERROR(SEARCH("%s",%s))',
              $param->{value}, $start_cell;
        }
        elsif ( $param->{criteria} eq 'beginsWith' ) {
            $param->{type}    = 'beginsWith';
            $param->{formula} = sprintf 'LEFT(%s,%d)="%s"',
              $start_cell, length( $param->{value} ), $param->{value};
        }
        elsif ( $param->{criteria} eq 'endsWith' ) {
            $param->{type}    = 'endsWith';
            $param->{formula} = sprintf 'RIGHT(%s,%d)="%s"',
              $start_cell, length( $param->{value} ), $param->{value};
        }
        else {
            carp "Invalid text criteria '$param->{criteria}' "
              . "in conditional_formatting()";
        }
    }
    if ( $param->{type} eq 'timePeriod' ) {
        if ( $param->{criteria} eq 'yesterday' ) {
            $param->{formula} = sprintf 'FLOOR(%s,1)=TODAY()-1', $start_cell;
        }
        elsif ( $param->{criteria} eq 'today' ) {
            $param->{formula} = sprintf 'FLOOR(%s,1)=TODAY()', $start_cell;
        }
        elsif ( $param->{criteria} eq 'tomorrow' ) {
            $param->{formula} = sprintf 'FLOOR(%s,1)=TODAY()+1', $start_cell;
        }
        elsif ( $param->{criteria} eq 'last7Days' ) {
            $param->{formula} =
              sprintf 'AND(TODAY()-FLOOR(%s,1)<=6,FLOOR(%s,1)<=TODAY())',
              $start_cell, $start_cell;
        }
        elsif ( $param->{criteria} eq 'lastWeek' ) {
            $param->{formula} =
              sprintf 'AND(TODAY()-ROUNDDOWN(%s,0)>=(WEEKDAY(TODAY())),'
              . 'TODAY()-ROUNDDOWN(%s,0)<(WEEKDAY(TODAY())+7))',
              $start_cell, $start_cell;
        }
        elsif ( $param->{criteria} eq 'thisWeek' ) {
            $param->{formula} =
              sprintf 'AND(TODAY()-ROUNDDOWN(%s,0)<=WEEKDAY(TODAY())-1,'
              . 'ROUNDDOWN(%s,0)-TODAY()<=7-WEEKDAY(TODAY()))',
              $start_cell, $start_cell;
        }
        elsif ( $param->{criteria} eq 'nextWeek' ) {
            $param->{formula} =
              sprintf 'AND(ROUNDDOWN(%s,0)-TODAY()>(7-WEEKDAY(TODAY())),'
              . 'ROUNDDOWN(%s,0)-TODAY()<(15-WEEKDAY(TODAY())))',
              $start_cell, $start_cell;
        }
        elsif ( $param->{criteria} eq 'lastMonth' ) {
            $param->{formula} =
              sprintf
              'AND(MONTH(%s)=MONTH(TODAY())-1,OR(YEAR(%s)=YEAR(TODAY()),'
              . 'AND(MONTH(%s)=1,YEAR(A1)=YEAR(TODAY())-1)))',
              $start_cell, $start_cell, $start_cell;
        }
        elsif ( $param->{criteria} eq 'thisMonth' ) {
            $param->{formula} =
              sprintf 'AND(MONTH(%s)=MONTH(TODAY()),YEAR(%s)=YEAR(TODAY()))',
              $start_cell, $start_cell;
        }
        elsif ( $param->{criteria} eq 'nextMonth' ) {
            $param->{formula} =
              sprintf
              'AND(MONTH(%s)=MONTH(TODAY())+1,OR(YEAR(%s)=YEAR(TODAY()),'
              . 'AND(MONTH(%s)=12,YEAR(%s)=YEAR(TODAY())+1)))',
              $start_cell, $start_cell, $start_cell, $start_cell;
        }
        else {
            carp "Invalid time_period criteria '$param->{criteria}' "
              . "in conditional_formatting()";
        }
    }
    if ( $param->{type} eq 'containsBlanks' ) {
        $param->{formula} = sprintf 'LEN(TRIM(%s))=0', $start_cell;
    }
    if ( $param->{type} eq 'notContainsBlanks' ) {
        $param->{formula} = sprintf 'LEN(TRIM(%s))>0', $start_cell;
    }
    if ( $param->{type} eq 'containsErrors' ) {
        $param->{formula} = sprintf 'ISERROR(%s)', $start_cell;
    }
    if ( $param->{type} eq 'notContainsErrors' ) {
        $param->{formula} = sprintf 'NOT(ISERROR(%s))', $start_cell;
    }
    if ( $param->{type} eq '2_color_scale' ) {
        $param->{type} = 'colorScale';
        $param->{format} = undef;
        $param->{mid_type}  = undef;
        $param->{mid_color} = undef;
        $param->{min_type}  ||= 'min';
        $param->{max_type}  ||= 'max';
        $param->{min_value} ||= 0;
        $param->{max_value} ||= 0;
        $param->{min_color} ||= '#FF7128';
        $param->{max_color} ||= '#FFEF9C';
        $param->{max_color} = $self->_get_palette_color( $param->{max_color} );
        $param->{min_color} = $self->_get_palette_color( $param->{min_color} );
    }
    if ( $param->{type} eq '3_color_scale' ) {
        $param->{type} = 'colorScale';
        $param->{format} = undef;
        $param->{min_type}  ||= 'min';
        $param->{mid_type}  ||= 'percentile';
        $param->{max_type}  ||= 'max';
        $param->{min_value} ||= 0;
        $param->{mid_value} = 50 unless defined $param->{mid_value};
        $param->{max_value} ||= 0;
        $param->{min_color} ||= '#F8696B';
        $param->{mid_color} ||= '#FFEB84';
        $param->{max_color} ||= '#63BE7B';
        $param->{max_color} = $self->_get_palette_color( $param->{max_color} );
        $param->{mid_color} = $self->_get_palette_color( $param->{mid_color} );
        $param->{min_color} = $self->_get_palette_color( $param->{min_color} );
    }
    if ( $param->{type} eq 'dataBar' ) {
        $param->{format} = undef;
        if ( !defined $param->{min_type} ) {
            $param->{min_type}      = 'min';
            $param->{_x14_min_type} = 'autoMin';
        }
        else {
            $param->{_x14_min_type} = $param->{min_type};
        }
        if ( !defined $param->{max_type} ) {
            $param->{max_type}      = 'max';
            $param->{_x14_max_type} = 'autoMax';
        }
        else {
            $param->{_x14_max_type} = $param->{max_type};
        }
        $param->{min_value}                      ||= 0;
        $param->{max_value}                      ||= 0;
        $param->{bar_color}                      ||= '#638EC6';
        $param->{bar_border_color}               ||= $param->{bar_color};
        $param->{bar_only}                       ||= 0;
        $param->{bar_no_border}                  ||= 0;
        $param->{bar_solid}                      ||= 0;
        $param->{bar_direction}                  ||= '';
        $param->{bar_negative_color}             ||= '#FF0000';
        $param->{bar_negative_border_color}      ||= '#FF0000';
        $param->{bar_negative_color_same}        ||= 0;
        $param->{bar_negative_border_color_same} ||= 0;
        $param->{bar_axis_position}              ||= '';
        $param->{bar_axis_color}                 ||= '#000000';
        $param->{bar_color} =
          $self->_get_palette_color( $param->{bar_color} );
        $param->{bar_border_color} =
          $self->_get_palette_color( $param->{bar_border_color} );
        $param->{bar_negative_color} =
          $self->_get_palette_color( $param->{bar_negative_color} );
        $param->{bar_negative_border_color} =
          $self->_get_palette_color( $param->{bar_negative_border_color} );
        $param->{bar_axis_color} =
          $self->_get_palette_color( $param->{bar_axis_color} );
    }
    if ( $param->{_is_data_bar_2010} ) {
        $self->{_excel_version} = 2010;
        if ( $param->{min_type} eq 'min' && $param->{min_value} == 0 ) {
            $param->{min_value} = undef;
        }
        if ( $param->{max_type} eq 'max' && $param->{max_value} == 0 ) {
            $param->{max_value} = undef;
        }
        $param->{_range} = $range;
    }
    $param->{min_value} =~ s/^=// if defined $param->{min_value};
    $param->{mid_value} =~ s/^=// if defined $param->{mid_value};
    $param->{max_value} =~ s/^=// if defined $param->{max_value};
    push @{ $self->{_cond_formats}->{$range} }, $param;
}
sub _set_icon_properties {
    my $self        = shift;
    my $total_icons = shift;
    my $user_props  = shift;
    my $props       = [];
    for ( 0 .. $total_icons - 1 ) {
        push @$props,
          {
            criteria => 0,
            value    => 0,
            type     => 'percent'
          };
    }
    if ( $total_icons == 3 ) {
        $props->[0]->{value} = 67;
        $props->[1]->{value} = 33;
    }
    if ( $total_icons == 4 ) {
        $props->[0]->{value} = 75;
        $props->[1]->{value} = 50;
        $props->[2]->{value} = 25;
    }
    if ( $total_icons == 5 ) {
        $props->[0]->{value} = 80;
        $props->[1]->{value} = 60;
        $props->[2]->{value} = 40;
        $props->[3]->{value} = 20;
    }
    if ( defined $user_props ) {
        my $max_data = @$user_props;
        if ( $max_data >= $total_icons ) {
            $max_data = $total_icons -1;
        }
        for my $i ( 0 .. $max_data - 1 ) {
            if ( defined $user_props->[$i]->{value} ) {
                $props->[$i]->{value} = $user_props->[$i]->{value};
                $props->[$i]->{value} =~ s/^=//;
            }
            if ( defined $user_props->[$i]->{type} ) {
                my $type = $user_props->[$i]->{type};
                if (   $type ne 'percent'
                    && $type ne 'percentile'
                    && $type ne 'number'
                    && $type ne 'formula' )
                {
                    carp "Unknown icon property type '$props->{type}' for sub-"
                      . "property 'type' in conditional_formatting()";
                }
                else {
                    $props->[$i]->{type} = $type;
                    if ( $props->[$i]->{type} eq 'number' ) {
                        $props->[$i]->{type} = 'num';
                    }
                }
            }
            if ( defined $user_props->[$i]->{criteria}
                && $user_props->[$i]->{criteria} eq '>' )
            {
                $props->[$i]->{criteria} = 1;
            }
        }
    }
    return $props;
}
sub add_table {
    my $self       = shift;
    my $user_range = '';
    my %table;
    my @col_formats;
    if ( $self->{_optimization} == 1 ) {
        carp "add_table() isn't supported when set_optimization() is on";
        return -1;
    }
    if ( @_ && $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    if ( @_ < 4 ) {
        carp "Not enough parameters to add_table()";
        return -1;
    }
    my ( $row1, $col1, $row2, $col2 ) = @_;
    return -2 if $self->_check_dimensions( $row1, $col1, 1, 1 );
    return -2 if $self->_check_dimensions( $row2, $col2, 1, 1 );
    my $param = $_[4] || {};
    if ( ref $param ne 'HASH' ) {
        carp "Last parameter '$param' in add_table() must be a hash ref";
        return -3;
    }
    my %valid_parameter = (
        autofilter     => 1,
        banded_columns => 1,
        banded_rows    => 1,
        columns        => 1,
        data           => 1,
        first_column   => 1,
        header_row     => 1,
        last_column    => 1,
        name           => 1,
        style          => 1,
        total_row      => 1,
    );
    for my $param_key ( keys %$param ) {
        if ( not exists $valid_parameter{$param_key} ) {
            carp "Unknown parameter '$param_key' in add_table()";
            return -3;
        }
    }
    $param->{banded_rows} = 1 if !defined $param->{banded_rows};
    $param->{header_row}  = 1 if !defined $param->{header_row};
    $param->{autofilter}  = 1 if !defined $param->{autofilter};
    $table{_show_first_col}   = $param->{first_column}   ? 1 : 0;
    $table{_show_last_col}    = $param->{last_column}    ? 1 : 0;
    $table{_show_row_stripes} = $param->{banded_rows}    ? 1 : 0;
    $table{_show_col_stripes} = $param->{banded_columns} ? 1 : 0;
    $table{_header_row_count} = $param->{header_row}     ? 1 : 0;
    $table{_totals_row_shown} = $param->{total_row}      ? 1 : 0;
    if ( defined $param->{name} ) {
        my $name = $param->{name};
        if ( $name !~ m/^[\w\\][\w\\.]*$/ || $name =~ m/^\d/ ) {
            carp "Invalid character in name '$name' used in add_table()";
            return -3;
        }
        if ( $name =~ m/^[a-zA-Z][a-zA-Z]?[a-dA-D]?[0-9]+$/ ) {
            carp "Invalid name '$name' looks like a cell name in add_table()";
            return -3;
        }
        if ( $name =~ m/^[rcRC]$/ || $name =~ m/^[rcRC]\d+[rcRC]\d+$/ ) {
            carp "Invalid name '$name' like a RC cell ref in add_table()";
            return -3;
        }
        $table{_name} = $param->{name};
    }
    if ( defined $param->{style} ) {
        $table{_style} = $param->{style};
        $table{_style} =~ s/\s//g;
    }
    else {
        $table{_style} = "TableStyleMedium9";
    }
    if ( $row1 > $row2 ) {
        ( $row1, $row2 ) = ( $row2, $row1 );
    }
    if ( $col1 > $col2 ) {
        ( $col1, $col2 ) = ( $col2, $col1 );
    }
    my $first_data_row = $row1;
    my $last_data_row  = $row2;
    $first_data_row++ if $param->{header_row};
    $last_data_row--  if $param->{total_row};
    $table{_range}   = xl_range( $row1, $row2,          $col1, $col2 );
    $table{_a_range} = xl_range( $row1, $last_data_row, $col1, $col2 );
    if ( !$param->{header_row} ) {
        $param->{autofilter} = 0;
    }
    if ( $param->{autofilter} ) {
        $table{_autofilter} = $table{_a_range};
    }
    my %seen_names;
    my $col_id = 1;
    for my $col_num ( $col1 .. $col2 ) {
        my $col_data = {
            _id             => $col_id,
            _name           => 'Column' . $col_id,
            _total_string   => '',
            _total_function => '',
            _formula        => '',
            _format         => undef,
            _name_format    => undef,
        };
        if ( $param->{columns} ) {
            if ( my $user_data = $param->{columns}->[ $col_id - 1 ] ) {
                $col_data->{_name} = $user_data->{header}
                  if $user_data->{header};
                my $name = $col_data->{_name};
                my $key = lc $name;
                if (exists $seen_names{$key}) {
                    carp "add_table() contains duplicate name: '$name'";
                    return -1;
                }
                else {
                    $seen_names{$key} = 1;
                }
                $col_data->{_name_format} = $user_data->{header_format};
                if ( $user_data->{formula} ) {
                    my $formula = $user_data->{formula};
                    $formula =~ s/^=//;
                    $formula =~ s/@/[#This Row],/g;
                    $col_data->{_formula} = $formula;
                    for my $row ( $first_data_row .. $last_data_row ) {
                        $self->write_formula( $row, $col_num, $formula,
                            $user_data->{format} );
                    }
                }
                if ( $user_data->{total_function} ) {
                    my $function = $user_data->{total_function};
                    $function = lc $function;
                    $function =~ s/_//g;
                    $function =~ s/\s//g;
                    $function = 'countNums' if $function eq 'countnums';
                    $function = 'stdDev'    if $function eq 'stddev';
                    $col_data->{_total_function} = $function;
                    my $formula = _table_function_to_formula(
                        $function,
                        $col_data->{_name}
                    );
                    my $value = $user_data->{total_value} || 0;
                    $self->write_formula( $row2, $col_num, $formula,
                        $user_data->{format}, $value );
                }
                elsif ( $user_data->{total_string} ) {
                    my $total_string = $user_data->{total_string};
                    $col_data->{_total_string} = $total_string;
                    $self->write_string( $row2, $col_num, $total_string,
                        $user_data->{format} );
                }
                if ( defined $user_data->{format} && ref $user_data->{format} )
                {
                    $col_data->{_format} =
                      $user_data->{format}->get_dxf_index();
                }
                $col_formats[ $col_id - 1 ] = $user_data->{format};
            }
        }
        push @{ $table{_columns} }, $col_data;
        if ( $param->{header_row} ) {
            $self->write_string( $row1, $col_num, $col_data->{_name},
                $col_data->{_name_format} );
        }
        $col_id++;
    }
    if ( my $data = $param->{data} ) {
        my $i = 0;
        for my $row ( $first_data_row .. $last_data_row ) {
            my $j = 0;
            for my $col ( $col1 .. $col2 ) {
                my $token = $data->[$i]->[$j];
                if ( defined $token ) {
                    $self->write( $row, $col, $token, $col_formats[$j] );
                }
                $j++;
            }
            $i++;
        }
    }
    push @{ $self->{_tables} }, \%table;
    return \%table;
}
sub add_sparkline {
    my $self      = shift;
    my $param     = shift;
    my $sparkline = {};
    if ( ref $param ne 'HASH' ) {
        carp "Parameter list in add_sparkline() must be a hash ref";
        return -1;
    }
    my %valid_parameter = (
        location        => 1,
        range           => 1,
        type            => 1,
        high_point      => 1,
        low_point       => 1,
        negative_points => 1,
        first_point     => 1,
        last_point      => 1,
        markers         => 1,
        style           => 1,
        series_color    => 1,
        negative_color  => 1,
        markers_color   => 1,
        first_color     => 1,
        last_color      => 1,
        high_color      => 1,
        low_color       => 1,
        max             => 1,
        min             => 1,
        axis            => 1,
        reverse         => 1,
        empty_cells     => 1,
        show_hidden     => 1,
        plot_hidden     => 1,
        date_axis       => 1,
        weight          => 1,
    );
    for my $param_key ( keys %$param ) {
        if ( not exists $valid_parameter{$param_key} ) {
            carp "Unknown parameter '$param_key' in add_sparkline()";
            return -2;
        }
    }
    if ( not exists $param->{location} ) {
        carp "Parameter 'location' is required in add_sparkline()";
        return -3;
    }
    if ( not exists $param->{range} ) {
        carp "Parameter 'range' is required in add_sparkline()";
        return -3;
    }
    my $type = $param->{type} || 'line';
    if ( $type ne 'line' && $type ne 'column' && $type ne 'win_loss' ) {
        carp "Parameter 'type' must be 'line', 'column' "
          . "or 'win_loss' in add_sparkline()";
        return -4;
    }
    $type = 'stacked' if $type eq 'win_loss';
    $sparkline->{_type} = $type;
    if ( ref $param->{location} ) {
        $sparkline->{_locations} = $param->{location};
        $sparkline->{_ranges}    = $param->{range};
    }
    else {
        $sparkline->{_locations} = [ $param->{location} ];
        $sparkline->{_ranges}    = [ $param->{range} ];
    }
    my $range_count    = @{ $sparkline->{_ranges} };
    my $location_count = @{ $sparkline->{_locations} };
    if ( $range_count != $location_count ) {
        carp "Must have the same number of location and range "
          . "parameters in add_sparkline()";
        return -5;
    }
    $sparkline->{_count} = @{ $sparkline->{_locations} };
    my $sheetname = quote_sheetname( $self->{_name} );
    for my $range ( @{ $sparkline->{_ranges} } ) {
        $range =~ s{\$}{}g;
        $range =~ s{^=}{};
        if ( $range !~ /!/ ) {
            $range = $sheetname . "!" . $range;
        }
    }
    for my $location ( @{ $sparkline->{_locations} } ) {
        $location =~ s{\$}{}g;
    }
    $sparkline->{_high}     = $param->{high_point};
    $sparkline->{_low}      = $param->{low_point};
    $sparkline->{_negative} = $param->{negative_points};
    $sparkline->{_first}    = $param->{first_point};
    $sparkline->{_last}     = $param->{last_point};
    $sparkline->{_markers}  = $param->{markers};
    $sparkline->{_min}      = $param->{min};
    $sparkline->{_max}      = $param->{max};
    $sparkline->{_axis}     = $param->{axis};
    $sparkline->{_reverse}  = $param->{reverse};
    $sparkline->{_hidden}   = $param->{show_hidden};
    $sparkline->{_weight}   = $param->{weight};
    my $empty = $param->{empty_cells} || '';
    if ( $empty eq 'zero' ) {
        $sparkline->{_empty} = 0;
    }
    elsif ( $empty eq 'connect' ) {
        $sparkline->{_empty} = 'span';
    }
    else {
        $sparkline->{_empty} = 'gap';
    }
    my $date_range = $param->{date_axis};
    if ( $date_range && $date_range !~ /!/ ) {
        $date_range = $sheetname . "!" . $date_range;
    }
    $sparkline->{_date_axis} = $date_range;
    my $style_id = $param->{style} || 0;
    my $style = $Excel::Writer::XLSX::Package::Theme::spark_styles[$style_id];
    $sparkline->{_series_color}   = $style->{series};
    $sparkline->{_negative_color} = $style->{negative};
    $sparkline->{_markers_color}  = $style->{markers};
    $sparkline->{_first_color}    = $style->{first};
    $sparkline->{_last_color}     = $style->{last};
    $sparkline->{_high_color}     = $style->{high};
    $sparkline->{_low_color}      = $style->{low};
    $self->_set_spark_color( $sparkline, $param, 'series_color' );
    $self->_set_spark_color( $sparkline, $param, 'negative_color' );
    $self->_set_spark_color( $sparkline, $param, 'markers_color' );
    $self->_set_spark_color( $sparkline, $param, 'first_color' );
    $self->_set_spark_color( $sparkline, $param, 'last_color' );
    $self->_set_spark_color( $sparkline, $param, 'high_color' );
    $self->_set_spark_color( $sparkline, $param, 'low_color' );
    push @{ $self->{_sparklines} }, $sparkline;
}
sub insert_button {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    if ( @_ < 3 ) { return -1 }
    my $button = $self->_button_params( @_ );
    push @{ $self->{_buttons_array} }, $button;
    $self->{_has_vml} = 1;
}
sub set_vba_name {
    my $self         = shift;
    my $vba_codemame = shift;
    if ( $vba_codemame ) {
        $self->{_vba_codename} = $vba_codemame;
    }
    else {
        $self->{_vba_codename} = "Sheet" . ($self->{_index} + 1);
    }
}
sub _table_function_to_formula {
    my $function = shift;
    my $col_name = shift;
    my $formula  = '';
    $col_name =~ s/'/''/g;
    $col_name =~ s/#/'#/g;
    $col_name =~ s/\[/'[/g;
    $col_name =~ s/]/']/g;
    my %subtotals = (
        average   => 101,
        countNums => 102,
        count     => 103,
        max       => 104,
        min       => 105,
        stdDev    => 107,
        sum       => 109,
        var       => 110,
    );
    if ( exists $subtotals{$function} ) {
        my $func_num = $subtotals{$function};
        $formula = qq{SUBTOTAL($func_num,[$col_name])};
    }
    else {
        carp "Unsupported function '$function' in add_table()";
    }
    return $formula;
}
sub _set_spark_color {
    my $self        = shift;
    my $sparkline   = shift;
    my $param       = shift;
    my $user_color  = shift;
    my $spark_color = '_' . $user_color;
    return unless $param->{$user_color};
    $sparkline->{$spark_color} =
      { _rgb => $self->_get_palette_color( $param->{$user_color} ) };
}
sub _get_palette_color {
    my $self    = shift;
    my $index   = shift;
    my $palette = $self->{_palette};
    if ( $index =~ m/^#([0-9A-F]{6})$/i ) {
        return "FF" . uc( $1 );
    }
    $index -= 8;
    my @rgb = @{ $palette->[$index] };
    return sprintf "FF%02X%02X%02X", @rgb[0, 1, 2];
}
sub _substitute_cellref {
    my $self = shift;
    my $cell = uc( shift );
    if ( $cell =~ /\$?([A-Z]{1,3}):\$?([A-Z]{1,3})/ ) {
        my ( $row1, $col1 ) = $self->_cell_to_rowcol( $1 . '1' );
        my ( $row2, $col2 ) =
          $self->_cell_to_rowcol( $2 . $self->{_xls_rowmax} );
        return $row1, $col1, $row2, $col2, @_;
    }
    if ( $cell =~ /\$?([A-Z]{1,3}\$?\d+):\$?([A-Z]{1,3}\$?\d+)/ ) {
        my ( $row1, $col1 ) = $self->_cell_to_rowcol( $1 );
        my ( $row2, $col2 ) = $self->_cell_to_rowcol( $2 );
        return $row1, $col1, $row2, $col2, @_;
    }
    if ( $cell =~ /\$?([A-Z]{1,3}\$?\d+)/ ) {
        my ( $row1, $col1 ) = $self->_cell_to_rowcol( $1 );
        return $row1, $col1, @_;
    }
    croak( "Unknown cell reference $cell" );
}
sub _cell_to_rowcol {
    my $self = shift;
    my $cell = $_[0];
    $cell =~ /(\$?)([A-Z]{1,3})(\$?)(\d+)/;
    my $col_abs = $1 eq "" ? 0 : 1;
    my $col     = $2;
    my $row_abs = $3 eq "" ? 0 : 1;
    my $row     = $4;
    my @chars = split //, $col;
    my $expn = 0;
    $col = 0;
    while ( @chars ) {
        my $char = pop( @chars );
        $col += ( ord( $char ) - ord( 'A' ) + 1 ) * ( 26**$expn );
        $expn++;
    }
    $row--;
    $col--;
    return $row, $col, $row_abs, $col_abs;
}
our @col_names = ( 'A' .. 'XFD' );
sub _xl_rowcol_to_cell {
    return $col_names[ $_[1] ] . ( $_[0] + 1 );
}
sub _sort_pagebreaks {
    my $self = shift;
    return () unless @_;
    my %hash;
    my @array;
    @hash{@_} = undef;
    @array = sort { $a <=> $b } keys %hash;
    shift @array if $array[0] == 0;
    my $max_num_breaks = 1023;
    splice( @array, $max_num_breaks ) if @array > $max_num_breaks;
    return @array;
}
sub _check_dimensions {
    my $self       = shift;
    my $row        = $_[0];
    my $col        = $_[1];
    my $ignore_row = $_[2];
    my $ignore_col = $_[3];
    return -2 if not defined $row;
    return -2 if $row >= $self->{_xls_rowmax};
    return -2 if not defined $col;
    return -2 if $col >= $self->{_xls_colmax};
    if ( !$ignore_row && !$ignore_col && $self->{_optimization} == 1 ) {
        return -2 if $row < $self->{_previous_row};
    }
    if ( !$ignore_row ) {
        if ( not defined $self->{_dim_rowmin} or $row < $self->{_dim_rowmin} ) {
            $self->{_dim_rowmin} = $row;
        }
        if ( not defined $self->{_dim_rowmax} or $row > $self->{_dim_rowmax} ) {
            $self->{_dim_rowmax} = $row;
        }
    }
    if ( !$ignore_col ) {
        if ( not defined $self->{_dim_colmin} or $col < $self->{_dim_colmin} ) {
            $self->{_dim_colmin} = $col;
        }
        if ( not defined $self->{_dim_colmax} or $col > $self->{_dim_colmax} ) {
            $self->{_dim_colmax} = $col;
        }
    }
    return 0;
}
sub _position_object_pixels {
    my $self = shift;
    my $col_start;
    my $x1;
    my $row_start;
    my $y1;
    my $col_end;
    my $x2;
    my $row_end;
    my $y2;
    my $width;
    my $height;
    my $x_abs = 0;
    my $y_abs = 0;
    my $anchor;
    ( $col_start, $row_start, $x1, $y1, $width, $height, $anchor ) = @_;
    while ( $x1 < 0 && $col_start > 0) {
        $x1 += $self->_size_col( $col_start  - 1);
        $col_start--;
    }
    while ( $y1 < 0 && $row_start > 0) {
        $y1 += $self->_size_row( $row_start - 1);
        $row_start--;
    }
    $x1 = 0 if $x1 < 0;
    $y1 = 0 if $y1 < 0;
    if ( $self->{_col_size_changed} ) {
        for my $col_id ( 0 .. $col_start -1 ) {
            $x_abs += $self->_size_col( $col_id );
        }
    }
    else {
        $x_abs += $self->{_default_col_pixels} * $col_start;
    }
    $x_abs += $x1;
    if ( $self->{_row_size_changed} ) {
        for my $row_id ( 0 .. $row_start -1 ) {
            $y_abs += $self->_size_row( $row_id );
        }
    }
    else {
        $y_abs += $self->{_default_row_pixels} * $row_start;
    }
    $y_abs += $y1;
    while ( $x1 >= $self->_size_col( $col_start, $anchor ) ) {
        $x1 -= $self->_size_col( $col_start );
        $col_start++;
    }
    while ( $y1 >= $self->_size_row( $row_start, $anchor ) ) {
        $y1 -= $self->_size_row( $row_start );
        $row_start++;
    }
    $col_end = $col_start;
    $row_end = $row_start;
    if ($self->_size_col( $col_start, $anchor) > 0 ) {
        $width  = $width + $x1;
    }
    if ( $self->_size_row( $row_start, $anchor ) > 0 ) {
        $height = $height + $y1;
    }
    while ( $width >= $self->_size_col( $col_end, $anchor ) ) {
        $width -= $self->_size_col( $col_end, $anchor );
        $col_end++;
    }
    while ( $height >= $self->_size_row( $row_end, $anchor ) ) {
        $height -= $self->_size_row( $row_end, $anchor );
        $row_end++;
    }
    $x2 = $width;
    $y2 = $height;
    return (
        $col_start, $row_start, $x1, $y1,
        $col_end,   $row_end,   $x2, $y2,
        $x_abs,     $y_abs
    );
}
sub _position_object_emus {
    my $self       = shift;
    my (
        $col_start, $row_start, $x1, $y1,
        $col_end,   $row_end,   $x2, $y2,
        $x_abs,     $y_abs
    ) = $self->_position_object_pixels( @_ );
    $x1    = int( 0.5 + 9_525 * $x1 );
    $y1    = int( 0.5 + 9_525 * $y1 );
    $x2    = int( 0.5 + 9_525 * $x2 );
    $y2    = int( 0.5 + 9_525 * $y2 );
    $x_abs = int( 0.5 + 9_525 * $x_abs );
    $y_abs = int( 0.5 + 9_525 * $y_abs );
    return (
        $col_start, $row_start, $x1, $y1,
        $col_end,   $row_end,   $x2, $y2,
        $x_abs,     $y_abs
    );
}
sub _position_shape_emus {
    my $self  = shift;
    my $shape = shift;
    my (
        $col_start, $row_start, $x1, $y1,    $col_end,
        $row_end,   $x2,        $y2, $x_abs, $y_abs
      )
      = $self->_position_object_pixels(
        $shape->{_column_start},
        $shape->{_row_start},
        $shape->{_x_offset},
        $shape->{_y_offset},
        $shape->{_width} * $shape->{_scale_x},
        $shape->{_height} * $shape->{_scale_y},
        $shape->{_drawing}
      );
    $shape->{_width_emu}  = int( abs( $shape->{_width} * 9_525 ) );
    $shape->{_height_emu} = int( abs( $shape->{_height} * 9_525 ) );
    $shape->{_column_start} = int( $col_start );
    $shape->{_row_start}    = int( $row_start );
    $shape->{_column_end}   = int( $col_end );
    $shape->{_row_end}      = int( $row_end );
    $shape->{_x1}    = int( $x1 * 9_525 );
    $shape->{_y1}    = int( $y1 * 9_525 );
    $shape->{_x2}    = int( $x2 * 9_525 );
    $shape->{_y2}    = int( $y2 * 9_525 );
    $shape->{_x_abs} = int( $x_abs * 9_525 );
    $shape->{_y_abs} = int( $y_abs * 9_525 );
}
sub _size_col {
    my $self    = shift;
    my $col     = shift;
    my $anchor  = shift || 0;
    my $max_digit_width = 7;
    my $padding         = 5;
    my $pixels;
    if ( exists $self->{_col_sizes}->{$col} )
    {
        my $width  = $self->{_col_sizes}->{$col}[0];
        my $hidden = $self->{_col_sizes}->{$col}[1];
        if ( $hidden == 1 && $anchor != 4 ) {
            $pixels = 0;
        }
        elsif ( $width < 1 ) {
            $pixels = int( $width * ( $max_digit_width + $padding ) + 0.5 );
        }
        else {
            $pixels = int( $width * $max_digit_width + 0.5 ) + $padding;
        }
    }
    else {
        $pixels = $self->{_default_col_pixels};
    }
    return $pixels;
}
sub _size_row {
    my $self    = shift;
    my $row     = shift;
    my $anchor  = shift || 0;
    my $pixels;
    if ( exists $self->{_row_sizes}->{$row} ) {
        my $height = $self->{_row_sizes}->{$row}[0];
        my $hidden = $self->{_row_sizes}->{$row}[1];
        if ( $hidden == 1 && $anchor != 4 ) {
            $pixels = 0;
        }
        else {
            $pixels = int( 4 / 3 * $height );
        }
    }
    else {
        $pixels = int( 4 / 3 * $self->{_default_row_height} );
    }
    return $pixels;
}
sub _get_shared_string_index {
    my $self = shift;
    my $str  = shift;
    if ( not exists ${ $self->{_str_table} }->{$str} ) {
        ${ $self->{_str_table} }->{$str} = ${ $self->{_str_unique} }++;
    }
    ${ $self->{_str_total} }++;
    my $index = ${ $self->{_str_table} }->{$str};
    return $index;
}
sub _get_drawing_rel_index {
    my $self   = shift;
    my $target = shift;
    if ( ! defined $target ) {
        return ++$self->{_drawing_rels_id};
    }
    elsif ( exists $self->{_drawing_rels}->{$target} ) {
        return $self->{_drawing_rels}->{$target};
    }
    else {
        $self->{_drawing_rels}->{$target} = ++$self->{_drawing_rels_id};
        return $self->{_drawing_rels_id};
    }
}
sub _get_vml_drawing_rel_index {
    my $self   = shift;
    my $target = shift;
    if ( exists $self->{_vml_drawing_rels}->{$target} ) {
        return $self->{_vml_drawing_rels}->{$target};
    }
    else {
        $self->{_vml_drawing_rels}->{$target} = ++$self->{_vml_drawing_rels_id};
        return $self->{_vml_drawing_rels_id};
    }
}
sub insert_chart {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    my $row      = $_[0];
    my $col      = $_[1];
    my $chart    = $_[2];
    my $x_offset;
    my $y_offset;
    my $x_scale;
    my $y_scale;
    my $anchor;
    croak "Insufficient arguments in insert_chart()" unless @_ >= 3;
    if ( ref $chart ) {
        croak "Not a Chart object in insert_chart()"
          unless $chart->isa( 'Excel::Writer::XLSX::Chart' );
        croak "Not a embedded style Chart object in insert_chart()"
          unless $chart->{_embedded};
    }
    if ( ref $_[3] eq 'HASH' ) {
        my $options = $_[3];
        $x_offset = $options->{x_offset}        || 0;
        $y_offset = $options->{y_offset}        || 0;
        $x_scale  = $options->{x_scale}         || 1;
        $y_scale  = $options->{y_scale}         || 1;
        $anchor   = $options->{object_position} || 1;
    }
    else {
        $x_offset = $_[3] || 0;
        $y_offset = $_[4] || 0;
        $x_scale  = $_[5] || 1;
        $y_scale  = $_[6] || 1;
        $anchor   = $_[7] || 1;
    }
    if (   $chart->{_already_inserted}
        || $chart->{_combined} && $chart->{_combined}->{_already_inserted} )
    {
        carp "Chart cannot be inserted in a worksheet more than once";
        return;
    }
    else {
        $chart->{_already_inserted} = 1;
        if ( $chart->{_combined} ) {
            $chart->{_combined}->{_already_inserted} = 1;
        }
    }
    $x_scale  = $chart->{_x_scale}  if $chart->{_x_scale} != 1;
    $y_scale  = $chart->{_y_scale}  if $chart->{_y_scale} != 1;
    $x_offset = $chart->{_x_offset} if $chart->{_x_offset};
    $y_offset = $chart->{_y_offset} if $chart->{_y_offset};
    push @{ $self->{_charts} },
      [ $row, $col, $chart, $x_offset, $y_offset, $x_scale, $y_scale, $anchor ];
}
sub _prepare_chart {
    my $self         = shift;
    my $index        = shift;
    my $chart_id     = shift;
    my $drawing_id   = shift;
    my $drawing_type = 1;
    my $drawing;
    my ( $row, $col, $chart, $x_offset, $y_offset, $x_scale, $y_scale, $anchor )
      = @{ $self->{_charts}->[$index] };
    $chart->{_id} = $chart_id - 1;
    my $width  = $chart->{_width}  if $chart->{_width};
    my $height = $chart->{_height} if $chart->{_height};
    $width  = int( 0.5 + ( $width  * $x_scale ) );
    $height = int( 0.5 + ( $height * $y_scale ) );
    my @dimensions =
      $self->_position_object_emus( $col, $row, $x_offset, $y_offset, $width,
        $height, $anchor);
    my $name = $chart->{_chart_name};
    if ( !$self->{_drawing} ) {
        $drawing              = Excel::Writer::XLSX::Drawing->new();
        $drawing->{_embedded} = 1;
        $self->{_drawing}     = $drawing;
        push @{ $self->{_external_drawing_links} },
          [ '/drawing', '../drawings/drawing' . $drawing_id . '.xml' ];
    }
    else {
        $drawing = $self->{_drawing};
    }
    my $drawing_object = $drawing->_add_drawing_object();
    $drawing_object->{_type}          = $drawing_type;
    $drawing_object->{_dimensions}    = \@dimensions;
    $drawing_object->{_width}         = 0;
    $drawing_object->{_height}        = 0;
    $drawing_object->{_description}   = $name;
    $drawing_object->{_shape}         = undef;
    $drawing_object->{_anchor}        = $anchor;
    $drawing_object->{_rel_index}     = $self->_get_drawing_rel_index();
    $drawing_object->{_url_rel_index} = 0;
    $drawing_object->{_tip}           = undef;
    push @{ $self->{_drawing_links} },
      [ '/chart', '../charts/chart' . $chart_id . '.xml' ];
}
sub _get_range_data {
    my $self = shift;
    return () if $self->{_optimization};
    my @data;
    my ( $row_start, $col_start, $row_end, $col_end ) = @_;
    for my $row_num ( $row_start .. $row_end ) {
        if ( !exists $self->{_table}->{$row_num} ) {
            push @data, undef;
            next;
        }
        for my $col_num ( $col_start .. $col_end ) {
            if ( my $cell = $self->{_table}->{$row_num}->{$col_num} ) {
                my $type  = $cell->[0];
                my $token = $cell->[1];
                if ( $type eq 'n' ) {
                    push @data, $token;
                }
                elsif ( $type eq 's' ) {
                    if ( $self->{_optimization} == 0 ) {
                        push @data, { 'sst_id' => $token };
                    }
                    else {
                        push @data, $token;
                    }
                }
                elsif ( $type eq 'f' ) {
                    push @data, $cell->[3] || 0;
                }
                elsif ( $type eq 'a' ) {
                    push @data, $cell->[4] || 0;
                }
                elsif ( $type eq 'b' ) {
                    push @data, '';
                }
            }
            else {
                push @data, undef;
            }
        }
    }
    return @data;
}
sub insert_image {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    my $row      = $_[0];
    my $col      = $_[1];
    my $image    = $_[2];
    my $x_offset;
    my $y_offset;
    my $x_scale;
    my $y_scale;
    my $anchor;
    my $url;
    my $tip;
    if ( ref $_[3] eq 'HASH' ) {
        my $options = $_[3];
        $x_offset = $options->{x_offset}        || 0;
        $y_offset = $options->{y_offset}        || 0;
        $x_scale  = $options->{x_scale}         || 1;
        $y_scale  = $options->{y_scale}         || 1;
        $anchor   = $options->{object_position} || 2;
        $url      = $options->{url};
        $tip      = $options->{tip};
    }
    else {
        $x_offset = $_[3] || 0;
        $y_offset = $_[4] || 0;
        $x_scale  = $_[5] || 1;
        $y_scale  = $_[6] || 1;
        $anchor   = $_[7] || 2;
    }
    croak "Insufficient arguments in insert_image()" unless @_ >= 3;
    croak "Couldn't locate $image: $!" unless -e $image;
    push @{ $self->{_images} },
      [
        $row,     $col,     $image, $x_offset, $y_offset,
        $x_scale, $y_scale, $url,   $tip,      $anchor
      ];
}
sub _prepare_image {
    my $self         = shift;
    my $index        = shift;
    my $image_id     = shift;
    my $drawing_id   = shift;
    my $width        = shift;
    my $height       = shift;
    my $name         = shift;
    my $image_type   = shift;
    my $x_dpi        = shift;
    my $y_dpi        = shift;
    my $md5          = shift;
    my $drawing_type = 2;
    my $drawing;
    my (
        $row,     $col,     $image, $x_offset, $y_offset,
        $x_scale, $y_scale, $url,   $tip,      $anchor
    ) = @{ $self->{_images}->[$index] };
    $width  *= $x_scale;
    $height *= $y_scale;
    $width  *= 96 / $x_dpi;
    $height *= 96 / $y_dpi;
    my @dimensions =
      $self->_position_object_emus( $col, $row, $x_offset, $y_offset, $width,
        $height, $anchor);
    $width  = int( 0.5 + ( $width * 9_525 ) );
    $height = int( 0.5 + ( $height * 9_525 ) );
    if ( !$self->{_drawing} ) {
        $drawing              = Excel::Writer::XLSX::Drawing->new();
        $drawing->{_embedded} = 1;
        $self->{_drawing}     = $drawing;
        push @{ $self->{_external_drawing_links} },
          [ '/drawing', '../drawings/drawing' . $drawing_id . '.xml' ];
    }
    else {
        $drawing = $self->{_drawing};
    }
    my $drawing_object = $drawing->_add_drawing_object();
    $drawing_object->{_type}          = $drawing_type;
    $drawing_object->{_dimensions}    = \@dimensions;
    $drawing_object->{_width}         = $width;
    $drawing_object->{_height}        = $height;
    $drawing_object->{_description}   = $name;
    $drawing_object->{_shape}         = undef;
    $drawing_object->{_anchor}        = $anchor;
    $drawing_object->{_rel_index}     = 0;
    $drawing_object->{_url_rel_index} = 0;
    $drawing_object->{_tip}           = $tip;
    if ( $url ) {
        my $rel_type    = '/hyperlink';
        my $target_mode = 'External';
        my $target;
        if ( $url =~ m{^[fh]tt?ps?://} || $url =~ m{^mailto:} ) {
            $target = _escape_url( $url );
        }
        if ( $url =~ s{^external:}{file:///} ) {
            $target = _escape_url( $url );
            $target =~ s/#/%23/g;
        }
        if ( $url =~ s/^internal:/#/ ) {
            $target      = $url;
            $target_mode = undef;
        }
        my $max_url = $self->{_max_url_length};
        if ( length $target > $max_url ) {
            carp "Ignoring URL '$url' where link or anchor > $max_url characters "
              . "since it exceeds Excel's limit for URLS. See LIMITATIONS "
              . "section of the Excel::Writer::XLSX documentation.";
        }
        else {
            if ( $target && !exists $self->{_drawing_rels}->{$url} ) {
                push @{ $self->{_drawing_links} },
                  [ $rel_type, $target, $target_mode ];
            }
            $drawing_object->{_url_rel_index} =
              $self->_get_drawing_rel_index( $url );
        }
    }
    if ( !exists $self->{_drawing_rels}->{$md5} ) {
        push @{ $self->{_drawing_links} },
          [ '/image', '../media/image' . $image_id . '.' . $image_type ];
    }
    $drawing_object->{_rel_index} = $self->_get_drawing_rel_index( $md5 );
}
sub _prepare_header_image {
    my $self       = shift;
    my $image_id   = shift;
    my $width      = shift;
    my $height     = shift;
    my $name       = shift;
    my $image_type = shift;
    my $position   = shift;
    my $x_dpi      = shift;
    my $y_dpi      = shift;
    my $md5        = shift;
    $name =~ s/\.[^\.]+$//;
    if ( !exists $self->{_vml_drawing_rels}->{$md5} ) {
        push @{ $self->{_vml_drawing_links} },
          [ '/image', '../media/image' . $image_id . '.' . $image_type ];
    }
    my $ref_id = $self->_get_vml_drawing_rel_index( $md5 );
    push @{ $self->{_header_images_array} },
      [ $width, $height, $name, $position, $x_dpi, $y_dpi, $ref_id ];
}
sub insert_shape {
    my $self = shift;
    if ( $_[0] =~ /^\D/ ) {
        @_ = $self->_substitute_cellref( @_ );
    }
    croak "Insufficient arguments in insert_shape()" unless @_ >= 3;
    my $shape = $_[2];
    croak "Not a Shape object in insert_shape()"
      unless $shape->isa( 'Excel::Writer::XLSX::Shape' );
    $shape->{_row_start}    = $_[0];
    $shape->{_column_start} = $_[1];
    $shape->{_x_offset}     = $_[3] || 0;
    $shape->{_y_offset}     = $_[4] || 0;
    $shape->{_scale_x} = $_[5] if defined $_[5];
    $shape->{_scale_y} = $_[6] if defined $_[6];
    $shape->{_anchor}  = $_[7] || 1;
    my $needs_id = 1;
    while ( $needs_id ) {
        my $id = $shape->{_id} || 0;
        my $used = exists $self->{_shape_hash}->{$id} ? 1 : 0;
        if ( !$used && $id != 0 ) {
            $needs_id = 0;
        }
        else {
            $shape->{_id} = ++$self->{_last_shape_id};
        }
    }
    $shape->{_element} = $#{ $self->{_shapes} } + 1;
    $self->{_shape_hash}->{ $shape->{_id} } = $shape->{_element};
    $shape->{_palette} = $self->{_palette};
    if ( $shape->{_stencil} ) {
        my $insert = { %{$shape} };
        $self->_auto_locate_connectors( $insert );
        bless $insert, ref $shape;
        push @{ $self->{_shapes} }, $insert;
        return $insert;
    }
    else {
        $self->_auto_locate_connectors( $shape );
        push @{ $self->{_shapes} }, $shape;
        return $shape;
    }
}
sub _prepare_shape {
    my $self       = shift;
    my $index      = shift;
    my $drawing_id = shift;
    my $shape      = $self->{_shapes}->[$index];
    my $drawing;
    my $drawing_type = 3;
    if ( !$self->{_drawing} ) {
        $drawing              = Excel::Writer::XLSX::Drawing->new();
        $drawing->{_embedded} = 1;
        $self->{_drawing}     = $drawing;
        push @{ $self->{_external_drawing_links} },
          [ '/drawing', '../drawings/drawing' . $drawing_id . '.xml' ];
        $self->{_has_shapes} = 1;
    }
    else {
        $drawing = $self->{_drawing};
    }
    $self->_validate_shape( $shape, $index );
    $self->_position_shape_emus( $shape );
    my @dimensions = (
        $shape->{_column_start}, $shape->{_row_start},
        $shape->{_x1},           $shape->{_y1},
        $shape->{_column_end},   $shape->{_row_end},
        $shape->{_x2},           $shape->{_y2},
        $shape->{_x_abs},        $shape->{_y_abs},
    );
    my $drawing_object = $drawing->_add_drawing_object();
    $drawing_object->{_type}          = $drawing_type;
    $drawing_object->{_dimensions}    = \@dimensions;
    $drawing_object->{_width}         = $shape->{_width_emu};
    $drawing_object->{_height}        = $shape->{_height_emu};
    $drawing_object->{_description}   = $shape->{_name};
    $drawing_object->{_shape}         = $shape;
    $drawing_object->{_anchor}        = $shape->{_anchor};
    $drawing_object->{_rel_index}     = $self->_get_drawing_rel_index();
    $drawing_object->{_url_rel_index} = 0;
    $drawing_object->{_tip}           = undef;
}
sub _auto_locate_connectors {
    my $self  = shift;
    my $shape = shift;
    my $connector_shapes = {
        straightConnector => 1,
        Connector         => 1,
        bentConnector     => 1,
        curvedConnector   => 1,
        line              => 1,
    };
    my $shape_base = $shape->{_type};
    chop $shape_base;
    $shape->{_connect} = $connector_shapes->{$shape_base} ? 1 : 0;
    return unless $shape->{_connect};
    return unless ( $shape->{_start} and $shape->{_end} );
    return unless ( $shape->{_start_side} and $shape->{_end_side} );
    my $sid = $shape->{_start};
    my $eid = $shape->{_end};
    my $slink_id = $self->{_shape_hash}->{$sid};
    my ( $sls, $els );
    if ( defined $slink_id ) {
        $sls = $self->{_shapes}->[$slink_id];
    }
    else {
        warn "missing start connection for '$shape->{_name}', id=$sid\n";
        return;
    }
    my $elink_id = $self->{_shape_hash}->{$eid};
    if ( defined $elink_id ) {
        $els = $self->{_shapes}->[$elink_id];
    }
    else {
        warn "missing end connection for '$shape->{_name}', id=$eid\n";
        return;
    }
    my $connect_type = $shape->{_start_side} . $shape->{_end_side};
    my $smidx        = $sls->{_x_offset} + $sls->{_width} / 2;
    my $emidx        = $els->{_x_offset} + $els->{_width} / 2;
    my $smidy        = $sls->{_y_offset} + $sls->{_height} / 2;
    my $emidy        = $els->{_y_offset} + $els->{_height} / 2;
    my $netx         = abs( $smidx - $emidx );
    my $nety         = abs( $smidy - $emidy );
    if ( $connect_type eq 'bt' ) {
        my $sy = $sls->{_y_offset} + $sls->{_height};
        my $ey = $els->{_y_offset};
        $shape->{_width} = abs( int( $emidx - $smidx ) );
        $shape->{_x_offset} = int( min( $smidx, $emidx ) );
        $shape->{_height} =
          abs(
            int( $els->{_y_offset} - ( $sls->{_y_offset} + $sls->{_height} ) )
          );
        $shape->{_y_offset} = int(
            min( ( $sls->{_y_offset} + $sls->{_height} ), $els->{_y_offset} ) );
        $shape->{_flip_h} = ( $smidx < $emidx ) ? 1 : 0;
        $shape->{_rotation} = 90;
        if ( $sy > $ey ) {
            $shape->{_flip_v} = 1;
            if ( $#{ $shape->{_adjustments} } < 0 ) {
                $shape->{_adjustments} = [ -10, 50, 110 ];
            }
            $shape->{_type} = 'bentConnector5';
        }
    }
    elsif ( $connect_type eq 'rl' ) {
        $shape->{_width} =
          abs(
            int( $els->{_x_offset} - ( $sls->{_x_offset} + $sls->{_width} ) ) );
        $shape->{_height} = abs( int( $emidy - $smidy ) );
        $shape->{_x_offset} =
          min( $sls->{_x_offset} + $sls->{_width}, $els->{_x_offset} );
        $shape->{_y_offset} = min( $smidy, $emidy );
        $shape->{_flip_h} = 1 if ( $smidx < $emidx ) and ( $smidy > $emidy );
        $shape->{_flip_h} = 1 if ( $smidx > $emidx ) and ( $smidy < $emidy );
        if ( $smidx > $emidx ) {
            if ( $#{ $shape->{_adjustments} } < 0 ) {
                $shape->{_adjustments} = [ -10, 50, 110 ];
            }
            $shape->{_type} = 'bentConnector5';
        }
    }
    else {
        warn "Connection $connect_type not implemented yet\n";
    }
}
sub _validate_shape {
    my $self  = shift;
    my $shape = shift;
    my $index = shift;
    if ( !grep ( /^$shape->{_align}$/, qw[l ctr r just] ) ) {
        croak "Shape $index ($shape->{_type}) alignment ($shape->{align}), "
          . "not in ('l', 'ctr', 'r', 'just')\n";
    }
    if ( !grep ( /^$shape->{_valign}$/, qw[t ctr b] ) ) {
        croak "Shape $index ($shape->{_type}) vertical alignment "
          . "($shape->{valign}), not ('t', 'ctr', 'b')\n";
    }
}
sub _prepare_vml_objects {
    my $self           = shift;
    my $vml_data_id    = shift;
    my $vml_shape_id   = shift;
    my $vml_drawing_id = shift;
    my $comment_id     = shift;
    my @comments;
    my @rows = sort { $a <=> $b } keys %{ $self->{_comments} };
    for my $row ( @rows ) {
        my @cols = sort { $a <=> $b } keys %{ $self->{_comments}->{$row} };
        for my $col ( @cols ) {
            my $user_options = $self->{_comments}->{$row}->{$col};
            my $params = [ $self->_comment_params( @$user_options ) ];
            $self->{_comments}->{$row}->{$col} = $params;
            if ( $self->{_comments_visible} ) {
                if ( !defined $self->{_comments}->{$row}->{$col}->[4] ) {
                    $self->{_comments}->{$row}->{$col}->[4] = 1;
                }
            }
            if ( !defined $self->{_comments}->{$row}->{$col}->[3] ) {
                $self->{_comments}->{$row}->{$col}->[3] =
                  $self->{_comments_author};
            }
            push @comments, $self->{_comments}->{$row}->{$col};
        }
    }
    push @{ $self->{_external_vml_links} },
      [ '/vmlDrawing', '../drawings/vmlDrawing' . $vml_drawing_id . '.vml' ];
    if ( $self->{_has_comments} ) {
        $self->{_comments_array} = \@comments;
        push @{ $self->{_external_comment_links} },
          [ '/comments', '../comments' . $comment_id . '.xml' ];
    }
    my $count         = scalar @comments;
    my $start_data_id = $vml_data_id;
    for my $i ( 1 .. int( $count / 1024 ) ) {
        $vml_data_id = "$vml_data_id," . ( $start_data_id + $i );
    }
    $self->{_vml_data_id}  = $vml_data_id;
    $self->{_vml_shape_id} = $vml_shape_id;
    return $count;
}
sub _prepare_header_vml_objects {
    my $self           = shift;
    my $vml_header_id  = shift;
    my $vml_drawing_id = shift;
    $self->{_vml_header_id} = $vml_header_id;
    push @{ $self->{_external_vml_links} },
      [ '/vmlDrawing', '../drawings/vmlDrawing' . $vml_drawing_id . '.vml' ];
}
sub _prepare_tables {
    my $self     = shift;
    my $table_id = shift;
    my $seen     = shift;
    for my $table ( @{ $self->{_tables} } ) {
        $table-> {_id} = $table_id;
        if ( !defined $table->{_name} ) {
            $table->{_name} = 'Table' . $table_id;
        }
        my $name = lc $table->{_name};
        if ( exists $seen->{$name} ) {
            die "error: invalid duplicate table name '$table->{_name}' found";
        }
        else {
            $seen->{$name} = 1;
        }
        my $link = [ '/table', '../tables/table' . $table_id . '.xml' ];
        push @{ $self->{_external_table_links} }, $link;
        $table_id++;
    }
}
sub _comment_params {
    my $self = shift;
    my $row    = shift;
    my $col    = shift;
    my $string = shift;
    my $default_width  = 128;
    my $default_height = 74;
    my %params = (
        author      => undef,
        color       => 81,
        start_cell  => undef,
        start_col   => undef,
        start_row   => undef,
        visible     => undef,
        width       => $default_width,
        height      => $default_height,
        x_offset    => undef,
        x_scale     => 1,
        y_offset    => undef,
        y_scale     => 1,
        font        => 'Tahoma',
        font_size   => 8,
        font_family => 2,
    );
    %params = ( %params, @_ );
    $params{width}  = $default_width  if not $params{width};
    $params{height} = $default_height if not $params{height};
    my $max_len = 32767;
    if ( length( $string ) > $max_len ) {
        $string = substr( $string, 0, $max_len );
    }
    my $color    = $params{color};
    my $color_id = &Excel::Writer::XLSX::Format::_get_color( $color );
    if ( $color_id =~ m/^#[0-9A-F]{6}$/i ) {
        $params{color} = $color_id;
    }
    elsif ( $color_id == 0 ) {
        $params{color} = '#ffffe1';
    }
    else {
        my $palette = $self->{_palette};
        my @rgb = @{ $palette->[ $color_id - 8 ] };
        my $rgb_color = sprintf "%02x%02x%02x", @rgb[0, 1, 2];
        $rgb_color =~ s/^([0-9a-f])\1([0-9a-f])\2([0-9a-f])\3$/$1$2$3/;
        $params{color} = sprintf "#%s [%d]", $rgb_color, $color_id;
    }
    if ( defined $params{start_cell} ) {
        my ( $row, $col ) = $self->_substitute_cellref( $params{start_cell} );
        $params{start_row} = $row;
        $params{start_col} = $col;
    }
    my $row_max = $self->{_xls_rowmax};
    my $col_max = $self->{_xls_colmax};
    if ( not defined $params{start_row} ) {
        if    ( $row == 0 )            { $params{start_row} = 0 }
        elsif ( $row == $row_max - 3 ) { $params{start_row} = $row_max - 7 }
        elsif ( $row == $row_max - 2 ) { $params{start_row} = $row_max - 6 }
        elsif ( $row == $row_max - 1 ) { $params{start_row} = $row_max - 5 }
        else                           { $params{start_row} = $row - 1 }
    }
    if ( not defined $params{y_offset} ) {
        if    ( $row == 0 )            { $params{y_offset} = 2 }
        elsif ( $row == $row_max - 3 ) { $params{y_offset} = 16 }
        elsif ( $row == $row_max - 2 ) { $params{y_offset} = 16 }
        elsif ( $row == $row_max - 1 ) { $params{y_offset} = 14 }
        else                           { $params{y_offset} = 10 }
    }
    if ( not defined $params{start_col} ) {
        if    ( $col == $col_max - 3 ) { $params{start_col} = $col_max - 6 }
        elsif ( $col == $col_max - 2 ) { $params{start_col} = $col_max - 5 }
        elsif ( $col == $col_max - 1 ) { $params{start_col} = $col_max - 4 }
        else                           { $params{start_col} = $col + 1 }
    }
    if ( not defined $params{x_offset} ) {
        if    ( $col == $col_max - 3 ) { $params{x_offset} = 49 }
        elsif ( $col == $col_max - 2 ) { $params{x_offset} = 49 }
        elsif ( $col == $col_max - 1 ) { $params{x_offset} = 49 }
        else                           { $params{x_offset} = 15 }
    }
    if ( $params{x_scale} ) {
        $params{width} = $params{width} * $params{x_scale};
    }
    if ( $params{y_scale} ) {
        $params{height} = $params{height} * $params{y_scale};
    }
    $params{width}  = int( 0.5 + $params{width} );
    $params{height} = int( 0.5 + $params{height} );
    my @vertices = $self->_position_object_pixels(
        $params{start_col}, $params{start_row}, $params{x_offset},
        $params{y_offset},  $params{width},     $params{height}
    );
    push @vertices, ( $params{width}, $params{height} );
    return (
        $row,
        $col,
        $string,
        $params{author},
        $params{visible},
        $params{color},
        $params{font},
        $params{font_size},
        $params{font_family},
        [@vertices],
    );
}
sub _button_params {
    my $self   = shift;
    my $row    = shift;
    my $col    = shift;
    my $params = shift;
    my $button = { _row => $row, _col => $col };
    my $button_number = 1 + @{ $self->{_buttons_array} };
    my $caption = $params->{caption};
    if ( !defined $caption ) {
        $caption = 'Button ' . $button_number;
    }
    $button->{_font}->{_caption} = $caption;
    if ( $params->{macro} ) {
        $button->{_macro} = '[0]!' . $params->{macro};
    }
    else {
        $button->{_macro} = '[0]!Button' . $button_number . '_Click';
    }
    my $default_width  = $self->{_default_col_pixels};
    my $default_height = $self->{_default_row_pixels};
    $params->{width}  = $default_width  if !$params->{width};
    $params->{height} = $default_height if !$params->{height};
    $params->{x_offset}  = 0  if !$params->{x_offset};
    $params->{y_offset}  = 0  if !$params->{y_offset};
    if ( $params->{x_scale} ) {
        $params->{width} = $params->{width} * $params->{x_scale};
    }
    if ( $params->{y_scale} ) {
        $params->{height} = $params->{height} * $params->{y_scale};
    }
    $params->{width}  = int( 0.5 + $params->{width} );
    $params->{height} = int( 0.5 + $params->{height} );
    $params->{start_row} = $row;
    $params->{start_col} = $col;
    my @vertices = $self->_position_object_pixels(
        $params->{start_col}, $params->{start_row}, $params->{x_offset},
        $params->{y_offset},  $params->{width},     $params->{height}
    );
    push @vertices, ( $params->{width}, $params->{height} );
    $button->{_vertices} = \@vertices;
    return $button;
}
sub write_url_range { }
sub write_utf16be_string {
    my $self = shift;
    @_ = $self->_substitute_cellref( @_ ) if $_[0] =~ /^\D/;
    return -1 if @_ < 3;
    require Encode;
    my $utf8_string = Encode::decode( 'UTF-16BE', $_[2] );
    return $self->write_string( $_[0], $_[1], $utf8_string, $_[3] );
}
sub write_utf16le_string {
    my $self = shift;
    @_ = $self->_substitute_cellref( @_ ) if $_[0] =~ /^\D/;
    return -1 if @_ < 3;
    require Encode;
    my $utf8_string = Encode::decode( 'UTF-16LE', $_[2] );
    return $self->write_string( $_[0], $_[1], $utf8_string, $_[3] );
}
sub store_formula {
    my $self   = shift;
    my $string = shift;
    my @tokens = split /(\$?[A-I]?[A-Z]\$?\d+)/, $string;
    return \@tokens;
}
sub repeat_formula {
    my $self = shift;
    @_ = $self->_substitute_cellref( @_ ) if $_[0] =~ /^\D/;
    if ( @_ < 2 ) { return -1 }
    my $row         = shift;
    my $col         = shift;
    my $formula_ref = shift;
    my $format      = shift;
    my @pairs       = @_;
    croak "Odd number of elements in pattern/replacement list" if @pairs % 2;
    croak "Not a valid formula" if ref $formula_ref ne 'ARRAY';
    my @tokens = @$formula_ref;
    my $value = undef;
    if ( @pairs && $pairs[-2] eq 'result' ) {
        $value = pop @pairs;
        pop @pairs;
    }
    while ( @pairs ) {
        my $pattern = shift @pairs;
        my $replace = shift @pairs;
        foreach my $token ( @tokens ) {
            last if $token =~ s/$pattern/$replace/;
        }
    }
    my $formula = join '', @tokens;
    return $self->write_formula( $row, $col, $formula, $format, $value );
}
sub _write_worksheet {
    my $self                   = shift;
    my $schema                 = 'http://schemas.openxmlformats.org/';
    my $xmlns                  = $schema . 'spreadsheetml/2006/main';
    my $xmlns_r                = $schema . 'officeDocument/2006/relationships';
    my $xmlns_mc               = $schema . 'markup-compatibility/2006';
    my @attributes = (
        'xmlns'   => $xmlns,
        'xmlns:r' => $xmlns_r,
    );
    if ( $self->{_excel_version} == 2010 ) {
        push @attributes, ( 'xmlns:mc' => $xmlns_mc );
        push @attributes,
          (     'xmlns:x14ac' => 'http://schemas.microsoft.com/'
              . 'office/spreadsheetml/2009/9/ac' );
        push @attributes, ( 'mc:Ignorable' => 'x14ac' );
    }
    $self->xml_start_tag( 'worksheet', @attributes );
}
sub _write_sheet_pr {
    my $self       = shift;
    my @attributes = ();
    if (   !$self->{_fit_page}
        && !$self->{_filter_on}
        && !$self->{_tab_color}
        && !$self->{_outline_changed}
        && !$self->{_vba_codename} )
    {
        return;
    }
    my $codename = $self->{_vba_codename};
    push @attributes, ( 'codeName'   => $codename ) if $codename;
    push @attributes, ( 'filterMode' => 1 )         if $self->{_filter_on};
    if (   $self->{_fit_page}
        || $self->{_tab_color}
        || $self->{_outline_changed} )
    {
        $self->xml_start_tag( 'sheetPr', @attributes );
        $self->_write_tab_color();
        $self->_write_outline_pr();
        $self->_write_page_set_up_pr();
        $self->xml_end_tag( 'sheetPr' );
    }
    else {
        $self->xml_empty_tag( 'sheetPr', @attributes );
    }
}
sub _write_page_set_up_pr {
    my $self = shift;
    return unless $self->{_fit_page};
    my @attributes = ( 'fitToPage' => 1 );
    $self->xml_empty_tag( 'pageSetUpPr', @attributes );
}
sub _write_dimension {
    my $self = shift;
    my $ref;
    if ( !defined $self->{_dim_rowmin} && !defined $self->{_dim_colmin} ) {
        $ref = 'A1';
    }
    elsif ( !defined $self->{_dim_rowmin} && defined $self->{_dim_colmin} ) {
        if ( $self->{_dim_colmin} == $self->{_dim_colmax} ) {
            $ref = xl_rowcol_to_cell( 0, $self->{_dim_colmin} );
        }
        else {
            my $cell_1 = xl_rowcol_to_cell( 0, $self->{_dim_colmin} );
            my $cell_2 = xl_rowcol_to_cell( 0, $self->{_dim_colmax} );
            $ref = $cell_1 . ':' . $cell_2;
        }
    }
    elsif ($self->{_dim_rowmin} == $self->{_dim_rowmax}
        && $self->{_dim_colmin} == $self->{_dim_colmax} )
    {
        $ref = xl_rowcol_to_cell( $self->{_dim_rowmin}, $self->{_dim_colmin} );
    }
    else {
        my $cell_1 =
          xl_rowcol_to_cell( $self->{_dim_rowmin}, $self->{_dim_colmin} );
        my $cell_2 =
          xl_rowcol_to_cell( $self->{_dim_rowmax}, $self->{_dim_colmax} );
        $ref = $cell_1 . ':' . $cell_2;
    }
    my @attributes = ( 'ref' => $ref );
    $self->xml_empty_tag( 'dimension', @attributes );
}
sub _write_sheet_views {
    my $self = shift;
    my @attributes = ();
    $self->xml_start_tag( 'sheetViews', @attributes );
    $self->_write_sheet_view();
    $self->xml_end_tag( 'sheetViews' );
}
sub _write_sheet_view {
    my $self             = shift;
    my $gridlines        = $self->{_screen_gridlines};
    my $show_zeros       = $self->{_show_zeros};
    my $right_to_left    = $self->{_right_to_left};
    my $tab_selected     = $self->{_selected};
    my $view             = $self->{_page_view};
    my $zoom             = $self->{_zoom};
    my $row_col_headers  = $self->{_hide_row_col_headers};
    my $workbook_view_id = 0;
    my @attributes       = ();
    if ( !$gridlines ) {
        push @attributes, ( 'showGridLines' => 0 );
    }
    if ( $row_col_headers ) {
        push @attributes, ( 'showRowColHeaders' => 0 );
    }
    if ( !$show_zeros ) {
        push @attributes, ( 'showZeros' => 0 );
    }
    if ( $right_to_left ) {
        push @attributes, ( 'rightToLeft' => 1 );
    }
    if ( $tab_selected ) {
        push @attributes, ( 'tabSelected' => 1 );
    }
    if ( !$self->{_outline_on} ) {
        push @attributes, ( "showOutlineSymbols" => 0 );
    }
    if ( $view ) {
        push @attributes, ( 'view' => 'pageLayout' );
    }
    if ( $zoom != 100 ) {
        push @attributes, ( 'zoomScale' => $zoom ) unless $view;
        push @attributes, ( 'zoomScaleNormal' => $zoom )
          if $self->{_zoom_scale_normal};
    }
    push @attributes, ( 'workbookViewId' => $workbook_view_id );
    if ( @{ $self->{_panes} } || @{ $self->{_selections} } ) {
        $self->xml_start_tag( 'sheetView', @attributes );
        $self->_write_panes();
        $self->_write_selections();
        $self->xml_end_tag( 'sheetView' );
    }
    else {
        $self->xml_empty_tag( 'sheetView', @attributes );
    }
}
sub _write_selections {
    my $self = shift;
    for my $selection ( @{ $self->{_selections} } ) {
        $self->_write_selection( @$selection );
    }
}
sub _write_selection {
    my $self        = shift;
    my $pane        = shift;
    my $active_cell = shift;
    my $sqref       = shift;
    my @attributes  = ();
    push @attributes, ( 'pane'       => $pane )        if $pane;
    push @attributes, ( 'activeCell' => $active_cell ) if $active_cell;
    push @attributes, ( 'sqref'      => $sqref )       if $sqref;
    $self->xml_empty_tag( 'selection', @attributes );
}
sub _write_sheet_format_pr {
    my $self               = shift;
    my $base_col_width     = 10;
    my $default_row_height = $self->{_default_row_height};
    my $row_level          = $self->{_outline_row_level};
    my $col_level          = $self->{_outline_col_level};
    my $zero_height        = $self->{_default_row_zeroed};
    my @attributes = ( 'defaultRowHeight' => $default_row_height );
    if ( $self->{_default_row_height} != $self->{_original_row_height} ) {
        push @attributes, ( 'customHeight' => 1 );
    }
    if ( $self->{_default_row_zeroed} ) {
        push @attributes, ( 'zeroHeight' => 1 );
    }
    push @attributes, ( 'outlineLevelRow' => $row_level ) if $row_level;
    push @attributes, ( 'outlineLevelCol' => $col_level ) if $col_level;
    if ( $self->{_excel_version} == 2010 ) {
        push @attributes, ( 'x14ac:dyDescent' => '0.25' );
    }
    $self->xml_empty_tag( 'sheetFormatPr', @attributes );
}
sub _write_cols {
    my $self = shift;
    return unless %{ $self->{_colinfo} };
    $self->xml_start_tag( 'cols' );
    for my $col ( sort keys %{ $self->{_colinfo} } ) {
        $self->_write_col_info( @{ $self->{_colinfo}->{$col} } );
    }
    $self->xml_end_tag( 'cols' );
}
sub _write_col_info {
    my $self         = shift;
    my $min          = $_[0] || 0;
    my $max          = $_[1] || 0;
    my $width        = $_[2];
    my $format       = $_[3];
    my $hidden       = $_[4] || 0;
    my $level        = $_[5] || 0;
    my $collapsed    = $_[6] || 0;
    my $custom_width = 1;
    my $xf_index     = 0;
    if ( ref( $format ) ) {
        $xf_index = $format->get_xf_index();
    }
    if ( !defined $width ) {
        if ( !$hidden ) {
            $width        = 8.43;
            $custom_width = 0;
        }
        else {
            $width = 0;
        }
    }
    else {
        if ( $width == 8.43 ) {
            $custom_width = 0;
        }
    }
    my $max_digit_width = 7;
    my $padding         = 5;
    if ( $width > 0 ) {
        if ( $width < 1 ) {
            $width =
              int( ( int( $width * ($max_digit_width + $padding) + 0.5 ) ) /
                  $max_digit_width *
                  256 ) / 256;
        }
        else {
            $width =
              int( ( int( $width * $max_digit_width + 0.5 ) + $padding ) /
                  $max_digit_width *
                  256 ) / 256;
        }
    }
    my @attributes = (
        'min'   => $min + 1,
        'max'   => $max + 1,
        'width' => $width,
    );
    push @attributes, ( 'style'        => $xf_index ) if $xf_index;
    push @attributes, ( 'hidden'       => 1 )         if $hidden;
    push @attributes, ( 'customWidth'  => 1 )         if $custom_width;
    push @attributes, ( 'outlineLevel' => $level )    if $level;
    push @attributes, ( 'collapsed'    => 1 )         if $collapsed;
    $self->xml_empty_tag( 'col', @attributes );
}
sub _write_sheet_data {
    my $self = shift;
    if ( not defined $self->{_dim_rowmin} ) {
        $self->xml_empty_tag( 'sheetData' );
    }
    else {
        $self->xml_start_tag( 'sheetData' );
        $self->_write_rows();
        $self->xml_end_tag( 'sheetData' );
    }
}
sub _write_optimized_sheet_data {
    my $self = shift;
    if ( not defined $self->{_dim_rowmin} ) {
        $self->xml_empty_tag( 'sheetData' );
    }
    else {
        $self->xml_start_tag( 'sheetData' );
        my $xlsx_fh = $self->xml_get_fh();
        my $cell_fh = $self->{_cell_data_fh};
        my $buffer;
        seek $cell_fh, 0, 0;
        while ( read( $cell_fh, $buffer, 4_096 ) ) {
            local $\ = undef;
            print $xlsx_fh $buffer;
        }
        $self->xml_end_tag( 'sheetData' );
    }
}
sub _write_rows {
    my $self = shift;
    $self->_calculate_spans();
    for my $row_num ( $self->{_dim_rowmin} .. $self->{_dim_rowmax} ) {
        if (   !$self->{_set_rows}->{$row_num}
            && !$self->{_table}->{$row_num}
            && !$self->{_comments}->{$row_num} )
        {
            next;
        }
        my $span_index = int( $row_num / 16 );
        my $span       = $self->{_row_spans}->[$span_index];
        if ( my $row_ref = $self->{_table}->{$row_num} ) {
            if ( !$self->{_set_rows}->{$row_num} ) {
                $self->_write_row( $row_num, $span );
            }
            else {
                $self->_write_row( $row_num, $span,
                    @{ $self->{_set_rows}->{$row_num} } );
            }
            for my $col_num ( $self->{_dim_colmin} .. $self->{_dim_colmax} ) {
                if ( my $col_ref = $self->{_table}->{$row_num}->{$col_num} ) {
                    $self->_write_cell( $row_num, $col_num, $col_ref );
                }
            }
            $self->xml_end_tag( 'row' );
        }
        elsif ( $self->{_comments}->{$row_num} ) {
            $self->_write_empty_row( $row_num, $span,
                @{ $self->{_set_rows}->{$row_num} } );
        }
        else {
            $self->_write_empty_row( $row_num, $span,
                @{ $self->{_set_rows}->{$row_num} } );
        }
    }
}
sub _write_single_row {
    my $self        = shift;
    my $current_row = shift || 0;
    my $row_num     = $self->{_previous_row};
    $self->{_previous_row} = $current_row;
    if (   !$self->{_set_rows}->{$row_num}
        && !$self->{_table}->{$row_num}
        && !$self->{_comments}->{$row_num} )
    {
        return;
    }
    if ( my $row_ref = $self->{_table}->{$row_num} ) {
        if ( !$self->{_set_rows}->{$row_num} ) {
            $self->_write_row( $row_num );
        }
        else {
            $self->_write_row( $row_num, undef,
                @{ $self->{_set_rows}->{$row_num} } );
        }
        for my $col_num ( $self->{_dim_colmin} .. $self->{_dim_colmax} ) {
            if ( my $col_ref = $self->{_table}->{$row_num}->{$col_num} ) {
                $self->_write_cell( $row_num, $col_num, $col_ref );
            }
        }
        $self->xml_end_tag( 'row' );
    }
    else {
        $self->_write_empty_row( $row_num, undef,
            @{ $self->{_set_rows}->{$row_num} } );
    }
    $self->{_table} = {};
}
sub _calculate_spans {
    my $self = shift;
    my @spans;
    my $span_min;
    my $span_max;
    for my $row_num ( $self->{_dim_rowmin} .. $self->{_dim_rowmax} ) {
        if ( my $row_ref = $self->{_table}->{$row_num} ) {
            for my $col_num ( $self->{_dim_colmin} .. $self->{_dim_colmax} ) {
                if ( my $col_ref = $self->{_table}->{$row_num}->{$col_num} ) {
                    if ( !defined $span_min ) {
                        $span_min = $col_num;
                        $span_max = $col_num;
                    }
                    else {
                        $span_min = $col_num if $col_num < $span_min;
                        $span_max = $col_num if $col_num > $span_max;
                    }
                }
            }
        }
        if ( defined $self->{_comments}->{$row_num} ) {
            for my $col_num ( $self->{_dim_colmin} .. $self->{_dim_colmax} ) {
                if ( defined $self->{_comments}->{$row_num}->{$col_num} ) {
                    if ( !defined $span_min ) {
                        $span_min = $col_num;
                        $span_max = $col_num;
                    }
                    else {
                        $span_min = $col_num if $col_num < $span_min;
                        $span_max = $col_num if $col_num > $span_max;
                    }
                }
            }
        }
        if ( ( ( $row_num + 1 ) % 16 == 0 )
            || $row_num == $self->{_dim_rowmax} )
        {
            my $span_index = int( $row_num / 16 );
            if ( defined $span_min ) {
                $span_min++;
                $span_max++;
                $spans[$span_index] = "$span_min:$span_max";
                $span_min = undef;
            }
        }
    }
    $self->{_row_spans} = \@spans;
}
sub _write_row {
    my $self      = shift;
    my $r         = shift;
    my $spans     = shift;
    my $height    = shift;
    my $format    = shift;
    my $hidden    = shift || 0;
    my $level     = shift || 0;
    my $collapsed = shift || 0;
    my $empty_row = shift || 0;
    my $xf_index  = 0;
    $height = $self->{_default_row_height} if !defined $height;
    my @attributes = ( 'r' => $r + 1 );
    if ( ref( $format ) ) {
        $xf_index = $format->get_xf_index();
    }
    push @attributes, ( 'spans'        => $spans )    if defined $spans;
    push @attributes, ( 's'            => $xf_index ) if $xf_index;
    push @attributes, ( 'customFormat' => 1 )         if $format;
    if ( $height != $self->{_original_row_height} ) {
        push @attributes, ( 'ht' => $height );
    }
    push @attributes, ( 'hidden'       => 1 )         if $hidden;
    if ( $height != $self->{_original_row_height} ) {
        push @attributes, ( 'customHeight' => 1 );
    }
    push @attributes, ( 'outlineLevel' => $level )    if $level;
    push @attributes, ( 'collapsed'    => 1 )         if $collapsed;
    if ( $self->{_excel_version} == 2010 ) {
        push @attributes, ( 'x14ac:dyDescent' => '0.25' );
    }
    if ( $empty_row ) {
        $self->xml_empty_tag_unencoded( 'row', @attributes );
    }
    else {
        $self->xml_start_tag_unencoded( 'row', @attributes );
    }
}
sub _write_empty_row {
    my $self = shift;
    $_[7] = 1;
    $self->_write_row( @_ );
}
sub _write_cell {
    my $self     = shift;
    my $row      = shift;
    my $col      = shift;
    my $cell     = shift;
    my $type     = $cell->[0];
    my $token    = $cell->[1];
    my $xf       = $cell->[2];
    my $xf_index = 0;
    my %error_codes = (
        '#DIV/0!' => 1,
        '#N/A'    => 1,
        '#NAME?'  => 1,
        '#NULL!'  => 1,
        '#NUM!'   => 1,
        '#REF!'   => 1,
        '#VALUE!' => 1,
    );
    my %boolean = ( 'TRUE' => 1, 'FALSE' => 0 );
    if ( ref( $xf ) ) {
        $xf_index = $xf->get_xf_index();
    }
    my $range = _xl_rowcol_to_cell( $row, $col );
    my @attributes = ( 'r' => $range );
    if ( $xf_index ) {
        push @attributes, ( 's' => $xf_index );
    }
    elsif ( $self->{_set_rows}->{$row} && $self->{_set_rows}->{$row}->[1] ) {
        my $row_xf = $self->{_set_rows}->{$row}->[1];
        push @attributes, ( 's' => $row_xf->get_xf_index() );
    }
    elsif ( $self->{_col_formats}->{$col} ) {
        my $col_xf = $self->{_col_formats}->{$col};
        push @attributes, ( 's' => $col_xf->get_xf_index() );
    }
    if ( $type eq 'n' ) {
        $self->xml_number_element( $token, @attributes );
    }
    elsif ( $type eq 's' ) {
        if ( $self->{_optimization} == 0 ) {
            $self->xml_string_element( $token, @attributes );
        }
        else {
            my $string = $token;
            $string =~ s/(_x[0-9a-fA-F]{4}_)/_x005F$1/g;
            $string =~ s/([\x00-\x08\x0B-\x1F])/sprintf "_x%04X_", ord($1)/eg;
            if ( $string =~ m{^<r>} && $string =~ m{</r>$} ) {
                $self->xml_rich_inline_string( $string, @attributes );
            }
            else {
                my $preserve = 0;
                if ( $string =~ /^\s/ || $string =~ /\s$/ ) {
                    $preserve = 1;
                }
                $self->xml_inline_string( $string, $preserve, @attributes );
            }
        }
    }
    elsif ( $type eq 'f' ) {
        my $value = $cell->[3] || 0;
        if (   $value
            && $value !~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ )
        {
            if ( exists $boolean{$value} ) {
                push @attributes, ( 't' => 'b' );
                $value = $boolean{$value};
            }
            elsif ( exists $error_codes{$value} ) {
                push @attributes, ( 't' => 'e' );
            }
            else {
                push @attributes, ( 't' => 'str' );
                $value = Excel::Writer::XLSX::Package::XMLwriter::_escape_data(
                    $value );
            }
        }
        $self->xml_formula_element( $token, $value, @attributes );
    }
    elsif ( $type eq 'a' ) {
        $self->xml_start_tag( 'c', @attributes );
        $self->_write_cell_array_formula( $token, $cell->[3] );
        $self->_write_cell_value( $cell->[4] );
        $self->xml_end_tag( 'c' );
    }
    elsif ( $type eq 'l' ) {
        push @attributes, ( 't' => 'b' );
        $self->xml_start_tag( 'c', @attributes );
        $self->_write_cell_value( $cell->[1] );
        $self->xml_end_tag( 'c' );
    }
    elsif ( $type eq 'b' ) {
        $self->xml_empty_tag( 'c', @attributes );
    }
}
sub _write_cell_value {
    my $self = shift;
    my $value = defined $_[0] ? $_[0] : '';
    $self->xml_data_element( 'v', $value );
}
sub _write_cell_formula {
    my $self = shift;
    my $formula = defined $_[0] ? $_[0] : '';
    $self->xml_data_element( 'f', $formula );
}
sub _write_cell_array_formula {
    my $self    = shift;
    my $formula = shift;
    my $range   = shift;
    my @attributes = ( 't' => 'array', 'ref' => $range );
    $self->xml_data_element( 'f', $formula, @attributes );
}
sub _write_sheet_calc_pr {
    my $self              = shift;
    my $full_calc_on_load = 1;
    my @attributes = ( 'fullCalcOnLoad' => $full_calc_on_load );
    $self->xml_empty_tag( 'sheetCalcPr', @attributes );
}
sub _write_phonetic_pr {
    my $self    = shift;
    my $font_id = 0;
    my $type    = 'noConversion';
    my @attributes = (
        'fontId' => $font_id,
        'type'   => $type,
    );
    $self->xml_empty_tag( 'phoneticPr', @attributes );
}
sub _write_page_margins {
    my $self = shift;
    my @attributes = (
        'left'   => $self->{_margin_left},
        'right'  => $self->{_margin_right},
        'top'    => $self->{_margin_top},
        'bottom' => $self->{_margin_bottom},
        'header' => $self->{_margin_header},
        'footer' => $self->{_margin_footer},
    );
    $self->xml_empty_tag( 'pageMargins', @attributes );
}
sub _write_page_setup {
    my $self       = shift;
    my @attributes = ();
    return unless $self->{_page_setup_changed};
    if ( $self->{_paper_size} ) {
        push @attributes, ( 'paperSize' => $self->{_paper_size} );
    }
    if ( $self->{_print_scale} != 100 ) {
        push @attributes, ( 'scale' => $self->{_print_scale} );
    }
    if ( $self->{_fit_page} && $self->{_fit_width} != 1 ) {
        push @attributes, ( 'fitToWidth' => $self->{_fit_width} );
    }
    if ( $self->{_fit_page} && $self->{_fit_height} != 1 ) {
        push @attributes, ( 'fitToHeight' => $self->{_fit_height} );
    }
    if ( $self->{_page_order} ) {
        push @attributes, ( 'pageOrder' => "overThenDown" );
    }
    if ( $self->{_page_start} > 1 ) {
        push @attributes, ( 'firstPageNumber' => $self->{_page_start} );
    }
    if ( $self->{_orientation} == 0 ) {
        push @attributes, ( 'orientation' => 'landscape' );
    }
    else {
        push @attributes, ( 'orientation' => 'portrait' );
    }
    if ( $self->{_black_white} ) {
        push @attributes, ( 'blackAndWhite' => 1 );
    }
    if ( $self->{_page_start} != 0 ) {
        push @attributes, ( 'useFirstPageNumber' => 1 );
    }
    if ( $self->{_horizontal_dpi} ) {
        push @attributes, ( 'horizontalDpi' => $self->{_horizontal_dpi} );
    }
    if ( $self->{_vertical_dpi} ) {
        push @attributes, ( 'verticalDpi' => $self->{_vertical_dpi} );
    }
    $self->xml_empty_tag( 'pageSetup', @attributes );
}
sub _write_merge_cells {
    my $self         = shift;
    my $merged_cells = $self->{_merge};
    my $count        = @$merged_cells;
    return unless $count;
    my @attributes = ( 'count' => $count );
    $self->xml_start_tag( 'mergeCells', @attributes );
    for my $merged_range ( @$merged_cells ) {
        $self->_write_merge_cell( $merged_range );
    }
    $self->xml_end_tag( 'mergeCells' );
}
sub _write_merge_cell {
    my $self         = shift;
    my $merged_range = shift;
    my ( $row_min, $col_min, $row_max, $col_max ) = @$merged_range;
    my $cell_1 = xl_rowcol_to_cell( $row_min, $col_min );
    my $cell_2 = xl_rowcol_to_cell( $row_max, $col_max );
    my $ref    = $cell_1 . ':' . $cell_2;
    my @attributes = ( 'ref' => $ref );
    $self->xml_empty_tag( 'mergeCell', @attributes );
}
sub _write_print_options {
    my $self       = shift;
    my @attributes = ();
    return unless $self->{_print_options_changed};
    if ( $self->{_hcenter} ) {
        push @attributes, ( 'horizontalCentered' => 1 );
    }
    if ( $self->{_vcenter} ) {
        push @attributes, ( 'verticalCentered' => 1 );
    }
    if ( $self->{_print_headers} ) {
        push @attributes, ( 'headings' => 1 );
    }
    if ( $self->{_print_gridlines} ) {
        push @attributes, ( 'gridLines' => 1 );
    }
    $self->xml_empty_tag( 'printOptions', @attributes );
}
sub _write_header_footer {
    my $self       = shift;
    my @attributes = ();
    if ( !$self->{_header_footer_scales} ) {
        push @attributes, ( 'scaleWithDoc' => 0 );
    }
    if ( !$self->{_header_footer_aligns} ) {
        push @attributes, ( 'alignWithMargins' => 0 );
    }
    if ( $self->{_header_footer_changed} ) {
        $self->xml_start_tag( 'headerFooter', @attributes );
        $self->_write_odd_header() if $self->{_header};
        $self->_write_odd_footer() if $self->{_footer};
        $self->xml_end_tag( 'headerFooter' );
    }
    elsif ( $self->{_excel2003_style} ) {
        $self->xml_empty_tag( 'headerFooter', @attributes );
    }
}
sub _write_odd_header {
    my $self = shift;
    my $data = $self->{_header};
    $self->xml_data_element( 'oddHeader', $data );
}
sub _write_odd_footer {
    my $self = shift;
    my $data = $self->{_footer};
    $self->xml_data_element( 'oddFooter', $data );
}
sub _write_row_breaks {
    my $self = shift;
    my @page_breaks = $self->_sort_pagebreaks( @{ $self->{_hbreaks} } );
    my $count       = scalar @page_breaks;
    return unless @page_breaks;
    my @attributes = (
        'count'            => $count,
        'manualBreakCount' => $count,
    );
    $self->xml_start_tag( 'rowBreaks', @attributes );
    for my $row_num ( @page_breaks ) {
        $self->_write_brk( $row_num, 16383 );
    }
    $self->xml_end_tag( 'rowBreaks' );
}
sub _write_col_breaks {
    my $self = shift;
    my @page_breaks = $self->_sort_pagebreaks( @{ $self->{_vbreaks} } );
    my $count       = scalar @page_breaks;
    return unless @page_breaks;
    my @attributes = (
        'count'            => $count,
        'manualBreakCount' => $count,
    );
    $self->xml_start_tag( 'colBreaks', @attributes );
    for my $col_num ( @page_breaks ) {
        $self->_write_brk( $col_num, 1048575 );
    }
    $self->xml_end_tag( 'colBreaks' );
}
sub _write_brk {
    my $self = shift;
    my $id   = shift;
    my $max  = shift;
    my $man  = 1;
    my @attributes = (
        'id'  => $id,
        'max' => $max,
        'man' => $man,
    );
    $self->xml_empty_tag( 'brk', @attributes );
}
sub _write_auto_filter {
    my $self = shift;
    my $ref  = $self->{_autofilter_ref};
    return unless $ref;
    my @attributes = ( 'ref' => $ref );
    if ( $self->{_filter_on} ) {
        $self->xml_start_tag( 'autoFilter', @attributes );
        $self->_write_autofilters();
        $self->xml_end_tag( 'autoFilter' );
    }
    else {
        $self->xml_empty_tag( 'autoFilter', @attributes );
    }
}
sub _write_autofilters {
    my $self = shift;
    my ( $col1, $col2 ) = @{ $self->{_filter_range} };
    for my $col ( $col1 .. $col2 ) {
        next unless $self->{_filter_cols}->{$col};
        my @tokens = @{ $self->{_filter_cols}->{$col} };
        my $type   = $self->{_filter_type}->{$col};
        $self->_write_filter_column( $col - $col1, $type, \@tokens );
    }
}
sub _write_filter_column {
    my $self    = shift;
    my $col_id  = shift;
    my $type    = shift;
    my $filters = shift;
    my @attributes = ( 'colId' => $col_id );
    $self->xml_start_tag( 'filterColumn', @attributes );
    if ( $type == 1 ) {
        $self->_write_filters( @$filters );
    }
    else {
        $self->_write_custom_filters( @$filters );
    }
    $self->xml_end_tag( 'filterColumn' );
}
sub _write_filters {
    my $self       = shift;
    my @filters    = @_;
    my @non_blanks = grep { !/^blanks$/i } @filters;
    my @attributes = ();
    if ( @filters != @non_blanks ) {
        @attributes = ( 'blank' => 1 );
    }
    if ( @filters == 1 && @non_blanks == 0 ) {
        $self->xml_empty_tag( 'filters', @attributes );
    }
    else {
        $self->xml_start_tag( 'filters', @attributes );
        for my $filter ( sort @non_blanks ) {
            $self->_write_filter( $filter );
        }
        $self->xml_end_tag( 'filters' );
    }
}
sub _write_filter {
    my $self = shift;
    my $val  = shift;
    my @attributes = ( 'val' => $val );
    $self->xml_empty_tag( 'filter', @attributes );
}
sub _write_custom_filters {
    my $self   = shift;
    my @tokens = @_;
    if ( @tokens == 2 ) {
        $self->xml_start_tag( 'customFilters' );
        $self->_write_custom_filter( @tokens );
        $self->xml_end_tag( 'customFilters' );
    }
    else {
        my @attributes;
        if ( $tokens[2] == 0 ) {
            @attributes = ( 'and' => 1 );
        }
        else {
            @attributes = ( 'and' => 0 );
        }
        $self->xml_start_tag( 'customFilters', @attributes );
        $self->_write_custom_filter( $tokens[0], $tokens[1] );
        $self->_write_custom_filter( $tokens[3], $tokens[4] );
        $self->xml_end_tag( 'customFilters' );
    }
}
sub _write_custom_filter {
    my $self       = shift;
    my $operator   = shift;
    my $val        = shift;
    my @attributes = ();
    my %operators = (
        1  => 'lessThan',
        2  => 'equal',
        3  => 'lessThanOrEqual',
        4  => 'greaterThan',
        5  => 'notEqual',
        6  => 'greaterThanOrEqual',
        22 => 'equal',
    );
    if ( defined $operators{$operator} ) {
        $operator = $operators{$operator};
    }
    else {
        croak "Unknown operator = $operator\n";
    }
    push @attributes, ( 'operator' => $operator ) unless $operator eq 'equal';
    push @attributes, ( 'val' => $val );
    $self->xml_empty_tag( 'customFilter', @attributes );
}
sub _write_hyperlinks {
    my $self = shift;
    my @hlink_refs;
    my @row_nums = sort { $a <=> $b } keys %{ $self->{_hyperlinks} };
    return if !@row_nums;
    for my $row_num ( @row_nums ) {
        my @col_nums = sort { $a <=> $b }
          keys %{ $self->{_hyperlinks}->{$row_num} };
        for my $col_num ( @col_nums ) {
            my $link      = $self->{_hyperlinks}->{$row_num}->{$col_num};
            my $link_type = $link->{_link_type};
            my $display;
            if (   $self->{_table}
                && $self->{_table}->{$row_num}
                && $self->{_table}->{$row_num}->{$col_num} )
            {
                my $cell = $self->{_table}->{$row_num}->{$col_num};
                $display = $link->{_url} if $cell->[0] ne 's';
            }
            if ( $link_type == 1 ) {
                push @hlink_refs,
                  [
                    $link_type,    $row_num,
                    $col_num,      ++$self->{_rel_count},
                    $link->{_str}, $display,
                    $link->{_tip}
                  ];
                push @{ $self->{_external_hyper_links} },
                  [ '/hyperlink', $link->{_url}, 'External' ];
            }
            else {
                push @hlink_refs,
                  [
                    $link_type,    $row_num,      $col_num,
                    $link->{_url}, $link->{_str}, $link->{_tip}
                  ];
            }
        }
    }
    $self->xml_start_tag( 'hyperlinks' );
    for my $aref ( @hlink_refs ) {
        my ( $type, @args ) = @$aref;
        if ( $type == 1 ) {
            $self->_write_hyperlink_external( @args );
        }
        elsif ( $type == 2 ) {
            $self->_write_hyperlink_internal( @args );
        }
    }
    $self->xml_end_tag( 'hyperlinks' );
}
sub _write_hyperlink_external {
    my $self     = shift;
    my $row      = shift;
    my $col      = shift;
    my $id       = shift;
    my $location = shift;
    my $display  = shift;
    my $tooltip  = shift;
    my $ref = xl_rowcol_to_cell( $row, $col );
    my $r_id = 'rId' . $id;
    my @attributes = (
        'ref'  => $ref,
        'r:id' => $r_id,
    );
    push @attributes, ( 'location' => $location ) if defined $location;
    push @attributes, ( 'display' => $display )   if defined $display;
    push @attributes, ( 'tooltip'  => $tooltip )  if defined $tooltip;
    $self->xml_empty_tag( 'hyperlink', @attributes );
}
sub _write_hyperlink_internal {
    my $self     = shift;
    my $row      = shift;
    my $col      = shift;
    my $location = shift;
    my $display  = shift;
    my $tooltip  = shift;
    my $ref = xl_rowcol_to_cell( $row, $col );
    my @attributes = ( 'ref' => $ref, 'location' => $location );
    push @attributes, ( 'tooltip' => $tooltip ) if defined $tooltip;
    push @attributes, ( 'display' => $display );
    $self->xml_empty_tag( 'hyperlink', @attributes );
}
sub _write_panes {
    my $self  = shift;
    my @panes = @{ $self->{_panes} };
    return unless @panes;
    if ( $panes[4] == 2 ) {
        $self->_write_split_panes( @panes );
    }
    else {
        $self->_write_freeze_panes( @panes );
    }
}
sub _write_freeze_panes {
    my $self = shift;
    my @attributes;
    my ( $row, $col, $top_row, $left_col, $type ) = @_;
    my $y_split       = $row;
    my $x_split       = $col;
    my $top_left_cell = xl_rowcol_to_cell( $top_row, $left_col );
    my $active_pane;
    my $state;
    my $active_cell;
    my $sqref;
    if ( @{ $self->{_selections} } ) {
        ( undef, $active_cell, $sqref ) = @{ $self->{_selections}->[0] };
        $self->{_selections} = [];
    }
    if ( $row && $col ) {
        $active_pane = 'bottomRight';
        my $row_cell = xl_rowcol_to_cell( $row, 0 );
        my $col_cell = xl_rowcol_to_cell( 0,    $col );
        push @{ $self->{_selections} },
          (
            [ 'topRight',    $col_cell,    $col_cell ],
            [ 'bottomLeft',  $row_cell,    $row_cell ],
            [ 'bottomRight', $active_cell, $sqref ]
          );
    }
    elsif ( $col ) {
        $active_pane = 'topRight';
        push @{ $self->{_selections} }, [ 'topRight', $active_cell, $sqref ];
    }
    else {
        $active_pane = 'bottomLeft';
        push @{ $self->{_selections} }, [ 'bottomLeft', $active_cell, $sqref ];
    }
    if ( $type == 0 ) {
        $state = 'frozen';
    }
    elsif ( $type == 1 ) {
        $state = 'frozenSplit';
    }
    else {
        $state = 'split';
    }
    push @attributes, ( 'xSplit' => $x_split ) if $x_split;
    push @attributes, ( 'ySplit' => $y_split ) if $y_split;
    push @attributes, ( 'topLeftCell' => $top_left_cell );
    push @attributes, ( 'activePane'  => $active_pane );
    push @attributes, ( 'state'       => $state );
    $self->xml_empty_tag( 'pane', @attributes );
}
sub _write_split_panes {
    my $self = shift;
    my @attributes;
    my $y_split;
    my $x_split;
    my $has_selection = 0;
    my $active_pane;
    my $active_cell;
    my $sqref;
    my ( $row, $col, $top_row, $left_col, $type ) = @_;
    $y_split = $row;
    $x_split = $col;
    if ( @{ $self->{_selections} } ) {
        ( undef, $active_cell, $sqref ) = @{ $self->{_selections}->[0] };
        $self->{_selections} = [];
        $has_selection = 1;
    }
    $y_split = int( 20 * $y_split + 300 ) if $y_split;
    $x_split = $self->_calculate_x_split_width( $x_split ) if $x_split;
    if ( $top_row == $row && $left_col == $col ) {
        $top_row  = int( 0.5 + ( $y_split - 300 ) / 20 / 15 );
        $left_col = int( 0.5 + ( $x_split - 390 ) / 20 / 3 * 4 / 64 );
    }
    my $top_left_cell = xl_rowcol_to_cell( $top_row, $left_col );
    if ( !$has_selection ) {
        $active_cell = $top_left_cell;
        $sqref       = $top_left_cell;
    }
    if ( $row && $col ) {
        $active_pane = 'bottomRight';
        my $row_cell = xl_rowcol_to_cell( $top_row, 0 );
        my $col_cell = xl_rowcol_to_cell( 0,        $left_col );
        push @{ $self->{_selections} },
          (
            [ 'topRight',    $col_cell,    $col_cell ],
            [ 'bottomLeft',  $row_cell,    $row_cell ],
            [ 'bottomRight', $active_cell, $sqref ]
          );
    }
    elsif ( $col ) {
        $active_pane = 'topRight';
        push @{ $self->{_selections} }, [ 'topRight', $active_cell, $sqref ];
    }
    else {
        $active_pane = 'bottomLeft';
        push @{ $self->{_selections} }, [ 'bottomLeft', $active_cell, $sqref ];
    }
    push @attributes, ( 'xSplit' => $x_split ) if $x_split;
    push @attributes, ( 'ySplit' => $y_split ) if $y_split;
    push @attributes, ( 'topLeftCell' => $top_left_cell );
    push @attributes, ( 'activePane' => $active_pane ) if $has_selection;
    $self->xml_empty_tag( 'pane', @attributes );
}
sub _calculate_x_split_width {
    my $self  = shift;
    my $width = shift;
    my $max_digit_width = 7;
    my $padding         = 5;
    my $pixels;
    if ( $width < 1 ) {
        $pixels = int( $width * ( $max_digit_width + $padding ) + 0.5 );
    }
    else {
          $pixels = int( $width * $max_digit_width + 0.5 ) + $padding;
    }
    my $points = $pixels * 3 / 4;
    my $twips = $points * 20;
    $width = $twips + 390;
    return $width;
}
sub _write_tab_color {
    my $self        = shift;
    my $color_index = $self->{_tab_color};
    return unless $color_index;
    my $rgb = $self->_get_palette_color( $color_index );
    my @attributes = ( 'rgb' => $rgb );
    $self->xml_empty_tag( 'tabColor', @attributes );
}
sub _write_outline_pr {
    my $self       = shift;
    my @attributes = ();
    return unless $self->{_outline_changed};
    push @attributes, ( "applyStyles"        => 1 ) if $self->{_outline_style};
    push @attributes, ( "summaryBelow"       => 0 ) if !$self->{_outline_below};
    push @attributes, ( "summaryRight"       => 0 ) if !$self->{_outline_right};
    push @attributes, ( "showOutlineSymbols" => 0 ) if !$self->{_outline_on};
    $self->xml_empty_tag( 'outlinePr', @attributes );
}
sub _write_sheet_protection {
    my $self = shift;
    my @attributes;
    return unless $self->{_protect};
    my %arg = %{ $self->{_protect} };
    push @attributes, ( "password"    => $arg{password} ) if $arg{password};
    push @attributes, ( "sheet"       => 1 )              if $arg{sheet};
    push @attributes, ( "content"     => 1 )              if $arg{content};
    push @attributes, ( "objects"     => 1 )              if !$arg{objects};
    push @attributes, ( "scenarios"   => 1 )              if !$arg{scenarios};
    push @attributes, ( "formatCells" => 0 )              if $arg{format_cells};
    push @attributes, ( "formatColumns"    => 0 ) if $arg{format_columns};
    push @attributes, ( "formatRows"       => 0 ) if $arg{format_rows};
    push @attributes, ( "insertColumns"    => 0 ) if $arg{insert_columns};
    push @attributes, ( "insertRows"       => 0 ) if $arg{insert_rows};
    push @attributes, ( "insertHyperlinks" => 0 ) if $arg{insert_hyperlinks};
    push @attributes, ( "deleteColumns"    => 0 ) if $arg{delete_columns};
    push @attributes, ( "deleteRows"       => 0 ) if $arg{delete_rows};
    push @attributes, ( "selectLockedCells" => 1 )
      if !$arg{select_locked_cells};
    push @attributes, ( "sort"        => 0 ) if $arg{sort};
    push @attributes, ( "autoFilter"  => 0 ) if $arg{autofilter};
    push @attributes, ( "pivotTables" => 0 ) if $arg{pivot_tables};
    push @attributes, ( "selectUnlockedCells" => 1 )
      if !$arg{select_unlocked_cells};
    $self->xml_empty_tag( 'sheetProtection', @attributes );
}
sub _write_drawings {
    my $self = shift;
    return unless $self->{_drawing};
    $self->_write_drawing( ++$self->{_rel_count} );
}
sub _write_drawing {
    my $self = shift;
    my $id   = shift;
    my $r_id = 'rId' . $id;
    my @attributes = ( 'r:id' => $r_id );
    $self->xml_empty_tag( 'drawing', @attributes );
}
sub _write_legacy_drawing {
    my $self = shift;
    my $id;
    return unless $self->{_has_vml};
    $id = ++$self->{_rel_count};
    my @attributes = ( 'r:id' => 'rId' . $id );
    $self->xml_empty_tag( 'legacyDrawing', @attributes );
}
sub _write_legacy_drawing_hf {
    my $self = shift;
    my $id;
    return unless $self->{_has_header_vml};
    $id = ++$self->{_rel_count};
    my @attributes = ( 'r:id' => 'rId' . $id );
    $self->xml_empty_tag( 'legacyDrawingHF', @attributes );
}
sub _write_font {
    my $self   = shift;
    my $format = shift;
    $self->{_rstring}->xml_start_tag( 'rPr' );
    $self->{_rstring}->xml_empty_tag( 'b' )       if $format->{_bold};
    $self->{_rstring}->xml_empty_tag( 'i' )       if $format->{_italic};
    $self->{_rstring}->xml_empty_tag( 'strike' )  if $format->{_font_strikeout};
    $self->{_rstring}->xml_empty_tag( 'outline' ) if $format->{_font_outline};
    $self->{_rstring}->xml_empty_tag( 'shadow' )  if $format->{_font_shadow};
    $self->_write_underline( $format->{_underline} ) if $format->{_underline};
    $self->_write_vert_align( 'superscript' ) if $format->{_font_script} == 1;
    $self->_write_vert_align( 'subscript' )   if $format->{_font_script} == 2;
    $self->{_rstring}->xml_empty_tag( 'sz', 'val', $format->{_size} );
    if ( my $theme = $format->{_theme} ) {
        $self->_write_rstring_color( 'theme' => $theme );
    }
    elsif ( my $color = $format->{_color} ) {
        $color = $self->_get_palette_color( $color );
        $self->_write_rstring_color( 'rgb' => $color );
    }
    else {
        $self->_write_rstring_color( 'theme' => 1 );
    }
    $self->{_rstring}->xml_empty_tag( 'rFont', 'val', $format->{_font} );
    $self->{_rstring}
      ->xml_empty_tag( 'family', 'val', $format->{_font_family} );
    if ( $format->{_font} eq 'Calibri' && !$format->{_hyperlink} ) {
        $self->{_rstring}
          ->xml_empty_tag( 'scheme', 'val', $format->{_font_scheme} );
    }
    $self->{_rstring}->xml_end_tag( 'rPr' );
}
sub _write_underline {
    my $self      = shift;
    my $underline = shift;
    my @attributes;
    if ( $underline == 2 ) {
        @attributes = ( val => 'double' );
    }
    elsif ( $underline == 33 ) {
        @attributes = ( val => 'singleAccounting' );
    }
    elsif ( $underline == 34 ) {
        @attributes = ( val => 'doubleAccounting' );
    }
    else {
        @attributes = ();
    }
    $self->{_rstring}->xml_empty_tag( 'u', @attributes );
}
sub _write_vert_align {
    my $self = shift;
    my $val  = shift;
    my @attributes = ( 'val' => $val );
    $self->{_rstring}->xml_empty_tag( 'vertAlign', @attributes );
}
sub _write_rstring_color {
    my $self  = shift;
    my $name  = shift;
    my $value = shift;
    my @attributes = ( $name => $value );
    $self->{_rstring}->xml_empty_tag( 'color', @attributes );
}
sub _write_data_validations {
    my $self        = shift;
    my @validations = @{ $self->{_validations} };
    my $count       = @validations;
    return unless $count;
    my @attributes = ( 'count' => $count );
    $self->xml_start_tag( 'dataValidations', @attributes );
    for my $validation ( @validations ) {
        $self->_write_data_validation( $validation );
    }
    $self->xml_end_tag( 'dataValidations' );
}
sub _write_data_validation {
    my $self       = shift;
    my $param      = shift;
    my $sqref      = '';
    my @attributes = ();
    for my $cells ( @{ $param->{cells} } ) {
        $sqref .= ' ' if $sqref ne '';
        my ( $row_first, $col_first, $row_last, $col_last ) = @$cells;
        if ( $row_first > $row_last ) {
            ( $row_first, $row_last ) = ( $row_last, $row_first );
        }
        if ( $col_first > $col_last ) {
            ( $col_first, $col_last ) = ( $col_last, $col_first );
        }
        if ( ( $row_first == $row_last ) && ( $col_first == $col_last ) ) {
            $sqref .= xl_rowcol_to_cell( $row_first, $col_first );
        }
        else {
            $sqref .= xl_range( $row_first, $row_last, $col_first, $col_last );
        }
    }
    if ( $param->{validate} ne 'none' ) {
        push @attributes, ( 'type' => $param->{validate} );
        if ( $param->{criteria} ne 'between' ) {
            push @attributes, ( 'operator' => $param->{criteria} );
        }
    }
    if ( $param->{error_type} ) {
        push @attributes, ( 'errorStyle' => 'warning' )
          if $param->{error_type} == 1;
        push @attributes, ( 'errorStyle' => 'information' )
          if $param->{error_type} == 2;
    }
    push @attributes, ( 'allowBlank'       => 1 ) if $param->{ignore_blank};
    push @attributes, ( 'showDropDown'     => 1 ) if !$param->{dropdown};
    push @attributes, ( 'showInputMessage' => 1 ) if $param->{show_input};
    push @attributes, ( 'showErrorMessage' => 1 ) if $param->{show_error};
    push @attributes, ( 'errorTitle' => $param->{error_title} )
      if $param->{error_title};
    push @attributes, ( 'error' => $param->{error_message} )
      if $param->{error_message};
    push @attributes, ( 'promptTitle' => $param->{input_title} )
      if $param->{input_title};
    push @attributes, ( 'prompt' => $param->{input_message} )
      if $param->{input_message};
    push @attributes, ( 'sqref' => $sqref );
    if ( $param->{validate} eq 'none' ) {
        $self->xml_empty_tag( 'dataValidation', @attributes );
    }
    else {
        $self->xml_start_tag( 'dataValidation', @attributes );
        $self->_write_formula_1( $param->{value} );
        $self->_write_formula_2( $param->{maximum} )
          if defined $param->{maximum};
        $self->xml_end_tag( 'dataValidation' );
    }
}
sub _write_formula_1 {
    my $self    = shift;
    my $formula = shift;
    if ( ref $formula eq 'ARRAY' ) {
        $formula = join ',', @$formula;
        $formula = qq("$formula");
    }
    $formula =~ s/^=//;
    $self->xml_data_element( 'formula1', $formula );
}
sub _write_formula_2 {
    my $self    = shift;
    my $formula = shift;
    $formula =~ s/^=//;
    $self->xml_data_element( 'formula2', $formula );
}
sub _write_conditional_formats {
    my $self   = shift;
    my @ranges = sort keys %{ $self->{_cond_formats} };
    return unless scalar @ranges;
    for my $range ( @ranges ) {
        $self->_write_conditional_formatting( $range,
            $self->{_cond_formats}->{$range} );
    }
}
sub _write_conditional_formatting {
    my $self   = shift;
    my $range  = shift;
    my $params = shift;
    my @attributes = ( 'sqref' => $range );
    $self->xml_start_tag( 'conditionalFormatting', @attributes );
    for my $param ( @$params ) {
        $self->_write_cf_rule( $param );
    }
    $self->xml_end_tag( 'conditionalFormatting' );
}
sub _write_cf_rule {
    my $self  = shift;
    my $param = shift;
    my @attributes = ( 'type' => $param->{type} );
    push @attributes, ( 'dxfId' => $param->{format} )
      if defined $param->{format};
    push @attributes, ( 'priority' => $param->{priority} );
    push @attributes, ( 'stopIfTrue' => 1 )
      if $param->{stop_if_true};
    if ( $param->{type} eq 'cellIs' ) {
        push @attributes, ( 'operator' => $param->{criteria} );
        $self->xml_start_tag( 'cfRule', @attributes );
        if ( defined $param->{minimum} && defined $param->{maximum} ) {
            $self->_write_formula( $param->{minimum} );
            $self->_write_formula( $param->{maximum} );
        }
        else {
            my $value = $param->{value};
            if (   $value !~ /(\$?)([A-Z]{1,3})(\$?)(\d+)/
                && $value !~
                /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ )
            {
                if ( $value !~ /^".*"$/ ) {
                    $value = qq("$value");
                }
            }
            $self->_write_formula( $value );
        }
        $self->xml_end_tag( 'cfRule' );
    }
    elsif ( $param->{type} eq 'aboveAverage' ) {
        if ( $param->{criteria} =~ /below/ ) {
            push @attributes, ( 'aboveAverage' => 0 );
        }
        if ( $param->{criteria} =~ /equal/ ) {
            push @attributes, ( 'equalAverage' => 1 );
        }
        if ( $param->{criteria} =~ /([123]) std dev/ ) {
            push @attributes, ( 'stdDev' => $1 );
        }
        $self->xml_empty_tag( 'cfRule', @attributes );
    }
    elsif ( $param->{type} eq 'top10' ) {
        if ( defined $param->{criteria} && $param->{criteria} eq '%' ) {
            push @attributes, ( 'percent' => 1 );
        }
        if ( $param->{direction} ) {
            push @attributes, ( 'bottom' => 1 );
        }
        my $rank = $param->{value} || 10;
        push @attributes, ( 'rank' => $rank );
        $self->xml_empty_tag( 'cfRule', @attributes );
    }
    elsif ( $param->{type} eq 'duplicateValues' ) {
        $self->xml_empty_tag( 'cfRule', @attributes );
    }
    elsif ( $param->{type} eq 'uniqueValues' ) {
        $self->xml_empty_tag( 'cfRule', @attributes );
    }
    elsif ($param->{type} eq 'containsText'
        || $param->{type} eq 'notContainsText'
        || $param->{type} eq 'beginsWith'
        || $param->{type} eq 'endsWith' )
    {
        push @attributes, ( 'operator' => $param->{criteria} );
        push @attributes, ( 'text'     => $param->{value} );
        $self->xml_start_tag( 'cfRule', @attributes );
        $self->_write_formula( $param->{formula} );
        $self->xml_end_tag( 'cfRule' );
    }
    elsif ( $param->{type} eq 'timePeriod' ) {
        push @attributes, ( 'timePeriod' => $param->{criteria} );
        $self->xml_start_tag( 'cfRule', @attributes );
        $self->_write_formula( $param->{formula} );
        $self->xml_end_tag( 'cfRule' );
    }
    elsif ($param->{type} eq 'containsBlanks'
        || $param->{type} eq 'notContainsBlanks'
        || $param->{type} eq 'containsErrors'
        || $param->{type} eq 'notContainsErrors' )
    {
        $self->xml_start_tag( 'cfRule', @attributes );
        $self->_write_formula( $param->{formula} );
        $self->xml_end_tag( 'cfRule' );
    }
    elsif ( $param->{type} eq 'colorScale' ) {
        $self->xml_start_tag( 'cfRule', @attributes );
        $self->_write_color_scale( $param );
        $self->xml_end_tag( 'cfRule' );
    }
    elsif ( $param->{type} eq 'dataBar' ) {
        $self->xml_start_tag( 'cfRule', @attributes );
        $self->_write_data_bar( $param );
        if ($param->{_is_data_bar_2010}) {
            $self->_write_data_bar_ext( $param );
        }
        $self->xml_end_tag( 'cfRule' );
    }
    elsif ( $param->{type} eq 'expression' ) {
        $self->xml_start_tag( 'cfRule', @attributes );
        $self->_write_formula( $param->{criteria} );
        $self->xml_end_tag( 'cfRule' );
    }
    elsif ( $param->{type} eq 'iconSet' ) {
        $self->xml_start_tag( 'cfRule', @attributes );
        $self->_write_icon_set( $param );
        $self->xml_end_tag( 'cfRule' );
    }
}
sub _write_icon_set {
    my $self        = shift;
    my $param       = shift;
    my $icon_style  = $param->{icon_style};
    my $total_icons = $param->{total_icons};
    my $icons       = $param->{icons};
    my $i;
    my @attributes = ();
    if ( $icon_style ne '3TrafficLights' ) {
        @attributes = ( 'iconSet' => $icon_style );
    }
    if ( exists $param->{'icons_only'} && $param->{'icons_only'} ) {
        push @attributes, ( 'showValue' => 0 );
    }
    if ( exists $param->{'reverse_icons'} && $param->{'reverse_icons'} ) {
        push @attributes, ( 'reverse' => 1 );
    }
    $self->xml_start_tag( 'iconSet', @attributes );
    for my $icon ( reverse @{ $param->{icons} } ) {
        $self->_write_cfvo(
            $icon->{'type'},
            $icon->{'value'},
            $icon->{'criteria'}
        );
    }
    $self->xml_end_tag( 'iconSet' );
}
sub _write_formula {
    my $self = shift;
    my $data = shift;
    $data =~ s/^=//;
    $self->xml_data_element( 'formula', $data );
}
sub _write_color_scale {
    my $self  = shift;
    my $param = shift;
    $self->xml_start_tag( 'colorScale' );
    $self->_write_cfvo( $param->{min_type}, $param->{min_value} );
    if ( defined $param->{mid_type} ) {
        $self->_write_cfvo( $param->{mid_type}, $param->{mid_value} );
    }
    $self->_write_cfvo( $param->{max_type}, $param->{max_value} );
    $self->_write_color( 'rgb' => $param->{min_color} );
    if ( defined $param->{mid_color} ) {
        $self->_write_color( 'rgb' => $param->{mid_color} );
    }
    $self->_write_color( 'rgb' => $param->{max_color} );
    $self->xml_end_tag( 'colorScale' );
}
sub _write_data_bar {
    my $self       = shift;
    my $data_bar   = shift;
    my @attributes = ();
    if ( $data_bar->{bar_only} ) {
        push @attributes, ( 'showValue', 0 );
    }
    $self->xml_start_tag( 'dataBar', @attributes );
    $self->_write_cfvo( $data_bar->{min_type}, $data_bar->{min_value} );
    $self->_write_cfvo( $data_bar->{max_type}, $data_bar->{max_value} );
    $self->_write_color( 'rgb' => $data_bar->{bar_color} );
    $self->xml_end_tag( 'dataBar' );
}
sub _write_data_bar_ext {
    my $self      = shift;
    my $param     = shift;
    my $worksheet_count = $self->{_index} + 1;
    my $data_bar_count  = @{ $self->{_data_bars_2010} } + 1;
    my $guid = sprintf "{DA7ABA51-AAAA-BBBB-%04X-%012X}", $worksheet_count,
      $data_bar_count;
    $param->{_guid} = $guid;
    push @{$self->{_data_bars_2010}}, $param;
    $self->xml_start_tag( 'extLst' );
    $self->_write_ext('{B025F937-C7B1-47D3-B67F-A62EFF666E3E}');
    $self->xml_data_element( 'x14:id', $guid);
    $self->xml_end_tag( 'ext' );
    $self->xml_end_tag( 'extLst' );
}
sub _write_cfvo {
    my $self     = shift;
    my $type     = shift;
    my $value    = shift;
    my $criteria = shift;
    my @attributes = ( 'type' => $type );
    if ( defined $value ) {
        push @attributes, ( 'val', $value );
    }
    if ( $criteria ) {
        push @attributes, ( 'gte', 0 );
    }
    $self->xml_empty_tag( 'cfvo', @attributes );
}
sub _write_x14_cfvo {
    my $self  = shift;
    my $type  = shift;
    my $value = shift;
    my @attributes = ( 'type' => $type );
    if (   $type eq 'min'
        || $type eq 'max'
        || $type eq 'autoMin'
        || $type eq 'autoMax' )
    {
        $self->xml_empty_tag( 'x14:cfvo', @attributes );
    }
    else {
        $self->xml_start_tag( 'x14:cfvo', @attributes );
        $self->xml_data_element( 'xm:f', $value );
        $self->xml_end_tag( 'x14:cfvo' );
    }
}
sub _write_color {
    my $self  = shift;
    my $name  = shift;
    my $value = shift;
    my @attributes = ( $name => $value );
    $self->xml_empty_tag( 'color', @attributes );
}
sub _write_table_parts {
    my $self   = shift;
    my @tables = @{ $self->{_tables} };
    my $count  = scalar @tables;
    return unless $count;
    my @attributes = ( 'count' => $count, );
    $self->xml_start_tag( 'tableParts', @attributes );
    for my $table ( @tables ) {
        $self->_write_table_part( ++$self->{_rel_count} );
    }
    $self->xml_end_tag( 'tableParts' );
}
sub _write_table_part {
    my $self = shift;
    my $id   = shift;
    my $r_id = 'rId' . $id;
    my @attributes = ( 'r:id' => $r_id, );
    $self->xml_empty_tag( 'tablePart', @attributes );
}
sub _write_ext_list {
    my $self            = shift;
    my $has_data_bars  = scalar @{ $self->{_data_bars_2010} };
    my $has_sparklines = scalar @{ $self->{_sparklines} };
    if ( !$has_data_bars and !$has_sparklines ) {
        return;
    }
    $self->xml_start_tag( 'extLst' );
    if ( $has_data_bars ) {
        $self->_write_ext_list_data_bars();
    }
    if ( $has_sparklines ) {
        $self->_write_ext_list_sparklines();
    }
    $self->xml_end_tag( 'extLst' );
}
sub _write_ext_list_data_bars {
    my $self      = shift;
    my @data_bars = @{ $self->{_data_bars_2010} };
    $self->_write_ext('{78C0D931-6437-407d-A8EE-F0AAD7539E65}');
    $self->xml_start_tag( 'x14:conditionalFormattings' );
    for my $data_bar (@data_bars) {
        $self->_write_conditional_formatting_2010($data_bar);
    }
    $self->xml_end_tag( 'x14:conditionalFormattings' );
    $self->xml_end_tag( 'ext' );
}
sub _write_conditional_formatting_2010 {
    my $self     = shift;
    my $data_bar = shift;
    my $xmlns_xm = 'http://schemas.microsoft.com/office/excel/2006/main';
    my @attributes = ( 'xmlns:xm' => $xmlns_xm );
    $self->xml_start_tag( 'x14:conditionalFormatting', @attributes );
    $self->_write_x14_cf_rule( $data_bar );
    $self->_write_x14_data_bar( $data_bar );
    $self->_write_x14_cfvo( $data_bar->{_x14_min_type},
        $data_bar->{min_value} );
    $self->_write_x14_cfvo( $data_bar->{_x14_max_type},
        $data_bar->{max_value} );
    if ( !$data_bar->{bar_no_border} ) {
        $self->_write_x14_border_color( $data_bar->{bar_border_color} );
    }
    if ( !$data_bar->{bar_negative_color_same} ) {
        $self->_write_x14_negative_fill_color(
            $data_bar->{bar_negative_color} );
    }
    if (   !$data_bar->{bar_no_border}
        && !$data_bar->{bar_negative_border_color_same} )
    {
        $self->_write_x14_negative_border_color(
            $data_bar->{bar_negative_border_color} );
    }
    if ( $data_bar->{bar_axis_position} ne 'none') {
        $self->_write_x14_axis_color($data_bar->{bar_axis_color});
    }
    $self->xml_end_tag( 'x14:dataBar' );
    $self->xml_end_tag( 'x14:cfRule' );
    $self->xml_data_element( 'xm:sqref', $data_bar->{_range} );
    $self->xml_end_tag( 'x14:conditionalFormatting' );
}
sub _write_x14_cf_rule {
    my $self     = shift;
    my $data_bar = shift;
    my $type     = 'dataBar';
    my $id       = $data_bar->{_guid};
    my @attributes = (
        'type' => $type,
        'id'   => $id,
    );
    $self->xml_start_tag( 'x14:cfRule', @attributes );
}
sub _write_x14_data_bar {
    my $self          = shift;
    my $data_bar      = shift;
    my $min_length    = 0;
    my $max_length    = 100;
    my @attributes = (
        'minLength' => $min_length,
        'maxLength' => $max_length,
    );
    if ( !$data_bar->{bar_no_border} ) {
        push @attributes, ( 'border', 1 );
    }
    if ( $data_bar->{bar_solid} ) {
        push @attributes, ( 'gradient', 0 );
    }
    if ( $data_bar->{bar_direction} eq 'left' ) {
        push @attributes, ( 'direction', 'leftToRight' );
    }
    if ( $data_bar->{bar_direction} eq 'right' ) {
        push @attributes, ( 'direction', 'rightToLeft' );
    }
    if ( $data_bar->{bar_negative_color_same} ) {
        push @attributes, ( 'negativeBarColorSameAsPositive', 1 );
    }
    if (   !$data_bar->{bar_no_border}
        && !$data_bar->{bar_negative_border_color_same} )
    {
        push @attributes, ( 'negativeBarBorderColorSameAsPositive', 0 );
    }
    if ( $data_bar->{bar_axis_position} eq 'middle') {
        push @attributes, ( 'axisPosition', 'middle' );
    }
    if ( $data_bar->{bar_axis_position} eq 'none') {
        push @attributes, ( 'axisPosition', 'none' );
    }
    $self->xml_start_tag( 'x14:dataBar', @attributes );
}
sub _write_x14_border_color {
    my $self = shift;
    my $rgb  = shift;
    my @attributes = ( 'rgb' => $rgb );
    $self->xml_empty_tag( 'x14:borderColor', @attributes );
}
sub _write_x14_negative_fill_color {
    my $self = shift;
    my $rgb  = shift;
    my @attributes = ( 'rgb' => $rgb );
    $self->xml_empty_tag( 'x14:negativeFillColor', @attributes );
}
sub _write_x14_negative_border_color {
    my $self = shift;
    my $rgb  = shift;
    my @attributes = ( 'rgb' => $rgb );
    $self->xml_empty_tag( 'x14:negativeBorderColor', @attributes );
}
sub _write_x14_axis_color {
    my $self = shift;
    my $rgb  = shift;
    my @attributes = ( 'rgb' => $rgb );
    $self->xml_empty_tag( 'x14:axisColor', @attributes );
}
sub _write_ext_list_sparklines {
    my $self       = shift;
    my @sparklines = @{ $self->{_sparklines} };
    my $count      = scalar @sparklines;
    $self->_write_ext('{05C60535-1F16-4fd2-B633-F4F36F0B64E0}');
    $self->_write_sparkline_groups();
    for my $sparkline ( reverse @sparklines ) {
        $self->_write_sparkline_group( $sparkline );
        $self->_write_color_series( $sparkline->{_series_color} );
        $self->_write_color_negative( $sparkline->{_negative_color} );
        $self->_write_color_axis();
        $self->_write_color_markers( $sparkline->{_markers_color} );
        $self->_write_color_first( $sparkline->{_first_color} );
        $self->_write_color_last( $sparkline->{_last_color} );
        $self->_write_color_high( $sparkline->{_high_color} );
        $self->_write_color_low( $sparkline->{_low_color} );
        if ( $sparkline->{_date_axis} ) {
            $self->xml_data_element( 'xm:f', $sparkline->{_date_axis} );
        }
        $self->_write_sparklines( $sparkline );
        $self->xml_end_tag( 'x14:sparklineGroup' );
    }
    $self->xml_end_tag( 'x14:sparklineGroups' );
    $self->xml_end_tag( 'ext' );
}
sub _write_sparklines {
    my $self      = shift;
    my $sparkline = shift;
    $self->xml_start_tag( 'x14:sparklines' );
    for my $i ( 0 .. $sparkline->{_count} - 1 ) {
        my $range    = $sparkline->{_ranges}->[$i];
        my $location = $sparkline->{_locations}->[$i];
        $self->xml_start_tag( 'x14:sparkline' );
        $self->xml_data_element( 'xm:f',     $range );
        $self->xml_data_element( 'xm:sqref', $location );
        $self->xml_end_tag( 'x14:sparkline' );
    }
    $self->xml_end_tag( 'x14:sparklines' );
}
sub _write_ext {
    my $self      = shift;
    my $uri       = shift;
    my $schema    = 'http://schemas.microsoft.com/office/';
    my $xmlns_x14 = $schema . 'spreadsheetml/2009/9/main';
    my @attributes = (
        'xmlns:x14' => $xmlns_x14,
        'uri'       => $uri,
    );
    $self->xml_start_tag( 'ext', @attributes );
}
sub _write_sparkline_groups {
    my $self     = shift;
    my $xmlns_xm = 'http://schemas.microsoft.com/office/excel/2006/main';
    my @attributes = ( 'xmlns:xm' => $xmlns_xm );
    $self->xml_start_tag( 'x14:sparklineGroups', @attributes );
}
sub _write_sparkline_group {
    my $self     = shift;
    my $opts     = shift;
    my $empty    = $opts->{_empty};
    my $user_max = 0;
    my $user_min = 0;
    my @a;
    if ( defined $opts->{_max} ) {
        if ( $opts->{_max} eq 'group' ) {
            $opts->{_cust_max} = 'group';
        }
        else {
            push @a, ( 'manualMax' => $opts->{_max} );
            $opts->{_cust_max} = 'custom';
        }
    }
    if ( defined $opts->{_min} ) {
        if ( $opts->{_min} eq 'group' ) {
            $opts->{_cust_min} = 'group';
        }
        else {
            push @a, ( 'manualMin' => $opts->{_min} );
            $opts->{_cust_min} = 'custom';
        }
    }
    if ( $opts->{_type} ne 'line' ) {
        push @a, ( 'type' => $opts->{_type} );
    }
    push @a, ( 'lineWeight' => $opts->{_weight} ) if $opts->{_weight};
    push @a, ( 'dateAxis' => 1 ) if $opts->{_date_axis};
    push @a, ( 'displayEmptyCellsAs' => $empty ) if $empty;
    push @a, ( 'markers'       => 1 )                  if $opts->{_markers};
    push @a, ( 'high'          => 1 )                  if $opts->{_high};
    push @a, ( 'low'           => 1 )                  if $opts->{_low};
    push @a, ( 'first'         => 1 )                  if $opts->{_first};
    push @a, ( 'last'          => 1 )                  if $opts->{_last};
    push @a, ( 'negative'      => 1 )                  if $opts->{_negative};
    push @a, ( 'displayXAxis'  => 1 )                  if $opts->{_axis};
    push @a, ( 'displayHidden' => 1 )                  if $opts->{_hidden};
    push @a, ( 'minAxisType'   => $opts->{_cust_min} ) if $opts->{_cust_min};
    push @a, ( 'maxAxisType'   => $opts->{_cust_max} ) if $opts->{_cust_max};
    push @a, ( 'rightToLeft'   => 1 )                  if $opts->{_reverse};
    $self->xml_start_tag( 'x14:sparklineGroup', @a );
}
sub _write_spark_color {
    my $self    = shift;
    my $element = shift;
    my $color   = shift;
    my @attr;
    push @attr, ( 'rgb'   => $color->{_rgb} )   if defined $color->{_rgb};
    push @attr, ( 'theme' => $color->{_theme} ) if defined $color->{_theme};
    push @attr, ( 'tint'  => $color->{_tint} )  if defined $color->{_tint};
    $self->xml_empty_tag( $element, @attr );
}
sub _write_color_series {
    my $self = shift;
    $self->_write_spark_color( 'x14:colorSeries', @_ );
}
sub _write_color_negative {
    my $self = shift;
    $self->_write_spark_color( 'x14:colorNegative', @_ );
}
sub _write_color_axis {
    my $self = shift;
    $self->_write_spark_color( 'x14:colorAxis', { _rgb => 'FF000000' } );
}
sub _write_color_markers {
    my $self = shift;
    $self->_write_spark_color( 'x14:colorMarkers', @_ );
}
sub _write_color_first {
    my $self = shift;
    $self->_write_spark_color( 'x14:colorFirst', @_ );
}
sub _write_color_last {
    my $self = shift;
    $self->_write_spark_color( 'x14:colorLast', @_ );
}
sub _write_color_high {
    my $self = shift;
    $self->_write_spark_color( 'x14:colorHigh', @_ );
}
sub _write_color_low {
    my $self = shift;
    $self->_write_spark_color( 'x14:colorLow', @_ );
}
1;
