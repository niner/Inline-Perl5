module Inline::Perl5;

use NativeCall;

my Str $p5helper;
BEGIN {
    $p5helper = IO::Path.new($?FILE).directory ~ '/p5helper.so';
}

class PerlInterpreter is repr('CPointer') {
    sub p5_SvIOK(PerlInterpreter, OpaquePointer)
        is native($p5helper)
        returns Int { * }
    sub p5_SvPOK(PerlInterpreter, OpaquePointer)
        is native($p5helper)
        returns Int { * }
    sub Perl_sv_iv(PerlInterpreter, OpaquePointer)
        is native('/usr/lib/perl5/5.18.1/x86_64-linux-thread-multi/CORE/libperl.so')
        returns Int { * }
    sub p5_sv_to_char_star(PerlInterpreter, OpaquePointer)
        is native($p5helper)
        returns Str { * }
    sub Perl_eval_pv(PerlInterpreter, Str, Int)
        is native('/usr/lib/perl5/5.18.1/x86_64-linux-thread-multi/CORE/libperl.so')
        returns OpaquePointer { * }
    sub Perl_call_pv(PerlInterpreter, Str, Int)
        is native('/usr/lib/perl5/5.18.1/x86_64-linux-thread-multi/CORE/libperl.so')
        returns OpaquePointer { * }

    method run($perl) {
        my $res = Perl_eval_pv(self, $perl, 1);
        if p5_SvIOK(self, $res) {
            return Perl_sv_iv(self, $res);
        }
        if p5_SvPOK(self, $res) {
            return p5_sv_to_char_star(self, $res);
        }
        return $res;
    }

    method call(Str $function) {
        Perl_call_pv(self, $function, 4 + 16 + 1);
    }
}

sub p5_init_perl() is export is native($p5helper) returns PerlInterpreter { * }
