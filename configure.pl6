#!/usr/bin/env perl6
use v6;

sub MAIN(:$test, :$install is copy) {
    configure();
    test() or $install = False if $test;
    install() if $install;
}

sub get_cc() {
    if $*DISTRO.is-win {
        my $cc = $*VM.config<cc> // $*VM.config<nativecall.cc> // 'cc';
        my $result = run $cc, "--version", :out;
        if  $result.exitcode != 0 {
            my $result2 = run "perl", "--version", :out;
            if $result2.exitcode != 0 {
                die "perl not found. Please install perl first.";
            }
            my $result3 = run "perl", "-MConfig", "-e", 'print $Config{cc}', :out;
            if $result3.exitcode == 0 {
                $cc = $result3.out.get;
            }
        }
        return $cc;
    }
    else {
        return $*VM.config<cc> // $*VM.config<nativecall.cc> // 'cc';
    }
}

sub configure() {
    run('perl', '-e', 'use v5.20;')
        or die "\nPerl 5 version requirement not met\n";

    run('perl', '-MFilter::Simple', '-e', '1')
        or die "\nPlease install the Filter::Simple Perl 5 module!\n";

    my %vars;
    #%vars<CC> = $*VM.config<cc> // $*VM.config<nativecall.cc> // 'cc';
    %vars<CC> = get_cc();
    %vars<p5helper> = p5helper().Str;
    %vars<perlopts> = run(<perl -MExtUtils::Embed -e ccopts -e ldopts>, :out).out.lines.join('');
    %vars<EXECUTABLE> = $*EXECUTABLE;
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
    my $repo = %*ENV<DESTREPO>
        ?? CompUnit::RepositoryRegistry.repository-for-name(%*ENV<DESTREPO>)
        !! (
            CompUnit::RepositoryRegistry.repository-for-name('site'),
            |$*REPO.repo-chain.grep(CompUnit::Repository::Installable)
        ).first(*.can-install)
        or die "Cannot find a repository to install to";
    say "Installing into $repo";
    my $dist = Distribution::Path.new($*CWD);

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
