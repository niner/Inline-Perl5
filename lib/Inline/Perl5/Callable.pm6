use NativeCall;

class Inline::Perl5::Callable does Callable {
    has Pointer $.ptr;
    has $.perl5; # Inline::Perl5 is circular

    method CALL-ME(*@args) {
        $.perl5.execute($.ptr, @args);
    }

    submethod DESTROY {
        $!perl5.sv_refcnt_dec($!ptr) if $!ptr;
        $!ptr = Pointer;
    }
}

