use NativeCall;

class Inline::Perl5::TypeGlob {
    has $!ip5; # Had to remove the Inline::Perl5 type to prevent circular dep
    has Pointer $.gv;
    method BUILD(:$!ip5 is raw, :$!gv is raw) {
    }
    submethod DESTROY() {
        $!ip5.sv_refcnt_dec($!gv);
    }
    multi method gist(Inline::Perl5::TypeGlob:D:) {
        'Perl 5 type glob'
    }
}
