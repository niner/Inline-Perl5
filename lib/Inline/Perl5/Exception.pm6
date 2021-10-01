unit class Inline::Perl5::Exception is Exception;

has $.payload;

multi method gist(Inline::Perl5::Exception:D:) {
    $.payload.gist
}

multi method Str(Inline::Perl5::Exception:D:) {
    $.payload.Str()
}
