#!/home/nine/install/rakudo/install/bin/perl6

use v6;
use NativeCall;

class PerlInterpreter is repr('CPointer') {
    sub Perl_eval_pv(PerlInterpreter, Str, Int)
        is native('/usr/lib/perl5/5.18.1/x86_64-linux-thread-multi/CORE/libperl.so') { * }

    method run($perl) {
        Perl_eval_pv(self, $perl, 1);
    }
}

sub init_perl() is native("%*ENV<HOME>/interop/p5helper.so") returns PerlInterpreter { * }

my $i = init_perl();
$i.run('print "hello world\n"');

# vim: ft=perl6
