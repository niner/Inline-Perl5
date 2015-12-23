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

        my %vars = get-vars($dir);
        %vars<p5helper> = $*VM.platform-library-name('p5helper'.IO);
        mkdir "$dir/resources" unless "$dir/resources".IO.e;
        mkdir "$dir/resources/libraries" unless "$dir/resources/libraries".IO.e;
        process-makefile($dir, %vars);
        my $goback = $*CWD;
        chdir($dir);
        shell(%vars<MAKE>);
        chdir($goback);
    }
}

# vim: ft=perl6
