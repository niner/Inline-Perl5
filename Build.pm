use v6;
use Panda::Common;
use Panda::Builder;
use Shell::Command;
use LibraryMake;

class Build is Panda::Builder {
    method build($dir) {
        my Str $blib = "$dir/blib";
        rm_f("$dir/lib/Inline/p5helper.so");
        rm_rf($blib);
        mkpath("$blib/lib/Inline");
        make($dir, "$blib/lib");
    }
}

# vim: ft=perl6
