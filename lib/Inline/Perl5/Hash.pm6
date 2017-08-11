use NativeCall;
use Inline::Perl5::Interpreter;

class Inline::Perl5::Hash does Iterable does Associative {
    has $!ip5; # Inline::Perl5 type removed to avoid circle
    has Inline::Perl5::Interpreter $!p5;
    has Pointer $.hv;

    my constant $encoding-registry = try ::("Encoding::Registry");
    my constant $utf8-encoder = $encoding-registry.^can('find')
        ?? $encoding-registry.find('utf8').encoder(:!replacement, :!translate-nl) # on 6.d
        !! class { method encode-chars($str) { $str.encode } }.new; # fallback for 6.c

    method new(:$ip5, :$p5, :$hv) {
        my \hash = self.CREATE;
        hash.BUILD(:$ip5, :$p5, :$hv);
        hash
    }
    submethod BUILD(:$!ip5, :$!p5, :$!hv) {
        $!p5.p5_sv_refcnt_inc($!hv);
    }
    submethod DESTROY() {
        $!ip5.sv_refcnt_dec($!hv);
    }
    method ASSIGN-KEY(Inline::Perl5::Hash:D: Str() \key, Mu \assignval) is raw {
        $!p5.p5_hv_store($!hv, key, $!ip5.p6_to_p5(assignval));
        assignval
    }
    method AT-KEY(Inline::Perl5::Hash:D: Str() \key) is raw {
        my $buf = $utf8-encoder.encode-chars(key);
        $!ip5.p5_to_p6($!p5.p5_hv_fetch($!hv, $buf.elems, $buf))
    }
    method EXISTS-KEY(Inline::Perl5::Hash:D: Str() \key) {
        my $buf = $utf8-encoder.encode-chars(key);
        $!p5.p5_hv_exists($!hv, $buf.elems, $buf)
    }
    method Hash() {
        my int32 $len = $!p5.p5_hv_iterinit($!hv);

        my $hash = {};

        for 0 .. $len - 1 {
            my Pointer $next = $!p5.p5_hv_iternext($!hv);
            my Pointer $key = $!p5.p5_hv_iterkeysv($next);
            die 'Hash entry without key!?' unless $key;
            my Str $p6_key = $!p5.p5_sv_to_char_star($key);
            my $val = $!ip5.p5_to_p6($!p5.p5_hv_iterval($!hv, $next));
            $hash{$p6_key} = $val;
        }

        $hash
    }
    method iterator() {
        self.Hash.iterator
    }
    method list() {
        self.Hash.list
    }
    method keys() {
        self.Hash.keys
    }
    method values() {
        self.Hash.values
    }
    method pairs() {
        self.Hash.pairs
    }
    method antipairs() {
        self.Hash.antipairs
    }
    method invert() {
        self.Hash.invert
    }
    method kv() {
        self.Hash.kv
    }
    method elems() {
        self.Hash.elems
    }
    method Int() {
        self.elems
    }
    method Numeric() {
        self.elems
    }
    method Bool() {
        self.Hash.Bool
    }
    method Capture() {
        self.Hash.Capture
    }
    method push(*@new) {
        self.Hash.push(|@new)
    }
    method append(+@values) {
        self.Hash.append(|@values)
    }
    multi method gist(Inline::Perl5::Hash:D:) {
        self.Hash.gist
    }
    multi method perl(Inline::Perl5::Hash:D:) {
        self.Hash.perl
    }
    multi method Str(Inline::Perl5::Hash:D:) {
        self.Hash.Str
    }
}
