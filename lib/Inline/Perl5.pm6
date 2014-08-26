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
    sub p5_sv_to_char_star(PerlInterpreter, OpaquePointer)
        is native($p5helper)
        returns Str { * }
    sub p5_int_to_sv(PerlInterpreter, Int)
        is native($p5helper)
        returns OpaquePointer { * }
    sub p5_str_to_sv(PerlInterpreter, Str)
        is native($p5helper)
        returns OpaquePointer { * }
    sub p5_av_top_index(PerlInterpreter, OpaquePointer)
        is native($p5helper)
        returns Int { * }
    sub p5_av_fetch(PerlInterpreter, OpaquePointer, Int)
        is native($p5helper)
        returns OpaquePointer { * }
    sub p5_call_function(PerlInterpreter, Str, Int, CArray[OpaquePointer])
        is native($p5helper)
        returns OpaquePointer { * }
    sub p5_destruct_perl(PerlInterpreter)
        is native($p5helper)
        { * }
    sub Perl_sv_iv(PerlInterpreter, OpaquePointer)
        is native('/usr/lib/perl5/5.18.1/x86_64-linux-thread-multi/CORE/libperl.so')
        returns Int { * }
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

    method p5_to_p6(OpaquePointer $value) {
        if p5_SvIOK(self, $value) {
            return Perl_sv_iv(self, $value);
        }
        elsif p5_SvPOK(self, $value) {
            return p5_sv_to_char_star(self, $value);
        }
        die "Unsupported type in p5_to_p6";
    }

    method run($perl) {
        my $res = Perl_eval_pv(self, $perl, 1);
        return self.p5_to_p6($res);
    }

    method call(Str $function, *@args) {
        my $len = @args.elems;
        my @svs := CArray[OpaquePointer].new();
        loop (my $i = 0; $i < $len; $i++) {
            @svs[$i] = self.p6_to_p5(@args[$i]);
        }

        my $av = p5_call_function(self, $function, $len, @svs);
        my $av_len = p5_av_top_index(self, $av);
        my @retvals;
        loop ($i = 0; $i <= $av_len; $i++) {
            @retvals.push(self.p5_to_p6(p5_av_fetch(self, $av, $i)));
        }
        return @retvals;
    }

    submethod DESTROY {
        p5_destruct_perl(self);
    }
}

sub p5_init_perl() is export is native($p5helper) returns PerlInterpreter { * }
