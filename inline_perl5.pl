#!/home/nine/install/rakudo/install/bin/perl6

use v6;
use NativeCall;

class PerlInterpreter is repr('CPointer') {
    sub Perl_SvIOK(PerlInterpreter, OpaquePointer)
        is native("%*ENV<HOME>/interop/p5helper.so")
        returns Int { * }
    sub Perl_sv_iv(PerlInterpreter, OpaquePointer)
        is native('/usr/lib/perl5/5.18.1/x86_64-linux-thread-multi/CORE/libperl.so')
        returns Int { * }
    sub Perl_eval_pv(PerlInterpreter, Str, Int)
        is native('/usr/lib/perl5/5.18.1/x86_64-linux-thread-multi/CORE/libperl.so')
        returns OpaquePointer { * }

    method run($perl) returns Int {
        my $res = Perl_eval_pv(self, $perl, 1);
        return Perl_SvIOK(self, $res) ?? Perl_sv_iv(self, $res) !! $res;
    }
}

sub init_perl() is native("%*ENV<HOME>/interop/p5helper.so") returns PerlInterpreter { * }

my $i = init_perl();
say $i.run('
$| = 1;
print "Hello world from Perl ";
5');

# vim: ft=perl6
