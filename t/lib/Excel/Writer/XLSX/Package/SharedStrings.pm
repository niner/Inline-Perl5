package Excel::Writer::XLSX::Package::SharedStrings;
use 5.008002;
use strict;
use warnings;
use Carp;
use Encode;
use Excel::Writer::XLSX::Package::XMLwriter;
our @ISA     = qw(Excel::Writer::XLSX::Package::XMLwriter);
our $VERSION = '1.03';
sub new {
    my $class = shift;
    my $fh    = shift;
    my $self  = Excel::Writer::XLSX::Package::XMLwriter->new( $fh );
    $self->{_strings}      = [];
    $self->{_string_count} = 0;
    $self->{_unique_count} = 0;
    bless $self, $class;
    return $self;
}
sub _assemble_xml_file {
    my $self = shift;
    $self->xml_declaration;
    $self->_write_sst( $self->{_string_count}, $self->{_unique_count} );
    $self->_write_sst_strings();
    $self->xml_end_tag( 'sst' );
    $self->xml_get_fh()->close();
}
sub _set_string_count {
    my $self = shift;
    $self->{_string_count} = shift;
}
sub _set_unique_count {
    my $self = shift;
    $self->{_unique_count} = shift;
}
sub _add_strings {
    my $self = shift;
    $self->{_strings} = shift;
}
sub _write_sst {
    my $self         = shift;
    my $count        = shift;
    my $unique_count = shift;
    my $schema       = 'http://schemas.openxmlformats.org';
    my $xmlns        = $schema . '/spreadsheetml/2006/main';
    my @attributes = (
        'xmlns'       => $xmlns,
        'count'       => $count,
        'uniqueCount' => $unique_count,
    );
    $self->xml_start_tag( 'sst', @attributes );
}
sub _write_sst_strings {
    my $self = shift;
    for my $string ( @{ $self->{_strings} } ) {
        $self->_write_si( $string );
    }
}
sub _write_si {
    my $self       = shift;
    my $string     = shift;
    my @attributes = ();
    $string =~ s/(_x[0-9a-fA-F]{4}_)/_x005F$1/g;
    $string =~ s/([\x00-\x08\x0B-\x1F])/sprintf "_x%04X_", ord($1)/eg;
    if ( $string =~ /^\s/ || $string =~ /\s$/ ) {
        push @attributes, ( 'xml:space' => 'preserve' );
    }
    if ( $string =~ m{^<r>} && $string =~ m{</r>$} ) {
        $string = decode_utf8( $string );
        $self->xml_rich_si_element( $string );
    }
    else {
        $self->xml_si_element( $string, @attributes );
    }
}
1;
