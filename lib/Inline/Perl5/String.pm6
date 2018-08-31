use NativeCall;
use Inline::Perl5::Interpreter;

class Inline::Perl5::String does Stringy {
    has Inline::Perl5::Interpreter $!p5;
    has Pointer $.sv;
    has Str $!decoded;
    submethod BUILD(:$!p5, :$!sv) {
        $!p5.p5_sv_refcnt_inc($!sv);
    }
    method gist() {
        $.Str
    }
    method Str() {
        $!decoded //= $!p5.p5_sv_to_char_star($!sv);
    }
    method Bool() {
        ?$.Str
    }
}
