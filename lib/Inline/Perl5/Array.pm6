use NativeCall;
use Inline::Perl5::Interpreter;

class Inline::Perl5::Array does Iterable does Positional {
    has $!ip5; # Had to remove the Inline::Perl5 type to prevent circular dep
    has Inline::Perl5::Interpreter $!p5;
    has Pointer $.av;
    method new(:$ip5, :$p5, :$av) {
        my \arr = self.CREATE;
        arr.BUILD(:$ip5, :$p5, :$av);
        arr
    }
    submethod BUILD(:$!ip5, :$!p5, :$!av) {
    }
    submethod DESTROY() {
        $!ip5.sv_refcnt_dec($!av);
    }
    method ASSIGN-POS(Inline::Perl5::Array:D: Int() \pos, Mu \assignval) is raw {
        $!p5.p5_av_store($!av, pos, $!ip5.p6_to_p5(assignval));
        assignval
    }
    method AT-POS(Inline::Perl5::Array:D: Int() \pos) is raw {
        $!ip5.p5_to_p6($!p5.p5_av_fetch($!av, pos))
    }
    method EXISTS-POS(Inline::Perl5::Array:D: Int() \pos) {
        0 <= pos <= $!p5.p5_av_top_index($!av)
    }
    method Array() {
        my int32 $av_len = $!p5.p5_av_top_index($!av);

        my $arr = [];
        loop (my int32 $i = 0; $i <= $av_len; $i = $i + 1) {
            $arr.push($!ip5.p5_to_p6($!p5.p5_av_fetch($!av, $i)));
        }
        $arr
    }
    method iterator() {
        self.Array.iterator
    }
    method list() {
        self.Array.list
    }
    method pairs() {
        self.Array.pairs
    }
    method kv() {
        self.Array.kv
    }
    method elems() {
        $!p5.p5_av_top_index($!av) + 1
    }
    method Numeric() {
        self.elems
    }
    method Bool() {
        ?($!p5.p5_av_top_index($!av) + 1);
    }
    multi method gist(Inline::Perl5::Array:D:) {
        self.Array.gist
    }
    multi method perl(Inline::Perl5::Array:D:) {
        self.Array.perl
    }
    multi method Str(Inline::Perl5::Array:D:) {
        self.Array.Str
    }
}
