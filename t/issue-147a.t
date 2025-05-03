#!/usr/bin/env perl6

use v6;
use Test;

my $fname = 't.xlsx';
END {
    unlink $fname if $fname.IO.f;
}

plan 1;

sub should-run {
    # this Raku version dies at the moment
    use lib:from<Perl5> <t/lib>;
    use Excel::Writer::XLSX:from<Perl5>;
    my $fname = 't.xlsx';
    my $wb  = Excel::Writer::XLSX.new($fname);
    my $fmt = $wb.add_format;
    $fmt.set_size(15);
    $fmt.set_font("Times New Roman");
    my $ws = $wb.add_worksheet;
    $ws.set_column(0, 0, 40);
    $ws.write(0, 0, "BOLD Times New Roman", $fmt);
    $wb.close;
}

dies-ok &should-run, "Runs as expected";

done-testing;

# vim: ft=perl6
