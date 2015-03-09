use Inline::Perl5;

my $p5 = Inline::Perl5.new;

$p5.run(q/
    use 5.14.0;
    sub foo {
        my ($handle) = @_;
        print { *$handle } "1..1\n";
    }
/);

$p5.call("foo", $*OUT);
say "ok - 1";

# vim: ft=perl6
