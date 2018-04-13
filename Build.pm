use v6;
use LibraryMake;

class Build {
    method build($dir) {
        run('perl', '-e', 'use v5.18;')
            or die "\nPerl 5 version requirement not met\n";

        run('perl', '-MFilter::Simple', '-e', '')
            or die "\nPlease install the Filter::Simple Perl 5 module!\n";

        my %vars = get-vars($dir);
        %vars<p5helper> = %vars<DESTDIR>.IO.child('resources').child('libraries')
            .child($*VM.platform-library-name('p5helper'.IO)).Str;
        %vars<perlopts> = run(<perl -MExtUtils::Embed -e ccopts -e ldopts>, :out).out.lines.join('');
        mkdir "$dir/resources" unless "$dir/resources".IO.e;
        mkdir "$dir/resources/libraries" unless "$dir/resources/libraries".IO.e;
        process-makefile($dir, %vars);
        my $goback = $*CWD;
        chdir($dir);
        shell(%vars<MAKE>);
        chdir($goback);
    }

    # only needed for older versions of panda
    method isa($what) {
        return True if $what.^name eq 'Panda::Builder';
        callsame;
    }
}

# vim: ft=perl6
