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
    sub p5_int_to_sv(PerlInterpreter, Int)
        is native($p5helper)
        returns OpaquePointer { * }
    sub p5_str_to_sv(PerlInterpreter, Str)
        is native($p5helper)
        returns OpaquePointer { * }
    sub p5_call_function(PerlInterpreter, Str, Int, CArray[OpaquePointer])
        is native($p5helper)
        { * }
    sub p5_destruct_perl(PerlInterpreter)
        is native($p5helper)
        { * }
    sub Perl_eval_pv(PerlInterpreter, Str, Int)
        is native('/usr/lib/perl5/5.18.1/x86_64-linux-thread-multi/CORE/libperl.so')
        returns OpaquePointer { * }
    sub Perl_call_pv(PerlInterpreter, Str, Int)
        is native('/usr/lib/perl5/5.18.1/x86_64-linux-thread-multi/CORE/libperl.so')
        returns OpaquePointer { * }

    multi method p6_to_p5(Int $value) returns OpaquePointer {
        return p5_int_to_sv(self, $value);
    }
    multi method p6_to_p5(Str $value) returns OpaquePointer {
        return p5_str_to_sv(self, $value);
    }

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

    method call(Str $function, *@args) {
        my $len = @args.elems;
        my @svs := CArray[OpaquePointer].new();
        loop (my $i = 0; $i < $len; $i++) {
            @svs[$i] = self.p6_to_p5(@args[$i]);
        }

        p5_call_function(self, $function, $len, @svs);
    }

    submethod DESTROY {
        p5_destruct_perl(self);
    }
}

sub p5_init_perl() is export is native($p5helper) returns PerlInterpreter { * }
