#!/usr/bin/env perl6

use v6;
use Test;

my $fname = 't.xlsx';
END {
    unlink $fname if $fname.IO.f;
}

plan 1;

sub good-run {
    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;
    $p5.run(q'
 
    # this Perl version works
    #!/usr/bin/env perl
    use strict;
    use warnings;
    use lib <t/lib>;
    use Excel::Writer::XLSX;
    my $fname = "t.xlsx";
    my $wb  = Excel::Writer::XLSX->new($fname);
    my $fmt = $wb->add_format;
    $fmt->set_size(15);
    $fmt->set_font("Times New Roman");
    my $ws = $wb->add_worksheet;
    $ws->set_column(0, 0, 40);
    $ws->write(0, 0, "BOLD Times New Roman", $fmt);
    $wb->close;

    ');
}

lives-ok &good-run, "Runs okay as expected";

done-testing;

# vim: ft=perl6
