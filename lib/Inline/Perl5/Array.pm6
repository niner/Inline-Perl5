use NativeCall;
use Inline::Perl5::Interpreter;

class Inline::Perl5::Array does Iterable does Positional {
    has $!ip5; # Had to remove the Inline::Perl5 type to prevent circular dep
    has Inline::Perl5::Interpreter $!p5;
    has Pointer $.av;
    method new(:$ip5 is raw, :$p5 is raw, :$av is raw) {
        my \arr = self.CREATE;
        arr.BUILD(:$ip5, :$p5, :$av);
        arr
    }
    submethod BUILD(:$!ip5 is raw, :$!p5 is raw, :$!av is raw) {
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
    method Capture() {
        self.Array.Capture
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
        my int32 $elems = $!p5.p5_av_top_index($!av) + 1
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
    method pop(Inline::Perl5::Array:D:) {
        $!ip5.p5_to_p6($!p5.p5_av_pop($!av));
    }
    method push(Inline::Perl5::Array:D: Mu \val --> Nil) {
        $!p5.p5_av_push($!av, $!ip5.p6_to_p5(val));
    }
    method shift(Inline::Perl5::Array:D:) {
        $!ip5.p5_to_p6($!p5.p5_av_shift($!av));
    }
    method unshift(Inline::Perl5::Array:D: Mu \val --> Nil) {
        $!p5.p5_av_unshift($!av, $!ip5.p6_to_p5(val));
    }
    multi method splice(Inline::Perl5::Array:D:) {
        my $retval = self.Array;
        $!p5.p5_av_clear($!av);
        $retval
    }
    multi method splice(Inline::Perl5::Array:D: Int:D $offset) {
        my @retval;
        my $size = self.elems - $offset;
        @retval[$size - 1 - $++] = self.pop for ^$size;
        @retval
    }
    multi method splice(Inline::Perl5::Array:D: Int:D $offset, Int:D $size) {
        my @retval;
        my $elems = self.elems;
        for ^$size -> $i {
            @retval[$i] = self.AT-POS($offset + $i);
            $!p5.p5_av_delete($!av, $offset + $i);
        }
        for ($offset + $size)..$elems {
            self.ASSIGN-POS($_ - $size, self.AT-POS($_));
        }
        # truncate array to new size
        for ($elems...($elems - $size)) {
            $!p5.p5_av_delete($!av, $_);
        }
        @retval
    }
    multi method splice(Inline::Perl5::Array:D: Int:D $offset, Int:D $size, @new) {
        my @retval;
        my $elems = self.elems;
        for ^$size -> $i {
            @retval[$i] = self.AT-POS($offset + $i);
            $!p5.p5_av_delete($!av, $offset + $i);
        }
        if @new.elems < $size {
            for @new {
                self.ASSIGN-POS($offset + $++, $_);
            }
            for ($offset + $size)..$elems {
                self.ASSIGN-POS($_ - $size + @new.elems, self.AT-POS($_));
            }
            # truncate array to new size
            for ($elems...($elems - $size + 1)) {
                $!p5.p5_av_delete($!av, $_);
            }
        }
        else {
            if $elems > $offset + $size {
                for ($elems - 1)...($offset + $size) {
                    self.ASSIGN-POS($_ + @new.elems - $size, self.AT-POS($_));
                }
            }
            for @new.pairs {
                self.ASSIGN-POS($offset + $_.key, $_.value);
            }
        }
        @retval
    }
}
