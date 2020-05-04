package Excel::Writer::XLSX::Utility;
use 5.008002;
use strict;
use Exporter;
use warnings;
use autouse 'Date::Calc'  => qw(Delta_DHMS Decode_Date_EU Decode_Date_US);
use autouse 'Date::Manip' => qw(ParseDate Date_Init);
our $VERSION = '1.03';
my @rowcol = qw(
  xl_rowcol_to_cell
  xl_cell_to_rowcol
  xl_col_to_name
  xl_range
  xl_range_formula
  xl_inc_row
  xl_dec_row
  xl_inc_col
  xl_dec_col
);
my @dates = qw(
  xl_date_list
  xl_date_1904
  xl_parse_time
  xl_parse_date
  xl_parse_date_init
  xl_decode_date_EU
  xl_decode_date_US
);
our @ISA         = qw(Exporter);
our @EXPORT_OK   = ();
our @EXPORT      = ( @rowcol, @dates, 'quote_sheetname' );
our %EXPORT_TAGS = (
    rowcol => \@rowcol,
    dates  => \@dates
);
sub xl_rowcol_to_cell {
    my $row     = $_[0] + 1;          
    my $col     = $_[1];
    my $row_abs = $_[2] ? '$' : '';
    my $col_abs = $_[3] ? '$' : '';
    my $col_str = xl_col_to_name( $col, $col_abs );
    return $col_str . $row_abs . $row;
}
sub xl_cell_to_rowcol {
    my $cell = shift;
    return ( 0, 0, 0, 0 ) unless $cell;
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
sub xl_col_to_name {
    my $col     = $_[0];
    my $col_abs = $_[1] ? '$' : '';
    my $col_str = '';
    $col++;
    while ( $col ) {
        my $remainder = $col % 26 || 26;
        my $col_letter = chr( ord( 'A' ) + $remainder - 1 );
        $col_str = $col_letter . $col_str;
        $col = int( ( $col - 1 ) / 26 );
    }
    return $col_abs . $col_str;
}
sub xl_range {
    my ( $row_1,     $row_2,     $col_1,     $col_2 )     = @_[ 0 .. 3 ];
    my ( $row_abs_1, $row_abs_2, $col_abs_1, $col_abs_2 ) = @_[ 4 .. 7 ];
    my $range1 = xl_rowcol_to_cell( $row_1, $col_1, $row_abs_1, $col_abs_1 );
    my $range2 = xl_rowcol_to_cell( $row_2, $col_2, $row_abs_2, $col_abs_2 );
    return $range1 . ':' . $range2;
}
sub xl_range_formula {
    my ( $sheetname, $row_1, $row_2, $col_1, $col_2 ) = @_;
    $sheetname = quote_sheetname( $sheetname );
    my $range = xl_range( $row_1, $row_2, $col_1, $col_2, 1, 1, 1, 1 );
    return '=' . $sheetname . '!' . $range
}
sub quote_sheetname {
    my $sheetname = $_[0];
    if ( $sheetname =~ /\W/ && $sheetname !~ /^'/ ) {
        $sheetname =~ s/'/''/g;
        $sheetname = q(') . $sheetname . q(');
    }
    return $sheetname;
}
sub xl_inc_row {
    my $cell = shift;
    my ( $row, $col, $row_abs, $col_abs ) = xl_cell_to_rowcol( $cell );
    return xl_rowcol_to_cell( ++$row, $col, $row_abs, $col_abs );
}
sub xl_dec_row {
    my $cell = shift;
    my ( $row, $col, $row_abs, $col_abs ) = xl_cell_to_rowcol( $cell );
    return xl_rowcol_to_cell( --$row, $col, $row_abs, $col_abs );
}
sub xl_inc_col {
    my $cell = shift;
    my ( $row, $col, $row_abs, $col_abs ) = xl_cell_to_rowcol( $cell );
    return xl_rowcol_to_cell( $row, ++$col, $row_abs, $col_abs );
}
sub xl_dec_col {
    my $cell = shift;
    my ( $row, $col, $row_abs, $col_abs ) = xl_cell_to_rowcol( $cell );
    return xl_rowcol_to_cell( $row, --$col, $row_abs, $col_abs );
}
sub xl_date_list {
    return undef unless @_;
    my $years   = $_[0];
    my $months  = $_[1] || 1;
    my $days    = $_[2] || 1;
    my $hours   = $_[3] || 0;
    my $minutes = $_[4] || 0;
    my $seconds = $_[5] || 0;
    my @date = ( $years, $months, $days, $hours, $minutes, $seconds );
    my @epoch = ( 1899, 12, 31, 0, 0, 0 );
    ( $days, $hours, $minutes, $seconds ) = Delta_DHMS( @epoch, @date );
    my $date =
      $days + ( $hours * 3600 + $minutes * 60 + $seconds ) / ( 24 * 60 * 60 );
    $date++ if ( $date > 59 );
    return $date;
}
sub xl_parse_time {
    my $time = shift;
    if ( $time =~ /(\d+):(\d\d):?((?:\d\d)(?:\.\d+)?)?(?:\s+)?(am|pm)?/i ) {
        my $hours    = $1;
        my $minutes  = $2;
        my $seconds  = $3 || 0;
        my $meridian = lc( $4 || '' );
        $hours = 0 if ( $hours == 12 && $meridian ne '' );
        $hours += 12 if $meridian eq 'pm';
        return ( $hours * 3600 + $minutes * 60 + $seconds ) / ( 24 * 60 * 60 );
    }
    else {
        return undef;    
    }
}
sub xl_parse_date {
    my $date = ParseDate( $_[0] );
    my ( $years, $months, $days, $hours, undef, $minutes, undef, $seconds ) =
      unpack( "A4     A2      A2     A2      C        A2      C       A2",
        $date );
    return xl_date_list( $years, $months, $days, $hours, $minutes, $seconds );
}
sub xl_parse_date_init {
    Date_Init( @_ );    
}
sub xl_decode_date_EU {
    return undef unless @_;
    my $date = shift;
    my @date;
    my $time = 0;
    if ( $date =~ s/(\d+:\d\d:?(\d\d(\.\d+)?)?(\s+)?(am|pm)?)//i ) {
        $time = xl_parse_time( $1 );
    }
    return $time if $date =~ /^\s*$/;
    @date = Decode_Date_EU( $date );
    return undef unless @date;
    return xl_date_list( @date ) + $time;
}
sub xl_decode_date_US {
    return undef unless @_;
    my $date = shift;
    my @date;
    my $time = 0;
    if ( $date =~ s/(\d+:\d\d:?(\d\d(\.\d+)?)?(\s+)?(am|pm)?)//i ) {
        $time = xl_parse_time( $1 );
    }
    return $time if $date =~ /^\s*$/;
    @date = Decode_Date_US( $date );
    return undef unless @date;
    return xl_date_list( @date ) + $time;
}
sub xl_date_1904 {
    my $date = $_[0] || 0;
    if ( $date < 1462 ) {
        $date = 0;
    }
    else {
        $date -= 1462;
    }
    return $date;
}
1;
