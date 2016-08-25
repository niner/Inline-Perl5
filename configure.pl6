#!/usr/bin/env perl6
use v6;

sub MAIN(:$test, :$install is copy) {
    configure();
    test() or $install = False if $test;
    install() if $install;
}

sub configure() {
    shell('perl -e "use v5.18;"')
        or die "\nPerl 5 version requirement not met\n";

    shell('perl -MFilter::Simple -e ""')
        or die "\nPlease install the Filter::Simple Perl 5 module!\n";

    my %vars;
    %vars<CC> = $*VM.config<cc>;
    %vars<p5helper> = p5helper().Str;
    %vars<perlopts> = run(<perl -MExtUtils::Embed -e ccopts -e ldopts>, :out).out.lines.join('');
    %vars<perl6> = $*EXECUTABLE;
    mkdir "resources" unless "resources".IO.e;
    mkdir "resources/libraries" unless "resources/libraries".IO.e;
    my $makefile = slurp('Makefile.in');
    for %vars.kv -> $k, $v {
        $makefile ~~ s:g/\%$k\%/$v/;
    }
    spurt('Makefile', $makefile);
}

sub test() {
    run($*VM.config<make>, 'test').exitcode == 0
}

sub install() {
    my $repo = $*REPO.repo-chain.grep(CompUnit::Repository::Installable).first(*.can-install)
        or die "Cannot find a repository to install to";
    my $dist = Distribution::Path.new($*CWD, :file('META.info'.IO));

    # workaround for missing proper handling of libraries in Distribution::Path
    my $p5helper = p5helper;
    $dist.meta<files> = (
        |$dist.meta<files>.grep(* ne $p5helper.Str),
        {'resources/libraries/p5helper' => $p5helper},
    );

    $repo.install($dist);
    say "Installed successfully.";
}

sub p5helper() {
    'resources'.IO.child('libraries').child($*VM.platform-library-name('p5helper'.IO))
}

# vim: ft=perl6
