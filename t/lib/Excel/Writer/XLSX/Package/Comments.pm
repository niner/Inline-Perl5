package Excel::Writer::XLSX::Package::Comments;
use 5.008002;
use strict;
use warnings;
use Carp;
use Excel::Writer::XLSX::Package::XMLwriter;
use Excel::Writer::XLSX::Utility qw(xl_rowcol_to_cell);
our @ISA     = qw(Excel::Writer::XLSX::Package::XMLwriter);
our $VERSION = '1.03';
sub new {
    my $class = shift;
    my $fh    = shift;
    my $self  = Excel::Writer::XLSX::Package::XMLwriter->new( $fh );
    $self->{_author_ids} = {};
    bless $self, $class;
    return $self;
}
sub _assemble_xml_file {
    my $self          = shift;
    my $comments_data = shift;
    $self->xml_declaration;
    $self->_write_comments();
    $self->_write_authors( $comments_data );
    $self->_write_comment_list( $comments_data );
    $self->xml_end_tag( 'comments' );
    $self->xml_get_fh()->close();
}
sub _write_comments {
    my $self  = shift;
    my $xmlns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
    my @attributes = ( 'xmlns' => $xmlns );
    $self->xml_start_tag( 'comments', @attributes );
}
sub _write_authors {
    my $self         = shift;
    my $comment_data = shift;
    my $author_count = 0;
    $self->xml_start_tag( 'authors' );
    for my $comment ( @$comment_data ) {
        my $author = $comment->[3];
        if ( defined $author && !exists $self->{_author_ids}->{$author} ) {
            $self->{_author_ids}->{$author} = $author_count++;
            $self->_write_author( $author );
        }
    }
    $self->xml_end_tag( 'authors' );
}
sub _write_author {
    my $self = shift;
    my $data = shift;
    $self->xml_data_element( 'author', $data );
}
sub _write_comment_list {
    my $self         = shift;
    my $comment_data = shift;
    $self->xml_start_tag( 'commentList' );
    for my $comment ( @$comment_data ) {
        my $row         = $comment->[0];
        my $col         = $comment->[1];
        my $text        = $comment->[2];
        my $author      = $comment->[3];
        my $font_name   = $comment->[6];
        my $font_size   = $comment->[7];
        my $font_family = $comment->[8];
        my $author_id = undef;
        $author_id = $self->{_author_ids}->{$author} if defined $author;
        my $font = [ $font_name, $font_size, $font_family ];
        $self->_write_comment( $row, $col, $text, $author_id, $font );
    }
    $self->xml_end_tag( 'commentList' );
}
sub _write_comment {
    my $self      = shift;
    my $row       = shift;
    my $col       = shift;
    my $text      = shift;
    my $author_id = shift;
    my $ref       = xl_rowcol_to_cell( $row, $col );
    my $font      = shift;
    my @attributes = ( 'ref' => $ref );
    push @attributes, ( 'authorId' => $author_id ) if defined $author_id;
    $self->xml_start_tag( 'comment', @attributes );
    $self->_write_text( $text, $font );
    $self->xml_end_tag( 'comment' );
}
sub _write_text {
    my $self = shift;
    my $text = shift;
    my $font = shift;
    $self->xml_start_tag( 'text' );
    $self->_write_text_r( $text, $font );
    $self->xml_end_tag( 'text' );
}
sub _write_text_r {
    my $self = shift;
    my $text = shift;
    my $font = shift;
    $self->xml_start_tag( 'r' );
    $self->_write_r_pr($font);
    $self->_write_text_t( $text );
    $self->xml_end_tag( 'r' );
}
sub _write_text_t {
    my $self = shift;
    my $text = shift;
    my @attributes = ();
    if ( $text =~ /^\s/ || $text =~ /\s$/ ) {
        push @attributes, ( 'xml:space' => 'preserve' );
    }
    $self->xml_data_element( 't', $text, @attributes );
}
sub _write_r_pr {
    my $self = shift;
    my $font = shift;
    $self->xml_start_tag( 'rPr' );
    $self->_write_sz($font->[1]);
    $self->_write_color();
    $self->_write_r_font($font->[0]);
    $self->_write_family($font->[2]);
    $self->xml_end_tag( 'rPr' );
}
sub _write_sz {
    my $self = shift;
    my $val  = shift;
    my @attributes = ( 'val' => $val );
    $self->xml_empty_tag( 'sz', @attributes );
}
sub _write_color {
    my $self    = shift;
    my $indexed = 81;
    my @attributes = ( 'indexed' => $indexed );
    $self->xml_empty_tag( 'color', @attributes );
}
sub _write_r_font {
    my $self = shift;
    my $val  = shift;
    my @attributes = ( 'val' => $val );
    $self->xml_empty_tag( 'rFont', @attributes );
}
sub _write_family {
    my $self = shift;
    my $val  = shift;
    my @attributes = ( 'val' => $val );
    $self->xml_empty_tag( 'family', @attributes );
}
1;
