package Excel::Writer::XLSX::Workbook;
use 5.008002;
use strict;
use warnings;
use Carp;
use IO::File;
use File::Find;
use File::Temp qw(tempfile);
use File::Basename 'fileparse';
#use Archive::Zip;
use Digest::MD5 qw(md5_hex);
use Excel::Writer::XLSX::Worksheet;
use Excel::Writer::XLSX::Chartsheet;
use Excel::Writer::XLSX::Format;
use Excel::Writer::XLSX::Shape;
use Excel::Writer::XLSX::Chart;
use Excel::Writer::XLSX::Package::Packager;
use Excel::Writer::XLSX::Package::XMLwriter;
use Excel::Writer::XLSX::Utility qw(xl_cell_to_rowcol xl_rowcol_to_cell);
our @ISA     = qw(Excel::Writer::XLSX::Package::XMLwriter);
our $VERSION = '1.03';
sub new {
    my $class = shift;
    my $self  = Excel::Writer::XLSX::Package::XMLwriter->new();
    $self->{_filename} = $_[0] || '';
    my $options = $_[1] || {};
    $self->{_tempdir}            = undef;
    $self->{_date_1904}          = 0;
    $self->{_activesheet}        = 0;
    $self->{_firstsheet}         = 0;
    $self->{_selected}           = 0;
    $self->{_fileclosed}         = 0;
    $self->{_filehandle}         = undef;
    $self->{_internal_fh}        = 0;
    $self->{_sheet_name}         = 'Sheet';
    $self->{_chart_name}         = 'Chart';
    $self->{_sheetname_count}    = 0;
    $self->{_chartname_count}    = 0;
    $self->{_worksheets}         = [];
    $self->{_charts}             = [];
    $self->{_drawings}           = [];
    $self->{_sheetnames}         = {};
    $self->{_formats}            = [];
    $self->{_xf_formats}         = [];
    $self->{_xf_format_indices}  = {};
    $self->{_dxf_formats}        = [];
    $self->{_dxf_format_indices} = {};
    $self->{_palette}            = [];
    $self->{_font_count}         = 0;
    $self->{_num_format_count}   = 0;
    $self->{_defined_names}      = [];
    $self->{_named_ranges}       = [];
    $self->{_custom_colors}      = [];
    $self->{_doc_properties}     = {};
    $self->{_custom_properties}  = [];
    $self->{_createtime}         = [ gmtime() ];
    $self->{_num_vml_files}      = 0;
    $self->{_num_comment_files}  = 0;
    $self->{_optimization}       = 0;
    $self->{_x_window}           = 240;
    $self->{_y_window}           = 15;
    $self->{_window_width}       = 16095;
    $self->{_window_height}      = 9660;
    $self->{_tab_ratio}          = 600;
    $self->{_excel2003_style}    = 0;
    $self->{_max_url_length}     = 2079;
    $self->{_has_comments}       = 0;
    $self->{_default_format_properties} = {};
    if ( exists $options->{tempdir} ) {
        $self->{_tempdir} = $options->{tempdir};
    }
    if ( exists $options->{date_1904} ) {
        $self->{_date_1904} = $options->{date_1904};
    }
    if ( exists $options->{optimization} ) {
        $self->{_optimization} = $options->{optimization};
    }
    if ( exists $options->{default_format_properties} ) {
        $self->{_default_format_properties} =
          $options->{default_format_properties};
    }
    if ( exists $options->{excel2003_style} ) {
        $self->{_excel2003_style} = 1;
    }
    if ( exists $options->{max_url_length} ) {
        $self->{_max_url_length} = $options->{max_url_length};
        if ($self->{_max_url_length} < 255) {
            $self->{_max_url_length} = 2079;
        }
    }
    $self->{_str_total}  = 0;
    $self->{_str_unique} = 0;
    $self->{_str_table}  = {};
    $self->{_str_array}  = [];
    $self->{_calc_id}      = 124519;
    $self->{_calc_mode}    = 'auto';
    $self->{_calc_on_load} = 1;
    bless $self, $class;
    if ( $self->{_excel2003_style} ) {
        $self->add_format( xf_index => 0, font_family => 0 );
    }
    else {
        $self->add_format( xf_index => 0 );
    }
    $self->{_default_url_format} = $self->add_format( hyperlink => 1 );
    if ( not ref $self->{_filename} and $self->{_filename} eq '' ) {
        carp 'Filename required by Excel::Writer::XLSX->new()';
        return undef;
    }
    if ( ref $self->{_filename} ) {
        $self->{_filehandle}  = $self->{_filename};
        $self->{_internal_fh} = 0;
    }
    elsif ( $self->{_filename} eq '-' ) {
        binmode STDOUT;
        $self->{_filehandle}  = \*STDOUT;
        $self->{_internal_fh} = 0;
    }
    else {
        my $fh = IO::File->new( $self->{_filename}, 'w' );
        return undef unless defined $fh;
        $self->{_filehandle}  = $fh;
        $self->{_internal_fh} = 1;
    }
    $self->set_color_palette();
    return $self;
}
sub _assemble_xml_file {
    my $self = shift;
    $self->_prepare_format_properties();
    $self->xml_declaration;
    $self->_write_workbook();
    $self->_write_file_version();
    $self->_write_workbook_pr();
    $self->_write_book_views();
    $self->_write_sheets();
    $self->_write_defined_names();
    $self->_write_calc_pr();
    $self->xml_end_tag( 'workbook' );
    $self->xml_get_fh()->close();
}
sub close {
    my $self = shift;
    return if $self->{_fileclosed};
    return undef if !defined $self->{_filehandle};
    $self->{_fileclosed} = 1;
    $self->_store_workbook();
    if ( $self->{_internal_fh} ) {
        return $self->{_filehandle}->close();
    }
    else {
        return 1;
    }
}
sub DESTROY {
    my $self = shift;
    local ( $@, $!, $^E, $? );
    $self->close() if not $self->{_fileclosed};
}
sub sheets {
    my $self = shift;
    if ( @_ ) {
        return @{ $self->{_worksheets} }[@_];
    }
    else {
        return @{ $self->{_worksheets} };
    }
}
sub get_worksheet_by_name {
    my $self      = shift;
    my $sheetname = shift;
    return undef if not defined $sheetname;
    return $self->{_sheetnames}->{$sheetname};
}
sub worksheets {
    my $self = shift;
    return $self->{_worksheets};
}
sub add_worksheet {
    my $self  = shift;
    my $index = @{ $self->{_worksheets} };
    my $name  = $self->_check_sheetname( $_[0] );
    my $fh    = undef;
    my @init_data = (
        $fh,
        $name,
        $index,
        \$self->{_activesheet},
        \$self->{_firstsheet},
        \$self->{_str_total},
        \$self->{_str_unique},
        \$self->{_str_table},
        $self->{_date_1904},
        $self->{_palette},
        $self->{_optimization},
        $self->{_tempdir},
        $self->{_excel2003_style},
        $self->{_default_url_format},
        $self->{_max_url_length},
    );
    my $worksheet = Excel::Writer::XLSX::Worksheet->new( @init_data );
    $self->{_worksheets}->[$index] = $worksheet;
    $self->{_sheetnames}->{$name} = $worksheet;
    return $worksheet;
}
sub add_chart {
    my $self  = shift;
    my %arg   = @_;
    my $name  = '';
    my $index = @{ $self->{_worksheets} };
    my $fh    = undef;
    my $type = $arg{type};
    if ( !defined $type ) {
        croak "Must define chart type in add_chart()";
    }
    my $embedded = $arg{embedded} || 0;
    if ( !$embedded ) {
        $name = $self->_check_sheetname( $arg{name}, 1 );
    }
    my @init_data = (
        $fh,
        $name,
        $index,
        \$self->{_activesheet},
        \$self->{_firstsheet},
        \$self->{_str_total},
        \$self->{_str_unique},
        \$self->{_str_table},
        $self->{_date_1904},
        $self->{_palette},
        $self->{_optimization},
    );
    my $chart = Excel::Writer::XLSX::Chart->factory( $type, $arg{subtype} );
    if ( !$embedded ) {
        my $drawing    = Excel::Writer::XLSX::Drawing->new();
        my $chartsheet = Excel::Writer::XLSX::Chartsheet->new( @init_data );
        $chart->{_palette} = $self->{_palette};
        $chartsheet->{_chart}   = $chart;
        $chartsheet->{_drawing} = $drawing;
        $self->{_worksheets}->[$index] = $chartsheet;
        $self->{_sheetnames}->{$name} = $chartsheet;
        push @{ $self->{_charts} }, $chart;
        return $chartsheet;
    }
    else {
        $chart->{_chart_name} = $arg{name} if $arg{name};
        $chart->{_index}   = 0;
        $chart->{_palette} = $self->{_palette};
        $chart->_set_embedded_config_data();
        push @{ $self->{_charts} }, $chart;
        return $chart;
    }
}
sub _check_sheetname {
    my $self         = shift;
    my $name         = shift || "";
    my $chart        = shift || 0;
    my $invalid_char = qr([\[\]:*?/\\]);
    if ( $chart ) {
        $self->{_chartname_count}++;
    }
    else {
        $self->{_sheetname_count}++;
    }
    if ( $name eq "" ) {
        if ( $chart ) {
            $name = $self->{_chart_name} . $self->{_chartname_count};
        }
        else {
            $name = $self->{_sheet_name} . $self->{_sheetname_count};
        }
    }
    croak "Sheetname $name must be <= 31 chars" if length $name > 31;
    if ( $name =~ $invalid_char ) {
        croak 'Invalid character []:*?/\\ in worksheet name: ' . $name;
    }
    if ( $name =~ /^'/ || $name =~ /'$/) {
        croak "Worksheet name $name cannot start or end with an apostrophe";
    }
    foreach my $worksheet ( @{ $self->{_worksheets} } ) {
        my $name_a = $name;
        my $name_b = $worksheet->{_name};
        if ( lc( $name_a ) eq lc( $name_b ) ) {
            croak "Worksheet name '$name', with case ignored, is already used.";
        }
    }
    return $name;
}
sub add_format {
    my $self = shift;
    my @init_data =
      ( \$self->{_xf_format_indices}, \$self->{_dxf_format_indices} );
    if ( $self->{_excel2003_style} ) {
        push @init_data, ( font => 'Arial', size => 10, theme => -1 );
    }
    push @init_data, %{ $self->{_default_format_properties} };
    push @init_data, @_;
    my $format = Excel::Writer::XLSX::Format->new( @init_data );
    push @{ $self->{_formats} }, $format;
    return $format;
}
sub add_shape {
    my $self  = shift;
    my $fh    = undef;
    my $shape = Excel::Writer::XLSX::Shape->new( $fh, @_ );
    $shape->{_palette} = $self->{_palette};
    push @{ $self->{_shapes} }, $shape;
    return $shape;
}
sub set_1904 {
    my $self = shift;
    if ( defined( $_[0] ) ) {
        $self->{_date_1904} = $_[0];
    }
    else {
        $self->{_date_1904} = 1;
    }
}
sub get_1904 {
    my $self = shift;
    return $self->{_date_1904};
}
sub set_custom_color {
    my $self = shift;
    if ( defined $_[1] and $_[1] =~ /^#(\w\w)(\w\w)(\w\w)/ ) {
        @_ = ( $_[0], hex $1, hex $2, hex $3 );
    }
    my $index = $_[0] || 0;
    my $red   = $_[1] || 0;
    my $green = $_[2] || 0;
    my $blue  = $_[3] || 0;
    my $aref = $self->{_palette};
    if ( $index < 8 or $index > 64 ) {
        carp "Color index $index outside range: 8 <= index <= 64";
        return 0;
    }
    if (   ( $red < 0 or $red > 255 )
        || ( $green < 0 or $green > 255 )
        || ( $blue < 0  or $blue > 255 ) )
    {
        carp "Color component outside range: 0 <= color <= 255";
        return 0;
    }
    $index -= 8;
    my @rgb = ( $red, $green, $blue );
    $aref->[$index] = [@rgb];
    push @{ $self->{_custom_colors} }, sprintf "FF%02X%02X%02X", @rgb;
    return $index + 8;
}
sub set_color_palette {
    my $self = shift;
    $self->{_palette} = [
        [ 0x00, 0x00, 0x00, 0x00 ],
        [ 0xff, 0xff, 0xff, 0x00 ],
        [ 0xff, 0x00, 0x00, 0x00 ],
        [ 0x00, 0xff, 0x00, 0x00 ],
        [ 0x00, 0x00, 0xff, 0x00 ],
        [ 0xff, 0xff, 0x00, 0x00 ],
        [ 0xff, 0x00, 0xff, 0x00 ],
        [ 0x00, 0xff, 0xff, 0x00 ],
        [ 0x80, 0x00, 0x00, 0x00 ],
        [ 0x00, 0x80, 0x00, 0x00 ],
        [ 0x00, 0x00, 0x80, 0x00 ],
        [ 0x80, 0x80, 0x00, 0x00 ],
        [ 0x80, 0x00, 0x80, 0x00 ],
        [ 0x00, 0x80, 0x80, 0x00 ],
        [ 0xc0, 0xc0, 0xc0, 0x00 ],
        [ 0x80, 0x80, 0x80, 0x00 ],
        [ 0x99, 0x99, 0xff, 0x00 ],
        [ 0x99, 0x33, 0x66, 0x00 ],
        [ 0xff, 0xff, 0xcc, 0x00 ],
        [ 0xcc, 0xff, 0xff, 0x00 ],
        [ 0x66, 0x00, 0x66, 0x00 ],
        [ 0xff, 0x80, 0x80, 0x00 ],
        [ 0x00, 0x66, 0xcc, 0x00 ],
        [ 0xcc, 0xcc, 0xff, 0x00 ],
        [ 0x00, 0x00, 0x80, 0x00 ],
        [ 0xff, 0x00, 0xff, 0x00 ],
        [ 0xff, 0xff, 0x00, 0x00 ],
        [ 0x00, 0xff, 0xff, 0x00 ],
        [ 0x80, 0x00, 0x80, 0x00 ],
        [ 0x80, 0x00, 0x00, 0x00 ],
        [ 0x00, 0x80, 0x80, 0x00 ],
        [ 0x00, 0x00, 0xff, 0x00 ],
        [ 0x00, 0xcc, 0xff, 0x00 ],
        [ 0xcc, 0xff, 0xff, 0x00 ],
        [ 0xcc, 0xff, 0xcc, 0x00 ],
        [ 0xff, 0xff, 0x99, 0x00 ],
        [ 0x99, 0xcc, 0xff, 0x00 ],
        [ 0xff, 0x99, 0xcc, 0x00 ],
        [ 0xcc, 0x99, 0xff, 0x00 ],
        [ 0xff, 0xcc, 0x99, 0x00 ],
        [ 0x33, 0x66, 0xff, 0x00 ],
        [ 0x33, 0xcc, 0xcc, 0x00 ],
        [ 0x99, 0xcc, 0x00, 0x00 ],
        [ 0xff, 0xcc, 0x00, 0x00 ],
        [ 0xff, 0x99, 0x00, 0x00 ],
        [ 0xff, 0x66, 0x00, 0x00 ],
        [ 0x66, 0x66, 0x99, 0x00 ],
        [ 0x96, 0x96, 0x96, 0x00 ],
        [ 0x00, 0x33, 0x66, 0x00 ],
        [ 0x33, 0x99, 0x66, 0x00 ],
        [ 0x00, 0x33, 0x00, 0x00 ],
        [ 0x33, 0x33, 0x00, 0x00 ],
        [ 0x99, 0x33, 0x00, 0x00 ],
        [ 0x99, 0x33, 0x66, 0x00 ],
        [ 0x33, 0x33, 0x99, 0x00 ],
        [ 0x33, 0x33, 0x33, 0x00 ],
    ];
    return 0;
}
sub set_tempdir {
    my $self = shift;
    my $dir  = shift;
    croak "$dir is not a valid directory" if defined $dir and not -d $dir;
    $self->{_tempdir} = $dir;
}
sub define_name {
    my $self        = shift;
    my $name        = shift;
    my $formula     = shift;
    my $sheet_index = undef;
    my $sheetname   = '';
    my $full_name   = $name;
    $formula =~ s/^=//;
    if ( $name =~ /^(.*)!(.*)$/ ) {
        $sheetname   = $1;
        $name        = $2;
        $sheet_index = $self->_get_sheet_index( $sheetname );
    }
    else {
        $sheet_index = -1;
    }
    if ( !defined $sheet_index ) {
        carp "Unknown sheet name $sheetname in defined_name()";
        return -1;
    }
    if ( $name !~ m/^[\w\\][\w\\.]*$/ || $name =~ m/^\d/ ) {
        carp "Invalid character in name '$name' used in defined_name()";
        return -1;
    }
    if ( $name =~ m/^[a-zA-Z][a-zA-Z]?[a-dA-D]?[0-9]+$/ ) {
        carp "Invalid name '$name' looks like a cell name in defined_name()";
        return -1;
    }
    if ( $name =~ m/^[rcRC]$/ || $name =~ m/^[rcRC]\d+[rcRC]\d+$/ ) {
        carp "Invalid name '$name' like a RC cell ref in defined_name()";
        return -1;
    }
    push @{ $self->{_defined_names} }, [ $name, $sheet_index, $formula ];
}
sub set_size {
    my $self   = shift;
    my $width  = shift;
    my $height = shift;
    if ( !$width ) {
        $self->{_window_width} = 16095;
    }
    else {
        $self->{_window_width} = int( $width * 1440 / 96 );
    }
    if ( !$height ) {
        $self->{_window_height} = 9660;
    }
    else {
        $self->{_window_height} = int( $height * 1440 / 96 );
    }
}
sub set_tab_ratio {
    my $self  = shift;
    my $tab_ratio = shift;
    if (!defined $tab_ratio) {
        return;
    }
    if ( $tab_ratio < 0 or $tab_ratio > 100 ) {
        carp "Tab ratio outside range: 0 <= zoom <= 100";
    }
    else {
        $self->{_tab_ratio} = int( $tab_ratio * 10 );
    }
}
sub set_properties {
    my $self  = shift;
    my %param = @_;
    return -1 unless @_;
    my %valid = (
        title          => 1,
        subject        => 1,
        author         => 1,
        keywords       => 1,
        comments       => 1,
        last_author    => 1,
        created        => 1,
        category       => 1,
        manager        => 1,
        company        => 1,
        status         => 1,
        hyperlink_base => 1,
    );
    for my $parameter ( keys %param ) {
        if ( not exists $valid{$parameter} ) {
            carp "Unknown parameter '$parameter' in set_properties()";
            return -1;
        }
    }
    if ( !exists $param{created} ) {
        $param{created} = $self->{_createtime};
    }
    $self->{_doc_properties} = \%param;
}
sub set_custom_property {
    my $self  = shift;
    my $name  = shift;
    my $value = shift;
    my $type  = shift;
    my %valid_type = (
        'text'       => 1,
        'date'       => 1,
        'number'     => 1,
        'number_int' => 1,
        'bool'       => 1,
    );
    if ( !defined $name || !defined $value ) {
        carp "The name and value parameters must be defined "
          . "in set_custom_property()";
        return -1;
    }
    if ( !$type ) {
        if ( $value =~ /^\d+$/ ) {
            $type = 'number_int';
        }
        elsif ( $value =~
            /^([+-]?)(?=[0-9]|\.[0-9])[0-9]*(\.[0-9]*)?([Ee]([+-]?[0-9]+))?$/ )
        {
            $type = 'number';
        }
        else {
            $type = 'text';
        }
    }
    if ( !exists $valid_type{$type} ) {
        carp "Unknown custom type '$type' in set_custom_property()";
        return -1;
    }
    if ( $type eq 'text' and length $value > 255 ) {
        carp "Length of text custom value '$value' exceeds "
          . "Excel's limit of 255 in set_custom_property()";
        return -1;
    }
    if ( length $value > 255 ) {
        carp "Length of custom name '$name' exceeds "
          . "Excel's limit of 255 in set_custom_property()";
        return -1;
    }
    push @{ $self->{_custom_properties} }, [ $name, $value, $type ];
}
sub add_vba_project {
    my $self        = shift;
    my $vba_project = shift;
    croak "No vbaProject.bin specified in add_vba_project()"
      if not $vba_project;
    croak "Couldn't locate $vba_project in add_vba_project(): $!"
      unless -e $vba_project;
    if ( !$self->{_vba_codemame} ) {
        $self->{_vba_codename} = 'ThisWorkbook';
    }
    $self->{_vba_project} = $vba_project;
}
sub set_vba_name {
    my $self         = shift;
    my $vba_codemame = shift;
    if ( $vba_codemame ) {
        $self->{_vba_codename} = $vba_codemame;
    }
    else {
        $self->{_vba_codename} = 'ThisWorkbook';
    }
}
sub set_calc_mode {
    my $self    = shift;
    my $mode    = shift || 'auto';
    my $calc_id = shift;
    $self->{_calc_mode} = $mode;
    if ( $mode eq 'manual' ) {
        $self->{_calc_mode}    = 'manual';
        $self->{_calc_on_load} = 0;
    }
    elsif ( $mode eq 'auto_except_tables' ) {
        $self->{_calc_mode} = 'autoNoTable';
    }
    $self->{_calc_id} = $calc_id if defined $calc_id;
}
sub get_default_url_format {
    my $self    = shift;
    return $self->{_default_url_format};
}
sub _store_workbook {
    my $self     = shift;
    my $tempdir  = File::Temp->newdir( DIR => $self->{_tempdir} );
    my $packager = Excel::Writer::XLSX::Package::Packager->new();

    return; # debug

    my $zip      = Archive::Zip->new();
    $self->add_worksheet() if not @{ $self->{_worksheets} };
    if ( $self->{_activesheet} == 0 ) {
        $self->{_worksheets}->[0]->{_selected} = 1;
        $self->{_worksheets}->[0]->{_hidden}   = 0;
    }
    for my $sheet ( @{ $self->{_worksheets} } ) {
        $sheet->{_active} = 1 if $sheet->{_index} == $self->{_activesheet};
    }
    if ( $self->{_vba_project} ) {
        for my $sheet ( @{ $self->{_worksheets} } ) {
            if ( !$sheet->{_vba_codename} ) {
                $sheet->set_vba_name();
            }
        }
    }
    $self->_prepare_sst_string_data();
    $self->_prepare_vml_objects();
    $self->_prepare_defined_names();
    $self->_prepare_drawings();
    $self->_add_chart_data();
    $self->_prepare_tables();
    $packager->_add_workbook( $self );
    $packager->_set_package_dir( $tempdir );
    $packager->_create_package();
    $packager = undef;
    my @xlsx_files;
    my $wanted = sub { push @xlsx_files, $File::Find::name if -f };
    File::Find::find(
        {
            wanted          => $wanted,
            untaint         => 1,
            untaint_pattern => qr|^(.+)$|
        },
        $tempdir
    );
    my @tmp     = grep {  m{/xl/} } @xlsx_files;
    @xlsx_files = grep { !m{/xl/} } @xlsx_files;
    @xlsx_files = ( @tmp, @xlsx_files );
    @tmp        = grep {  m{workbook\.xml$} } @xlsx_files;
    @xlsx_files = grep { !m{workbook\.xml$} } @xlsx_files;
    @xlsx_files = ( @tmp, @xlsx_files );
    @tmp        = grep {  m{_rels/workbook\.xml\.rels$} } @xlsx_files;
    @xlsx_files = grep { !m{_rels/workbook\.xml\.rels$} } @xlsx_files;
    @xlsx_files = ( @tmp, @xlsx_files );
    @tmp        = grep {  m{_rels/\.rels$} } @xlsx_files;
    @xlsx_files = grep { !m{_rels/\.rels$} } @xlsx_files;
    @xlsx_files = ( @tmp, @xlsx_files );
    @tmp        = grep {  m{\[Content_Types\]\.xml$} } @xlsx_files;
    @xlsx_files = grep { !m{\[Content_Types\]\.xml$} } @xlsx_files;
    @xlsx_files = ( @tmp, @xlsx_files );
    for my $filename ( @xlsx_files ) {
        my $short_name = $filename;
        $short_name =~ s{^\Q$tempdir\E/?}{};
        my $member = $zip->addFile( $filename, $short_name );
        $member->{'lastModFileDateTime'} = 2162688;
    }
    if ( $self->{_internal_fh} ) {
        if ( $zip->writeToFileHandle( $self->{_filehandle} ) != 0 ) {
            carp 'Error writing zip container for xlsx file.';
        }
    }
    else {
        my $tmp_fh = tempfile( DIR => $self->{_tempdir} );
        my $is_seekable = 1;
        if ( $zip->writeToFileHandle( $tmp_fh, $is_seekable ) != 0 ) {
            carp 'Error writing zip container for xlsx file.';
        }
        my $buffer;
        seek $tmp_fh, 0, 0;
        while ( read( $tmp_fh, $buffer, 4_096 ) ) {
            local $\ = undef;
            print { $self->{_filehandle} } $buffer;
        }
    }
}
sub _prepare_sst_string_data {
    my $self = shift;
    my @strings;
    $#strings = $self->{_str_unique} - 1;    # Pre-extend array
    while ( my $key = each %{ $self->{_str_table} } ) {
        $strings[ $self->{_str_table}->{$key} ] = $key;
    }
    $self->{_str_table} = undef;
    $self->{_str_array} = \@strings;
}
sub _prepare_format_properties {
    my $self = shift;
    $self->_prepare_formats();
    $self->_prepare_fonts();
    $self->_prepare_num_formats();
    $self->_prepare_borders();
    $self->_prepare_fills();
}
sub _prepare_formats {
    my $self = shift;
    for my $format ( @{ $self->{_formats} } ) {
        my $xf_index  = $format->{_xf_index};
        my $dxf_index = $format->{_dxf_index};
        if ( defined $xf_index ) {
            $self->{_xf_formats}->[$xf_index] = $format;
        }
        if ( defined $dxf_index ) {
            $self->{_dxf_formats}->[$dxf_index] = $format;
        }
    }
}
sub _set_default_xf_indices {
    my $self = shift;
    splice @{ $self->{_formats} }, 1, 1;
    for my $format ( @{ $self->{_formats} } ) {
        $format->get_xf_index();
    }
}
sub _prepare_fonts {
    my $self = shift;
    my %fonts;
    my $index = 0;
    for my $format ( @{ $self->{_xf_formats} } ) {
        my $key = $format->get_font_key();
        if ( exists $fonts{$key} ) {
            $format->{_font_index} = $fonts{$key};
            $format->{_has_font}   = 0;
        }
        else {
            $fonts{$key}           = $index;
            $format->{_font_index} = $index;
            $format->{_has_font}   = 1;
            $index++;
        }
    }
    $self->{_font_count} = $index;
    for my $format ( @{ $self->{_dxf_formats} } ) {
        if (   $format->{_color}
            || $format->{_bold}
            || $format->{_italic}
            || $format->{_underline}
            || $format->{_font_strikeout} )
        {
            $format->{_has_dxf_font} = 1;
        }
    }
}
sub _prepare_num_formats {
    my $self = shift;
    my %num_formats;
    my $index            = 164;
    my $num_format_count = 0;
    for my $format ( @{ $self->{_xf_formats} }, @{ $self->{_dxf_formats} } ) {
        my $num_format = $format->{_num_format};
        if ( $num_format =~ m/^\d+$/ && $num_format !~ m/^0+\d/ ) {
            if ($num_format == 0) {
                $num_format = 1;
            }
            $format->{_num_format_index} = $num_format;
            next;
        }
        elsif ( $num_format  eq 'General' ) {
            $format->{_num_format_index} = 0;
            next;
        }
        if ( exists( $num_formats{$num_format} ) ) {
            $format->{_num_format_index} = $num_formats{$num_format};
        }
        else {
            $num_formats{$num_format} = $index;
            $format->{_num_format_index} = $index;
            $index++;
            if ( $format->{_xf_index} ) {
                $num_format_count++;
            }
        }
    }
    $self->{_num_format_count} = $num_format_count;
}
sub _prepare_borders {
    my $self = shift;
    my %borders;
    my $index = 0;
    for my $format ( @{ $self->{_xf_formats} } ) {
        my $key = $format->get_border_key();
        if ( exists $borders{$key} ) {
            $format->{_border_index} = $borders{$key};
            $format->{_has_border}   = 0;
        }
        else {
            $borders{$key}           = $index;
            $format->{_border_index} = $index;
            $format->{_has_border}   = 1;
            $index++;
        }
    }
    $self->{_border_count} = $index;
    for my $format ( @{ $self->{_dxf_formats} } ) {
        my $key = $format->get_border_key();
        if ( $key =~ m/[^0:]/ ) {
            $format->{_has_dxf_border} = 1;
        }
    }
}
sub _prepare_fills {
    my $self = shift;
    my %fills;
    my $index = 2;
    $fills{'0:0:0'}  = 0;
    $fills{'17:0:0'} = 1;
    for my $format ( @{ $self->{_dxf_formats} } ) {
        if (   $format->{_pattern}
            || $format->{_bg_color}
            || $format->{_fg_color} )
        {
            $format->{_has_dxf_fill} = 1;
            $format->{_dxf_bg_color} = $format->{_bg_color};
            $format->{_dxf_fg_color} = $format->{_fg_color};
        }
    }
    for my $format ( @{ $self->{_xf_formats} } ) {
        if (   $format->{_pattern} == 1
            && $format->{_bg_color} ne '0'
            && $format->{_fg_color} ne '0' )
        {
            my $tmp = $format->{_fg_color};
            $format->{_fg_color} = $format->{_bg_color};
            $format->{_bg_color} = $tmp;
        }
        if (   $format->{_pattern} <= 1
            && $format->{_bg_color} ne '0'
            && $format->{_fg_color} eq '0' )
        {
            $format->{_fg_color} = $format->{_bg_color};
            $format->{_bg_color} = 0;
            $format->{_pattern}  = 1;
        }
        if (   $format->{_pattern} <= 1
            && $format->{_bg_color} eq '0'
            && $format->{_fg_color} ne '0' )
        {
            $format->{_bg_color} = 0;
            $format->{_pattern}  = 1;
        }
        my $key = $format->get_fill_key();
        if ( exists $fills{$key} ) {
            $format->{_fill_index} = $fills{$key};
            $format->{_has_fill}   = 0;
        }
        else {
            $fills{$key}           = $index;
            $format->{_fill_index} = $index;
            $format->{_has_fill}   = 1;
            $index++;
        }
    }
    $self->{_fill_count} = $index;
}
sub _prepare_defined_names {
    my $self = shift;
    my @defined_names = @{ $self->{_defined_names} };
    for my $sheet ( @{ $self->{_worksheets} } ) {
        if ( $sheet->{_autofilter} ) {
            my $range  = $sheet->{_autofilter};
            my $hidden = 1;
            push @defined_names,
              [ '_xlnm._FilterDatabase', $sheet->{_index}, $range, $hidden ];
        }
        if ( $sheet->{_print_area} ) {
            my $range = $sheet->{_print_area};
            push @defined_names,
              [ '_xlnm.Print_Area', $sheet->{_index}, $range ];
        }
        if ( $sheet->{_repeat_cols} || $sheet->{_repeat_rows} ) {
            my $range = '';
            if ( $sheet->{_repeat_cols} && $sheet->{_repeat_rows} ) {
                $range = $sheet->{_repeat_cols} . ',' . $sheet->{_repeat_rows};
            }
            else {
                $range = $sheet->{_repeat_cols} . $sheet->{_repeat_rows};
            }
            push @defined_names,
              [ '_xlnm.Print_Titles', $sheet->{_index}, $range ];
        }
    }
    @defined_names          = _sort_defined_names( @defined_names );
    $self->{_defined_names} = \@defined_names;
    $self->{_named_ranges}  = _extract_named_ranges( @defined_names );
}
sub _sort_defined_names {
    my @names = @_;
    @names = sort {
        _normalise_defined_name( $a->[0] )
        cmp
        _normalise_defined_name( $b->[0] )
        ||
        _normalise_sheet_name( $a->[2] )
        cmp
        _normalise_sheet_name( $b->[2] )
    } @names;
    return @names;
}
sub _normalise_defined_name {
    my $name = shift;
    $name =~ s/^_xlnm.//;
    $name = lc $name;
    return $name;
}
sub _normalise_sheet_name {
    my $name = shift;
    $name =~ s/^'//;
    $name = lc $name;
    return $name;
}
sub _extract_named_ranges {
    my @defined_names = @_;
    my @named_ranges;
    NAME:
    for my $defined_name ( @defined_names ) {
        my $name  = $defined_name->[0];
        my $index = $defined_name->[1];
        my $range = $defined_name->[2];
        next NAME if $name eq '_xlnm._FilterDatabase';
        if ( $range =~ /^([^!]+)!/ ) {
            my $sheet_name = $1;
            if ( $name =~ /^_xlnm\.(.*)$/ ) {
                my $xlnm_type = $1;
                $name = $sheet_name . '!' . $xlnm_type;
            }
            elsif ( $index != -1 ) {
                $name = $sheet_name . '!' . $name;
            }
            push @named_ranges, $name;
        }
    }
    return \@named_ranges;
}
sub _prepare_drawings {
    my $self             = shift;
    my $chart_ref_id     = 0;
    my $image_ref_id     = 0;
    my $drawing_id       = 0;
    my $ref_id           = 0;
    my %image_ids        = ();
    my %header_image_ids = ();
    for my $sheet ( @{ $self->{_worksheets} } ) {
        my $chart_count = scalar @{ $sheet->{_charts} };
        my $image_count = scalar @{ $sheet->{_images} };
        my $shape_count = scalar @{ $sheet->{_shapes} };
        my $header_image_count = scalar @{ $sheet->{_header_images} };
        my $footer_image_count = scalar @{ $sheet->{_footer_images} };
        my $has_drawing        = 0;
        if (   !$chart_count
            && !$image_count
            && !$shape_count
            && !$header_image_count
            && !$footer_image_count )
        {
            next;
        }
        if ( $chart_count || $image_count || $shape_count ) {
            $drawing_id++;
            $has_drawing = 1;
        }
        for my $index ( 0 .. $image_count - 1 ) {
            my $filename = $sheet->{_images}->[$index]->[2];
            my ( $type, $width, $height, $name, $x_dpi, $y_dpi, $md5 ) =
              $self->_get_image_properties( $filename );
            if ( exists $image_ids{$md5} ) {
                $ref_id = $image_ids{$md5};
            }
            else {
                $ref_id = ++$image_ref_id;
                $image_ids{$md5} = $ref_id;
                push @{ $self->{_images} }, [ $filename, $type ];
            }
            $sheet->_prepare_image(
                $index, $ref_id, $drawing_id, $width, $height,
                $name,  $type,   $x_dpi,      $y_dpi, $md5
            );
        }
        for my $index ( 0 .. $chart_count - 1 ) {
            $chart_ref_id++;
            $sheet->_prepare_chart( $index, $chart_ref_id, $drawing_id );
        }
        for my $index ( 0 .. $shape_count - 1 ) {
            $sheet->_prepare_shape( $index, $drawing_id );
        }
        for my $index ( 0 .. $header_image_count - 1 ) {
            my $filename = $sheet->{_header_images}->[$index]->[0];
            my $position = $sheet->{_header_images}->[$index]->[1];
            my ( $type, $width, $height, $name, $x_dpi, $y_dpi, $md5 ) =
              $self->_get_image_properties( $filename );
            if ( exists $header_image_ids{$md5} ) {
                $ref_id = $header_image_ids{$md5};
            }
            else {
                $ref_id = ++$image_ref_id;
                $header_image_ids{$md5} = $ref_id;
                push @{ $self->{_images} }, [ $filename, $type ];
            }
            $sheet->_prepare_header_image(
                $ref_id,   $width, $height, $name, $type,
                $position, $x_dpi, $y_dpi,  $md5
            );
        }
        for my $index ( 0 .. $footer_image_count - 1 ) {
            my $filename = $sheet->{_footer_images}->[$index]->[0];
            my $position = $sheet->{_footer_images}->[$index]->[1];
            my ( $type, $width, $height, $name, $x_dpi, $y_dpi, $md5 ) =
              $self->_get_image_properties( $filename );
            if ( exists $header_image_ids{$md5} ) {
                $ref_id = $header_image_ids{$md5};
            }
            else {
                $ref_id = ++$image_ref_id;
                $header_image_ids{$md5} = $ref_id;
                push @{ $self->{_images} }, [ $filename, $type ];
            }
            $sheet->_prepare_header_image(
                $ref_id,   $width, $height, $name, $type,
                $position, $x_dpi, $y_dpi,  $md5
            );
        }
        if ( $has_drawing ) {
            my $drawing = $sheet->{_drawing};
            push @{ $self->{_drawings} }, $drawing;
        }
    }
    my @chart_data;
    for my $chart ( @{ $self->{_charts} } ) {
        if ( $chart->{_id} != -1 ) {
            push @chart_data, $chart;
        }
    }
    @chart_data = sort { $a->{_id} <=> $b->{_id} } @chart_data;
    $self->{_charts}        = \@chart_data;
    $self->{_drawing_count} = $drawing_id;
}
sub _prepare_vml_objects {
    my $self           = shift;
    my $comment_id     = 0;
    my $vml_drawing_id = 0;
    my $vml_data_id    = 1;
    my $vml_header_id  = 0;
    my $vml_shape_id   = 1024;
    my $vml_files      = 0;
    my $comment_files  = 0;
    for my $sheet ( @{ $self->{_worksheets} } ) {
        next if !$sheet->{_has_vml} and !$sheet->{_has_header_vml};
        $vml_files = 1;
        if ( $sheet->{_has_vml} ) {
            if ( $sheet->{_has_comments} ) {
                $comment_files++;
                $comment_id++;
                $self->{_has_comments} = 1;
            }
            $vml_drawing_id++;
            my $count =
              $sheet->_prepare_vml_objects( $vml_data_id, $vml_shape_id,
                $vml_drawing_id, $comment_id );
            $vml_data_id  += 1 * int(    ( 1024 + $count ) / 1024 );
            $vml_shape_id += 1024 * int( ( 1024 + $count ) / 1024 );
        }
        if ( $sheet->{_has_header_vml} ) {
            $vml_header_id++;
            $vml_drawing_id++;
            $sheet->_prepare_header_vml_objects( $vml_header_id,
                $vml_drawing_id );
        }
    }
    $self->{_num_vml_files}     = $vml_files;
    $self->{_num_comment_files} = $comment_files;
}
sub _prepare_tables {
    my $self     = shift;
    my $table_id = 0;
    my $seen     = {};
    for my $sheet ( @{ $self->{_worksheets} } ) {
        my $table_count = scalar @{ $sheet->{_tables} };
        next unless $table_count;
        $sheet->_prepare_tables( $table_id + 1, $seen );
        $table_id += $table_count;
    }
}
sub _add_chart_data {
    my $self = shift;
    my %worksheets;
    my %seen_ranges;
    my @charts;
    for my $worksheet ( @{ $self->{_worksheets} } ) {
        $worksheets{ $worksheet->{_name} } = $worksheet;
    }
    for my $chart ( @{ $self->{_charts} } ) {
        push @charts, $chart;
        if ($chart->{_combined}) {
            push @charts, $chart->{_combined};
        }
    }
    CHART:
    for my $chart ( @charts ) {
        RANGE:
        while ( my ( $range, $id ) = each %{ $chart->{_formula_ids} } ) {
            if ( defined $chart->{_formula_data}->[$id] ) {
                if (   !exists $seen_ranges{$range}
                    || !defined $seen_ranges{$range} )
                {
                    my $data = $chart->{_formula_data}->[$id];
                    $seen_ranges{$range} = $data;
                }
                next RANGE;
            }
            if ( exists $seen_ranges{$range} ) {
                $chart->{_formula_data}->[$id] = $seen_ranges{$range};
                next RANGE;
            }
            my ( $sheetname, @cells ) = $self->_get_chart_range( $range );
            next RANGE if !defined $sheetname;
            if ( $sheetname =~ m/^\([^,]+,/ ) {
                $chart->{_formula_data}->[$id] = [];
                $seen_ranges{$range} = [];
                next RANGE;
            }
            if ( !exists $worksheets{$sheetname} ) {
                die "Unknown worksheet reference '$sheetname' in range "
                  . "'$range' passed to add_series().\n";
            }
            my $worksheet = $worksheets{$sheetname};
            my @data = $worksheet->_get_range_data( @cells );
            for my $token ( @data ) {
                if ( ref $token ) {
                    $token = $self->{_str_array}->[ $token->{sst_id} ];
                    if ( $token =~ m{^<r>} && $token =~ m{</r>$} ) {
                        $token = '';
                    }
                }
            }
            $chart->{_formula_data}->[$id] = \@data;
            $seen_ranges{$range} = \@data;
        }
    }
}
sub _get_chart_range {
    my $self  = shift;
    my $range = shift;
    my $cell_1;
    my $cell_2;
    my $sheetname;
    my $cells;
    my $pos = rindex $range, '!';
    if ( $pos > 0 ) {
        $sheetname = substr $range, 0, $pos;
        $cells = substr $range, $pos + 1;
    }
    else {
        return undef;
    }
    if ( $cells =~ ':' ) {
        ( $cell_1, $cell_2 ) = split /:/, $cells;
    }
    else {
        ( $cell_1, $cell_2 ) = ( $cells, $cells );
    }
    $sheetname =~ s/^'//g;
    $sheetname =~ s/'$//g;
    $sheetname =~ s/''/'/g;
    my ( $row_start, $col_start ) = xl_cell_to_rowcol( $cell_1 );
    my ( $row_end,   $col_end )   = xl_cell_to_rowcol( $cell_2 );
    if ( $row_start != $row_end && $col_start != $col_end ) {
        return undef;
    }
    return ( $sheetname, $row_start, $col_start, $row_end, $col_end );
}
sub _store_externs {
    my $self = shift;
}
sub _store_names {
    my $self = shift;
}
sub _quote_sheetname {
    my $self      = shift;
    my $sheetname = $_[0];
    if ( $sheetname =~ /^Sheet\d+$/ ) {
        return $sheetname;
    }
    else {
        return qq('$sheetname');
    }
}
sub _get_image_properties {
    my $self     = shift;
    my $filename = shift;
    my $type;
    my $width;
    my $height;
    my $x_dpi = 96;
    my $y_dpi = 96;
    my $image_name;
    ( $image_name ) = fileparse( $filename );
    my $fh = FileHandle->new( $filename );
    croak "Couldn't import $filename: $!" unless defined $fh;
    binmode $fh;
    my $data = do { local $/; <$fh> };
    my $size = length $data;
    my $md5  = md5_hex($data);
    if ( unpack( 'x A3', $data ) eq 'PNG' ) {
        ( $type, $width, $height, $x_dpi, $y_dpi ) =
          $self->_process_png( $data, $filename );
        $self->{_image_types}->{png} = 1;
    }
    elsif ( unpack( 'n', $data ) == 0xFFD8 ) {
        ( $type, $width, $height, $x_dpi, $y_dpi ) =
          $self->_process_jpg( $data, $filename );
        $self->{_image_types}->{jpeg} = 1;
    }
    elsif ( unpack( 'A2', $data ) eq 'BM' ) {
        ( $type, $width, $height ) = $self->_process_bmp( $data, $filename );
        $self->{_image_types}->{bmp} = 1;
    }
    else {
        croak "Unsupported image format for file: $filename\n";
    }
    $x_dpi = 96 if $x_dpi == 0;
    $y_dpi = 96 if $y_dpi == 0;
    $fh->close;
    return ( $type, $width, $height, $image_name, $x_dpi, $y_dpi, $md5 );
}
sub _process_png {
    my $self     = shift;
    my $data     = $_[0];
    my $filename = $_[1];
    my $type   = 'png';
    my $width  = 0;
    my $height = 0;
    my $x_dpi  = 96;
    my $y_dpi  = 96;
    my $offset      = 8;
    my $data_length = length $data;
    while ( $offset < $data_length ) {
        my $length = unpack "N",  substr $data, $offset + 0, 4;
        my $type   = unpack "A4", substr $data, $offset + 4, 4;
        if ( $type eq "IHDR" ) {
            $width  = unpack "N", substr $data, $offset + 8,  4;
            $height = unpack "N", substr $data, $offset + 12, 4;
        }
        if ( $type eq "pHYs" ) {
            my $x_ppu = unpack "N", substr $data, $offset + 8,  4;
            my $y_ppu = unpack "N", substr $data, $offset + 12, 4;
            my $units = unpack "C", substr $data, $offset + 16, 1;
            if ( $units == 1 ) {
                $x_dpi = $x_ppu * 0.0254;
                $y_dpi = $y_ppu * 0.0254;
            }
        }
        $offset = $offset + $length + 12;
        last if $type eq "IEND";
    }
    if ( not defined $height ) {
        croak "$filename: no size data found in png image.\n";
    }
    return ( $type, $width, $height, $x_dpi, $y_dpi );
}
sub _process_bmp {
    my $self     = shift;
    my $data     = $_[0];
    my $filename = $_[1];
    my $type     = 'bmp';
    if ( length $data <= 0x36 ) {
        croak "$filename doesn't contain enough data.";
    }
    my ( $width, $height ) = unpack "x18 V2", $data;
    if ( $width > 0xFFFF ) {
        croak "$filename: largest image width $width supported is 65k.";
    }
    if ( $height > 0xFFFF ) {
        croak "$filename: largest image height supported is 65k.";
    }
    my ( $planes, $bitcount ) = unpack "x26 v2", $data;
    if ( $bitcount != 24 ) {
        croak "$filename isn't a 24bit true color bitmap.";
    }
    if ( $planes != 1 ) {
        croak "$filename: only 1 plane supported in bitmap image.";
    }
    my $compression = unpack "x30 V", $data;
    if ( $compression != 0 ) {
        croak "$filename: compression not supported in bitmap image.";
    }
    return ( $type, $width, $height );
}
sub _process_jpg {
    my $self     = shift;
    my $data     = $_[0];
    my $filename = $_[1];
    my $type     = 'jpeg';
    my $x_dpi    = 96;
    my $y_dpi    = 96;
    my $width;
    my $height;
    my $offset      = 2;
    my $data_length = length $data;
    while ( $offset < $data_length ) {
        my $marker = unpack "n", substr $data, $offset + 0, 2;
        my $length = unpack "n", substr $data, $offset + 2, 2;
        if (   ( $marker & 0xFFF0 ) == 0xFFC0
            && $marker != 0xFFC4
            && $marker != 0xFFCC )
        {
            $height = unpack "n", substr $data, $offset + 5, 2;
            $width  = unpack "n", substr $data, $offset + 7, 2;
        }
        if ( $marker == 0xFFE0 ) {
            my $units     = unpack "C", substr $data, $offset + 11, 1;
            my $x_density = unpack "n", substr $data, $offset + 12, 2;
            my $y_density = unpack "n", substr $data, $offset + 14, 2;
            if ( $units == 1 ) {
                $x_dpi = $x_density;
                $y_dpi = $y_density;
            }
            if ( $units == 2 ) {
                $x_dpi = $x_density * 2.54;
                $y_dpi = $y_density * 2.54;
            }
        }
        $offset = $offset + $length + 2;
        last if $marker == 0xFFDA;
    }
    if ( not defined $height ) {
        croak "$filename: no size data found in jpeg image.\n";
    }
    return ( $type, $width, $height, $x_dpi, $y_dpi );
}
sub _get_sheet_index {
    my $self        = shift;
    my $sheetname   = shift;
    my $sheet_index = undef;
    $sheetname =~ s/^'//;
    $sheetname =~ s/'$//;
    if ( exists $self->{_sheetnames}->{$sheetname} ) {
        return $self->{_sheetnames}->{$sheetname}->{_index};
    }
    else {
        return undef;
    }
}
sub set_optimization {
    my $self = shift;
    my $level = defined $_[0] ? $_[0] : 1;
    croak "set_optimization() must be called before add_worksheet()"
      if $self->sheets();
    $self->{_optimization} = $level;
}
sub compatibility_mode { }
sub set_codepage       { }
sub _write_workbook {
    my $self    = shift;
    my $schema  = 'http://schemas.openxmlformats.org';
    my $xmlns   = $schema . '/spreadsheetml/2006/main';
    my $xmlns_r = $schema . '/officeDocument/2006/relationships';
    my @attributes = (
        'xmlns'   => $xmlns,
        'xmlns:r' => $xmlns_r,
    );
    $self->xml_start_tag( 'workbook', @attributes );
}
sub _write_file_version {
    my $self          = shift;
    my $app_name      = 'xl';
    my $last_edited   = 4;
    my $lowest_edited = 4;
    my $rup_build     = 4505;
    my @attributes = (
        'appName'      => $app_name,
        'lastEdited'   => $last_edited,
        'lowestEdited' => $lowest_edited,
        'rupBuild'     => $rup_build,
    );
    if ( $self->{_vba_project} ) {
        push @attributes, codeName => '{37E998C4-C9E5-D4B9-71C8-EB1FF731991C}';
    }
    $self->xml_empty_tag( 'fileVersion', @attributes );
}
sub _write_workbook_pr {
    my $self                   = shift;
    my $date_1904              = $self->{_date_1904};
    my $show_ink_annotation    = 0;
    my $auto_compress_pictures = 0;
    my $default_theme_version  = 124226;
    my $codename               = $self->{_vba_codename};
    my @attributes;
    push @attributes, ( 'codeName' => $codename ) if $codename;
    push @attributes, ( 'date1904' => 1 )         if $date_1904;
    push @attributes, ( 'defaultThemeVersion' => $default_theme_version );
    $self->xml_empty_tag( 'workbookPr', @attributes );
}
sub _write_book_views {
    my $self = shift;
    $self->xml_start_tag( 'bookViews' );
    $self->_write_workbook_view();
    $self->xml_end_tag( 'bookViews' );
}
sub _write_workbook_view {
    my $self          = shift;
    my $x_window      = $self->{_x_window};
    my $y_window      = $self->{_y_window};
    my $window_width  = $self->{_window_width};
    my $window_height = $self->{_window_height};
    my $tab_ratio     = $self->{_tab_ratio};
    my $active_tab    = $self->{_activesheet};
    my $first_sheet   = $self->{_firstsheet};
    my @attributes = (
        'xWindow'      => $x_window,
        'yWindow'      => $y_window,
        'windowWidth'  => $window_width,
        'windowHeight' => $window_height,
    );
    push @attributes, ( tabRatio => $tab_ratio ) if $tab_ratio != 600;
    push @attributes, ( firstSheet => $first_sheet + 1 ) if $first_sheet > 0;
    push @attributes, ( activeTab => $active_tab ) if $active_tab > 0;
    $self->xml_empty_tag( 'workbookView', @attributes );
}
sub _write_sheets {
    my $self   = shift;
    my $id_num = 1;
    $self->xml_start_tag( 'sheets' );
    for my $worksheet ( @{ $self->{_worksheets} } ) {
        $self->_write_sheet( $worksheet->{_name}, $id_num++,
            $worksheet->{_hidden} );
    }
    $self->xml_end_tag( 'sheets' );
}
sub _write_sheet {
    my $self     = shift;
    my $name     = shift;
    my $sheet_id = shift;
    my $hidden   = shift;
    my $r_id     = 'rId' . $sheet_id;
    my @attributes = (
        'name'    => $name,
        'sheetId' => $sheet_id,
    );
    push @attributes, ( 'state' => 'hidden' ) if $hidden;
    push @attributes, ( 'r:id' => $r_id );
    $self->xml_empty_tag( 'sheet', @attributes );
}
sub _write_calc_pr {
    my $self            = shift;
    my $calc_id         = $self->{_calc_id};
    my $concurrent_calc = 0;
    my @attributes = ( calcId => $calc_id );
    if ( $self->{_calc_mode} eq 'manual' ) {
        push @attributes, 'calcMode'   => 'manual';
        push @attributes, 'calcOnSave' => 0;
    }
    elsif ( $self->{_calc_mode} eq 'autoNoTable' ) {
        push @attributes, calcMode => 'autoNoTable';
    }
    if ( $self->{_calc_on_load} ) {
        push @attributes, 'fullCalcOnLoad' => 1;
    }
    $self->xml_empty_tag( 'calcPr', @attributes );
}
sub _write_ext_lst {
    my $self = shift;
    $self->xml_start_tag( 'extLst' );
    $self->_write_ext();
    $self->xml_end_tag( 'extLst' );
}
sub _write_ext {
    my $self     = shift;
    my $xmlns_mx = 'http://schemas.microsoft.com/office/mac/excel/2008/main';
    my $uri      = 'http://schemas.microsoft.com/office/mac/excel/2008/main';
    my @attributes = (
        'xmlns:mx' => $xmlns_mx,
        'uri'      => $uri,
    );
    $self->xml_start_tag( 'ext', @attributes );
    $self->_write_mx_arch_id();
    $self->xml_end_tag( 'ext' );
}
sub _write_mx_arch_id {
    my $self  = shift;
    my $Flags = 2;
    my @attributes = ( 'Flags' => $Flags, );
    $self->xml_empty_tag( 'mx:ArchID', @attributes );
}
sub _write_defined_names {
    my $self = shift;
    return unless @{ $self->{_defined_names} };
    $self->xml_start_tag( 'definedNames' );
    for my $aref ( @{ $self->{_defined_names} } ) {
        $self->_write_defined_name( $aref );
    }
    $self->xml_end_tag( 'definedNames' );
}
sub _write_defined_name {
    my $self = shift;
    my $data = shift;
    my $name   = $data->[0];
    my $id     = $data->[1];
    my $range  = $data->[2];
    my $hidden = $data->[3];
    my @attributes = ( 'name' => $name );
    push @attributes, ( 'localSheetId' => $id ) if $id != -1;
    push @attributes, ( 'hidden'       => 1 )   if $hidden;
    $self->xml_data_element( 'definedName', $range, @attributes );
}
1;
