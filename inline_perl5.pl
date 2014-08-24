#!/home/nine/install/rakudo/install/bin/perl6
use v6;
use NativeCall;

    sub perl_sys_init3()
        is native('/home/nine/interop/p5helper.so') { * }
class PerlInterpreter is repr('CPointer') {
    sub perl_construct(PerlInterpreter)
        is native('/usr/lib/perl5/5.18.1/x86_64-linux-thread-multi/CORE/libperl.so') { * }
    sub perl_parse(PerlInterpreter, OpaquePointer, Int, CArray[Str], OpaquePointer)
        is native('/usr/lib/perl5/5.18.1/x86_64-linux-thread-multi/CORE/libperl.so') { * }
    sub perl_run(PerlInterpreter)
        is native('/usr/lib/perl5/5.18.1/x86_64-linux-thread-multi/CORE/libperl.so') { * }
    sub Perl_eval_sv(Str, Int)
        is native('/usr/lib/perl5/5.18.1/x86_64-linux-thread-multi/CORE/libperl.so') { * }
    sub set_perl_exit_flags()
        is native('/home/nine/interop/p5helper.so') { * }
    method init() {
        perl_construct(self);
        my @args := CArray[Str].new();
        @args[0] = '';
        @args[1] = '-e';
        @args[2] = '0';
        perl_parse(self, Any, 3, @args, Any);
        set_perl_exit_flags();
        perl_run(self);
    }
    method run($perl) {
        Perl_eval_sv($perl, 1);
    }
}

sub perl_alloc() is native('/usr/lib/perl5/5.18.1/x86_64-linux-thread-multi/CORE/libperl.so') returns PerlInterpreter { * }

perl_sys_init3();
my $i = perl_alloc();
$i.init();
$i.run('say "hello world"');

say 'test';
