package Excel::Writer::XLSX::Package::XMLwriter;
use 5.008002;
use strict;
use warnings;
use Exporter;
use Carp;
use IO::File;
our @ISA     = qw(Exporter);
our $VERSION = '1.03';
sub new {
    my $class = shift;
    my $fh = shift;
    my $self = { _fh => $fh };
    bless $self, $class;
    return $self;
}
sub _set_xml_writer {
    my $self     = shift;
    my $filename = shift;
    my $fh = IO::File->new( $filename, 'w' );
    croak "Couldn't open file $filename for writing.\n" unless $fh;
    binmode $fh, ':utf8';
    $self->{_fh} = $fh;
}
sub xml_declaration {
    my $self = shift;
    local $\ = undef;
    print { $self->{_fh} }
      qq(<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n);
}
sub xml_start_tag {
    my $self = shift;
    my $tag  = shift;
    while ( @_ ) {
        my $key   = shift @_;
        my $value = shift @_;
        $value = _escape_attributes( $value );
        $tag .= qq( $key="$value");
    }
    local $\ = undef;
    print { $self->{_fh} } "<$tag>";
}
sub xml_start_tag_unencoded {
    my $self = shift;
    my $tag  = shift;
    while ( @_ ) {
        my $key   = shift @_;
        my $value = shift @_;
        $tag .= qq( $key="$value");
    }
    local $\ = undef;
    print { $self->{_fh} } "<$tag>";
}
sub xml_end_tag {
    my $self = shift;
    my $tag  = shift;
    local $\ = undef;
    print { $self->{_fh} } "</$tag>";
}
sub xml_empty_tag {
    my $self = shift;
    my $tag  = shift;
    while ( @_ ) {
        my $key   = shift @_;
        my $value = shift @_;
        $value = _escape_attributes( $value );
        $tag .= qq( $key="$value");
    }
    local $\ = undef;
    print { $self->{_fh} } "<$tag/>";
}
sub xml_empty_tag_unencoded {
    my $self = shift;
    my $tag  = shift;
    while ( @_ ) {
        my $key   = shift @_;
        my $value = shift @_;
        $tag .= qq( $key="$value");
    }
    local $\ = undef;
    print { $self->{_fh} } "<$tag/>";
}
sub xml_data_element {
    my $self    = shift;
    my $tag     = shift;
    my $data    = shift;
    my $end_tag = $tag;
    while ( @_ ) {
        my $key   = shift @_;
        my $value = shift @_;
        $value = _escape_attributes( $value );
        $tag .= qq( $key="$value");
    }
    $data = _escape_data( $data );
    local $\ = undef;
    print { $self->{_fh} } "<$tag>$data</$end_tag>";
}
sub xml_data_element_unencoded {
    my $self    = shift;
    my $tag     = shift;
    my $data    = shift;
    my $end_tag = $tag;
    while ( @_ ) {
        my $key   = shift @_;
        my $value = shift @_;
        $tag .= qq( $key="$value");
    }
    local $\ = undef;
    print { $self->{_fh} } "<$tag>$data</$end_tag>";
}
sub xml_string_element {
    my $self  = shift;
    my $index = shift;
    my $attr  = '';
    while ( @_ ) {
        my $key   = shift;
        my $value = shift;
        $attr .= qq( $key="$value");
    }
    local $\ = undef;
    print { $self->{_fh} } "<c$attr t=\"s\"><v>$index</v></c>";
}
sub xml_si_element {
    my $self   = shift;
    my $string = shift;
    my $attr   = '';
    while ( @_ ) {
        my $key   = shift;
        my $value = shift;
        $attr .= qq( $key="$value");
    }
    $string = _escape_data( $string );
    local $\ = undef;
    print { $self->{_fh} } "<si><t$attr>$string</t></si>";
}
sub xml_rich_si_element {
    my $self   = shift;
    my $string = shift;
    local $\ = undef;
    print { $self->{_fh} } "<si>$string</si>";
}
sub xml_number_element {
    my $self   = shift;
    my $number = shift;
    my $attr   = '';
    while ( @_ ) {
        my $key   = shift;
        my $value = shift;
        $attr .= qq( $key="$value");
    }
    local $\ = undef;
    print { $self->{_fh} } "<c$attr><v>$number</v></c>";
}
sub xml_formula_element {
    my $self    = shift;
    my $formula = shift;
    my $result  = shift;
    my $attr    = '';
    while ( @_ ) {
        my $key   = shift;
        my $value = shift;
        $attr .= qq( $key="$value");
    }
    $formula = _escape_data( $formula );
    local $\ = undef;
    print { $self->{_fh} } "<c$attr><f>$formula</f><v>$result</v></c>";
}
sub xml_inline_string {
    my $self     = shift;
    my $string   = shift;
    my $preserve = shift;
    my $attr     = '';
    my $t_attr   = '';
    $t_attr = ' xml:space="preserve"' if $preserve;
    while ( @_ ) {
        my $key   = shift;
        my $value = shift;
        $attr .= qq( $key="$value");
    }
    $string = _escape_data( $string );
    local $\ = undef;
    print { $self->{_fh} }
      "<c$attr t=\"inlineStr\"><is><t$t_attr>$string</t></is></c>";
}
sub xml_rich_inline_string {
    my $self   = shift;
    my $string = shift;
    my $attr   = '';
    while ( @_ ) {
        my $key   = shift;
        my $value = shift;
        $attr .= qq( $key="$value");
    }
    local $\ = undef;
    print { $self->{_fh} } "<c$attr t=\"inlineStr\"><is>$string</is></c>";
}
sub xml_get_fh {
    my $self = shift;
    return $self->{_fh};
}
sub _escape_attributes {
    my $str = $_[0];
    return $str if $str !~ m/["&<>\n]/;
    for ( $str ) {
        s/&/&amp;/g;
        s/"/&quot;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
        s/\n/&#xA;/g;
    }
    return $str;
}
sub _escape_data {
    my $str = $_[0];
    return $str if $str !~ m/[&<>]/;
    for ( $str ) {
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
    }
    return $str;
}
1;
