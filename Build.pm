use v6;
use Panda::Common;
use Panda::Builder;
use Shell::Command;
use LibraryMake;

class Build is Panda::Builder {
    method build($dir) {
        shell('perl -e "use v5.18;"')
            or die "\nPerl 5 version requirement not met\n";

        shell('perl -MFilter::Simple -e ""')
            or die "\nPlease install the Filter::Simple Perl 5 module!\n";

        my Str $blib = "$dir/blib";
        rm_rf($blib);
        mkpath("$blib/lib/Inline");
        mkpath("$blib/lib/../resources");
        make($dir, "$blib/lib");
    }
}

# vim: ft=perl6
