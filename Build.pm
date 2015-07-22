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

        shell(q{perl -MConfig -e '$Config{config_args} =~ /-Duseshrplib/ || exit 1'})
            or die "\nYour perl was not configured to build a shared library; unable to build\n";

        my Str $blib = "$dir/blib";
        rm_f("$dir/lib/Inline/p5helper.so");
        rm_rf($blib);
        mkpath("$blib/lib/Inline");
        make($dir, "$blib/lib");
    }
}

# vim: ft=perl6
