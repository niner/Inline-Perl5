package Excel::Writer::XLSX::Package::VML;
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
    bless $self, $class;
    return $self;
}
sub _assemble_xml_file {
    my $self               = shift;
    my $data_id            = shift;
    my $vml_shape_id       = shift;
    my $comments_data      = shift;
    my $buttons_data       = shift;
    my $header_images_data = shift;
    my $z_index            = 1;
    $self->_write_xml_namespace;
    $self->_write_shapelayout( $data_id );
    if ( defined $buttons_data && @$buttons_data ) {
        $self->_write_button_shapetype();
        for my $button ( @$buttons_data ) {
            $self->_write_button_shape( ++$vml_shape_id, $z_index++, $button );
        }
    }
    if ( defined $comments_data && @$comments_data ) {
        $self->_write_comment_shapetype();
        for my $comment ( @$comments_data ) {
            $self->_write_comment_shape( ++$vml_shape_id, $z_index++,
                $comment );
        }
    }
    if ( defined $header_images_data && @$header_images_data ) {
        $self->_write_image_shapetype();
        my $index = 1;
        for my $image ( @$header_images_data ) {
            $self->_write_image_shape( ++$vml_shape_id, $index++, $image );
        }
    }
    $self->xml_end_tag( 'xml' );
    $self->xml_get_fh()->close();
}
sub _pixels_to_points {
    my $self     = shift;
    my $vertices = shift;
    my (
        $col_start, $row_start, $x1,    $y1,
        $col_end,   $row_end,   $x2,    $y2,
        $left,      $top,       $width, $height
    ) = @$vertices;
    for my $pixels ( $left, $top, $width, $height ) {
        $pixels *= 0.75;
    }
    return ( $left, $top, $width, $height );
}
sub _write_xml_namespace {
    my $self    = shift;
    my $schema  = 'urn:schemas-microsoft-com:';
    my $xmlns   = $schema . 'vml';
    my $xmlns_o = $schema . 'office:office';
    my $xmlns_x = $schema . 'office:excel';
    my @attributes = (
        'xmlns:v' => $xmlns,
        'xmlns:o' => $xmlns_o,
        'xmlns:x' => $xmlns_x,
    );
    $self->xml_start_tag( 'xml', @attributes );
}
sub _write_shapelayout {
    my $self    = shift;
    my $data_id = shift;
    my $ext     = 'edit';
    my @attributes = ( 'v:ext' => $ext );
    $self->xml_start_tag( 'o:shapelayout', @attributes );
    $self->_write_idmap( $data_id );
    $self->xml_end_tag( 'o:shapelayout' );
}
sub _write_idmap {
    my $self    = shift;
    my $ext     = 'edit';
    my $data_id = shift;
    my @attributes = (
        'v:ext' => $ext,
        'data'  => $data_id,
    );
    $self->xml_empty_tag( 'o:idmap', @attributes );
}
sub _write_comment_shapetype {
    my $self      = shift;
    my $id        = '_x0000_t202';
    my $coordsize = '21600,21600';
    my $spt       = 202;
    my $path      = 'm,l,21600r21600,l21600,xe';
    my @attributes = (
        'id'        => $id,
        'coordsize' => $coordsize,
        'o:spt'     => $spt,
        'path'      => $path,
    );
    $self->xml_start_tag( 'v:shapetype', @attributes );
    $self->_write_stroke();
    $self->_write_comment_path( 't', 'rect' );
    $self->xml_end_tag( 'v:shapetype' );
}
sub _write_button_shapetype {
    my $self      = shift;
    my $id        = '_x0000_t201';
    my $coordsize = '21600,21600';
    my $spt       = 201;
    my $path      = 'm,l,21600r21600,l21600,xe';
    my @attributes = (
        'id'        => $id,
        'coordsize' => $coordsize,
        'o:spt'     => $spt,
        'path'      => $path,
    );
    $self->xml_start_tag( 'v:shapetype', @attributes );
    $self->_write_stroke();
    $self->_write_button_path( 't', 'rect' );
    $self->_write_shapetype_lock();
    $self->xml_end_tag( 'v:shapetype' );
}
sub _write_image_shapetype {
    my $self             = shift;
    my $id               = '_x0000_t75';
    my $coordsize        = '21600,21600';
    my $spt              = 75;
    my $o_preferrelative = 't';
    my $path             = 'm@4@5l@4@11@9@11@9@5xe';
    my $filled           = 'f';
    my $stroked          = 'f';
    my @attributes = (
        'id'               => $id,
        'coordsize'        => $coordsize,
        'o:spt'            => $spt,
        'o:preferrelative' => $o_preferrelative,
        'path'             => $path,
        'filled'           => $filled,
        'stroked'          => $stroked,
    );
    $self->xml_start_tag( 'v:shapetype', @attributes );
    $self->_write_stroke();
    $self->_write_formulas();
    $self->_write_image_path();
    $self->_write_aspect_ratio_lock();
    $self->xml_end_tag( 'v:shapetype' );
}
sub _write_stroke {
    my $self      = shift;
    my $joinstyle = 'miter';
    my @attributes = ( 'joinstyle' => $joinstyle );
    $self->xml_empty_tag( 'v:stroke', @attributes );
}
sub _write_comment_path {
    my $self            = shift;
    my $gradientshapeok = shift;
    my $connecttype     = shift;
    my @attributes      = ();
    push @attributes, ( 'gradientshapeok' => 't' ) if $gradientshapeok;
    push @attributes, ( 'o:connecttype' => $connecttype );
    $self->xml_empty_tag( 'v:path', @attributes );
}
sub _write_button_path {
    my $self        = shift;
    my $shadowok    = 'f';
    my $extrusionok = 'f';
    my $strokeok    = 'f';
    my $fillok      = 'f';
    my $connecttype = 'rect';
    my @attributes = (
        'shadowok'      => $shadowok,
        'o:extrusionok' => $extrusionok,
        'strokeok'      => $strokeok,
        'fillok'        => $fillok,
        'o:connecttype' => $connecttype,
    );
    $self->xml_empty_tag( 'v:path', @attributes );
}
sub _write_image_path {
    my $self            = shift;
    my $extrusionok     = 'f';
    my $gradientshapeok = 't';
    my $connecttype     = 'rect';
    my @attributes = (
        'o:extrusionok'   => $extrusionok,
        'gradientshapeok' => $gradientshapeok,
        'o:connecttype'   => $connecttype,
    );
    $self->xml_empty_tag( 'v:path', @attributes );
}
sub _write_shapetype_lock {
    my $self      = shift;
    my $ext       = 'edit';
    my $shapetype = 't';
    my @attributes = (
        'v:ext'     => $ext,
        'shapetype' => $shapetype,
    );
    $self->xml_empty_tag( 'o:lock', @attributes );
}
sub _write_rotation_lock {
    my $self     = shift;
    my $ext      = 'edit';
    my $rotation = 't';
    my @attributes = (
        'v:ext'    => $ext,
        'rotation' => $rotation,
    );
    $self->xml_empty_tag( 'o:lock', @attributes );
}
sub _write_aspect_ratio_lock {
    my $self        = shift;
    my $ext         = 'edit';
    my $aspectratio = 't';
    my @attributes = (
        'v:ext'       => $ext,
        'aspectratio' => $aspectratio,
    );
    $self->xml_empty_tag( 'o:lock', @attributes );
}
sub _write_comment_shape {
    my $self       = shift;
    my $id         = shift;
    my $z_index    = shift;
    my $comment    = shift;
    my $type       = '#_x0000_t202';
    my $insetmode  = 'auto';
    my $visibility = 'hidden';
    $id = '_x0000_s' . $id;
    my $row       = $comment->[0];
    my $col       = $comment->[1];
    my $string    = $comment->[2];
    my $author    = $comment->[3];
    my $visible   = $comment->[4];
    my $fillcolor = $comment->[5];
    my $vertices  = $comment->[9];
    my ( $left, $top, $width, $height ) = $self->_pixels_to_points( $vertices );
    $visibility = 'visible' if $visible;
    my $style =
        'position:absolute;'
      . 'margin-left:'
      . $left . 'pt;'
      . 'margin-top:'
      . $top . 'pt;'
      . 'width:'
      . $width . 'pt;'
      . 'height:'
      . $height . 'pt;'
      . 'z-index:'
      . $z_index . ';'
      . 'visibility:'
      . $visibility;
    my @attributes = (
        'id'          => $id,
        'type'        => $type,
        'style'       => $style,
        'fillcolor'   => $fillcolor,
        'o:insetmode' => $insetmode,
    );
    $self->xml_start_tag( 'v:shape', @attributes );
    $self->_write_comment_fill();
    $self->_write_shadow();
    $self->_write_comment_path( undef, 'none' );
    $self->_write_comment_textbox();
    $self->_write_comment_client_data( $row, $col, $visible, $vertices );
    $self->xml_end_tag( 'v:shape' );
}
sub _write_button_shape {
    my $self       = shift;
    my $id         = shift;
    my $z_index    = shift;
    my $button     = shift;
    my $type       = '#_x0000_t201';
    $id = '_x0000_s' . $id;
    my $row       = $button->{_row};
    my $col       = $button->{_col};
    my $vertices  = $button->{_vertices};
    my ( $left, $top, $width, $height ) = $self->_pixels_to_points( $vertices );
    my $style =
        'position:absolute;'
      . 'margin-left:'
      . $left . 'pt;'
      . 'margin-top:'
      . $top . 'pt;'
      . 'width:'
      . $width . 'pt;'
      . 'height:'
      . $height . 'pt;'
      . 'z-index:'
      . $z_index . ';'
      . 'mso-wrap-style:tight';
    my @attributes = (
        'id'          => $id,
        'type'        => $type,
        'style'       => $style,
        'o:button'    => 't',
        'fillcolor'   => 'buttonFace [67]',
        'strokecolor' => 'windowText [64]',
        'o:insetmode' => 'auto',
    );
    $self->xml_start_tag( 'v:shape', @attributes );
    $self->_write_button_fill();
    $self->_write_rotation_lock();
    $self->_write_button_textbox( $button->{_font} );
    $self->_write_button_client_data( $button );
    $self->xml_end_tag( 'v:shape' );
}
sub _write_image_shape {
    my $self       = shift;
    my $id         = shift;
    my $index      = shift;
    my $image_data = shift;
    my $type       = '#_x0000_t75';
    $id = '_x0000_s' . $id;
    my $width    = $image_data->[0];
    my $height   = $image_data->[1];
    my $name     = $image_data->[2];
    my $position = $image_data->[3];
    my $x_dpi    = $image_data->[4];
    my $y_dpi    = $image_data->[5];
    my $ref_id   = $image_data->[6];
    $width  = $width  * 72 / $x_dpi;
    $height = $height * 72 / $y_dpi;
    $width  = 72/96 * int($width  * 96/72 + 0.25);
    $height = 72/96 * int($height * 96/72 + 0.25);
    my $style =
        'position:absolute;'
      . 'margin-left:0;'
      . 'margin-top:0;'
      . 'width:'
      . $width . 'pt;'
      . 'height:'
      . $height . 'pt;'
      . 'z-index:'
      . $index;
    my @attributes = (
        'id'     => $position,
        'o:spid' => $id,
        'type'   => $type,
        'style'  => $style,
    );
    $self->xml_start_tag( 'v:shape', @attributes );
    $self->_write_imagedata( $ref_id, $name );
    $self->_write_rotation_lock();
    $self->xml_end_tag( 'v:shape' );
}
sub _write_comment_fill {
    my $self    = shift;
    my $color_2 = '#ffffe1';
    my @attributes = ( 'color2' => $color_2 );
    $self->xml_empty_tag( 'v:fill', @attributes );
}
sub _write_button_fill {
    my $self             = shift;
    my $color_2          = 'buttonFace [67]';
    my $detectmouseclick = 't';
    my @attributes = (
        'color2'             => $color_2,
        'o:detectmouseclick' => $detectmouseclick,
    );
    $self->xml_empty_tag( 'v:fill', @attributes );
}
sub _write_shadow {
    my $self     = shift;
    my $on       = 't';
    my $color    = 'black';
    my $obscured = 't';
    my @attributes = (
        'on'       => $on,
        'color'    => $color,
        'obscured' => $obscured,
    );
    $self->xml_empty_tag( 'v:shadow', @attributes );
}
sub _write_comment_textbox {
    my $self  = shift;
    my $style = 'mso-direction-alt:auto';
    my @attributes = ( 'style' => $style );
    $self->xml_start_tag( 'v:textbox', @attributes );
    $self->_write_div( 'left' );
    $self->xml_end_tag( 'v:textbox' );
}
sub _write_button_textbox {
    my $self  = shift;
    my $font  = shift;
    my $style = 'mso-direction-alt:auto';
    my @attributes = ( 'style' => $style, 'o:singleclick' => 'f' );
    $self->xml_start_tag( 'v:textbox', @attributes );
    $self->_write_div( 'center', $font );
    $self->xml_end_tag( 'v:textbox' );
}
sub _write_div {
    my $self  = shift;
    my $align = shift;
    my $font  = shift;
    my $style = 'text-align:' . $align;
    my @attributes = ( 'style' => $style );
    $self->xml_start_tag( 'div', @attributes );
    if ( $font ) {
        $self->_write_font( $font );
    }
    $self->xml_end_tag( 'div' );
}
sub _write_font {
    my $self    = shift;
    my $font    = shift;
    my $caption = $font->{_caption};
    my $face    = 'Calibri';
    my $size    = 220;
    my $color   = '#000000';
    my @attributes = (
        'face'  => $face,
        'size'  => $size,
        'color' => $color,
    );
    $self->xml_data_element( 'font', $caption, @attributes );
}
sub _write_comment_client_data {
    my $self        = shift;
    my $row         = shift;
    my $col         = shift;
    my $visible     = shift;
    my $vertices    = shift;
    my $object_type = 'Note';
    my @attributes = ( 'ObjectType' => $object_type );
    $self->xml_start_tag( 'x:ClientData', @attributes );
    $self->_write_move_with_cells();
    $self->_write_size_with_cells();
    $self->_write_anchor( $vertices );
    $self->_write_auto_fill();
    $self->_write_row( $row );
    $self->_write_column( $col );
    $self->_write_visible() if $visible;
    $self->xml_end_tag( 'x:ClientData' );
}
sub _write_button_client_data {
    my $self      = shift;
    my $button    = shift;
    my $row       = $button->{_row};
    my $col       = $button->{_col};
    my $macro     = $button->{_macro};
    my $vertices  = $button->{_vertices};
    my $object_type = 'Button';
    my @attributes = ( 'ObjectType' => $object_type );
    $self->xml_start_tag( 'x:ClientData', @attributes );
    $self->_write_anchor( $vertices );
    $self->_write_print_object();
    $self->_write_auto_fill();
    $self->_write_fmla_macro( $macro );
    $self->_write_text_halign();
    $self->_write_text_valign();
    $self->xml_end_tag( 'x:ClientData' );
}
sub _write_move_with_cells {
    my $self = shift;
    $self->xml_empty_tag( 'x:MoveWithCells' );
}
sub _write_size_with_cells {
    my $self = shift;
    $self->xml_empty_tag( 'x:SizeWithCells' );
}
sub _write_visible {
    my $self = shift;
    $self->xml_empty_tag( 'x:Visible' );
}
sub _write_anchor {
    my $self     = shift;
    my $vertices = shift;
    my ( $col_start, $row_start, $x1, $y1, $col_end, $row_end, $x2, $y2 ) =
      @$vertices;
    my $data = join ", ",
      ( $col_start, $x1, $row_start, $y1, $col_end, $x2, $row_end, $y2 );
    $self->xml_data_element( 'x:Anchor', $data );
}
sub _write_auto_fill {
    my $self = shift;
    my $data = 'False';
    $self->xml_data_element( 'x:AutoFill', $data );
}
sub _write_row {
    my $self = shift;
    my $data = shift;
    $self->xml_data_element( 'x:Row', $data );
}
sub _write_column {
    my $self = shift;
    my $data = shift;
    $self->xml_data_element( 'x:Column', $data );
}
sub _write_print_object {
    my $self = shift;
    my $data = 'False';
    $self->xml_data_element( 'x:PrintObject', $data );
}
sub _write_text_halign {
    my $self = shift;
    my $data = 'Center';
    $self->xml_data_element( 'x:TextHAlign', $data );
}
sub _write_text_valign {
    my $self = shift;
    my $data = 'Center';
    $self->xml_data_element( 'x:TextVAlign', $data );
}
sub _write_fmla_macro {
    my $self = shift;
    my $data = shift;
    $self->xml_data_element( 'x:FmlaMacro', $data );
}
sub _write_imagedata {
    my $self    = shift;
    my $index   = shift;
    my $o_title = shift;
    my @attributes = (
        'o:relid' => 'rId' . $index,
        'o:title' => $o_title,
    );
    $self->xml_empty_tag( 'v:imagedata', @attributes );
}
sub _write_formulas {
    my $self                 = shift;
    $self->xml_start_tag( 'v:formulas' );
    $self->_write_f('if lineDrawn pixelLineWidth 0');
    $self->_write_f('sum @0 1 0');
    $self->_write_f('sum 0 0 @1');
    $self->_write_f('prod @2 1 2');
    $self->_write_f('prod @3 21600 pixelWidth');
    $self->_write_f('prod @3 21600 pixelHeight');
    $self->_write_f('sum @0 0 1');
    $self->_write_f('prod @6 1 2');
    $self->_write_f('prod @7 21600 pixelWidth');
    $self->_write_f('sum @8 21600 0');
    $self->_write_f('prod @7 21600 pixelHeight');
    $self->_write_f('sum @10 21600 0');
    $self->xml_end_tag( 'v:formulas' );
}
sub _write_f {
    my $self = shift;
    my $eqn  = shift;
    my @attributes = ( 'eqn' => $eqn );
    $self->xml_empty_tag( 'v:f', @attributes );
}
1;
