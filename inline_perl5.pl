#!/home/nine/install/rakudo/install/bin/perl6

use v6;
use NativeCall;

class PerlInterpreter is repr('CPointer') {
    sub Perl_SvIOK(PerlInterpreter, OpaquePointer)
        is native("%*ENV<HOME>/interop/p5helper.so")
        returns Int { * }
    sub Perl_SvPOK(PerlInterpreter, OpaquePointer)
        is native("%*ENV<HOME>/interop/p5helper.so")
        returns Int { * }
    sub Perl_sv_iv(PerlInterpreter, OpaquePointer)
        is native('/usr/lib/perl5/5.18.1/x86_64-linux-thread-multi/CORE/libperl.so')
        returns Int { * }
    sub sv_to_char_star(PerlInterpreter, OpaquePointer)
        is native("%*ENV<HOME>/interop/p5helper.so")
        returns Str { * }
    sub Perl_eval_pv(PerlInterpreter, Str, Int)
        is native('/usr/lib/perl5/5.18.1/x86_64-linux-thread-multi/CORE/libperl.so')
        returns OpaquePointer { * }

    method run($perl) {
        my $res = Perl_eval_pv(self, $perl, 1);
        if Perl_SvIOK(self, $res) {
            return Perl_sv_iv(self, $res);
        }
        if Perl_SvPOK(self, $res) {
            return sv_to_char_star(self, $res);
        }
        return $res;
    }
}

sub init_perl() is native("%*ENV<HOME>/interop/p5helper.so") returns PerlInterpreter { * }

my $i = init_perl();
say $i.run('
$| = 1;
print "Hello world from Perl ";
5');

# vim: ft=perl6
