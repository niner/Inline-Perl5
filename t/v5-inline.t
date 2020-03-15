BEGIN {
    say "1..7";
}
{
    use v5-inline;
    use v5.10.0;
    $| = 1;
    BEGIN { say "ok 1 - First message from Perl 5"; }
    if (1) {
        say "ok 2 - Conditional message from Perl 5";
    }
    raku {
        say "ok 3 - Message from Raku";
        $*OUT.flush;
        if True {
            say "ok 4 - Conditional message from Raku";
            $*OUT.flush;
        }
        {
            use v5-inline;
            use v5.10.0;
            say "ok 5 - Message from Perl 5 from Raku";
        }
    }
    say "ok 6 - Last message from Perl 5";

    sub give_me_a_string {
        "a string"
    }
    warn "foo";
}

if True {
    say "ok 7 - Still alive";
    $*OUT.flush;
}

#say give_me_a_string() eq "a string"
#    ?? "ok 8 - sub in v5-inline block found"
#    !! "not ok 8 - sub in v5-inline block not found";
