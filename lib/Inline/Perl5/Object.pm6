use NativeCall;

my constant @pass_through_methods = |Any.^methods>>.name.grep(/^\w+$/), |<note print put say split>;

class Inline::Perl5::Object {
    has Pointer $.ptr is rw;
    has $.perl5;

    method sink() { self }

    method can($name) {
        my @candidates = self.^can($name);
        return @candidates[0] if @candidates;
        return $!perl5.invoke($!ptr, 'can', $name);
    }

    method Str() {
        my $stringify = $!perl5.call('overload::Method', self, '""');
        return $stringify ?? $stringify(self) !! callsame;
    }

    submethod DESTROY {
        $!perl5.sv_refcnt_dec($!ptr) if $!ptr;
        $!ptr = Pointer;
    }
}

BEGIN {
    Inline::Perl5::Object.^add_fallback(-> $, $ { True },
        method ($name) {
            -> \self, |args {
                args
                    ?? $.perl5.invoke-args($.ptr, $name, args)
                    !! $.perl5.invoke($.ptr, $name);
            }
        }
    );
    for @pass_through_methods -> $name {
        next if Inline::Perl5::Object.^declares_method($name);
        Inline::Perl5::Object.^add_method(
            $name,
            method (|args) {
                args
                    ?? $.perl5.invoke-args($.ptr, $name, args)
                    !! $.perl5.invoke($.ptr, $name);
            }
        );
    }
    Inline::Perl5::Object.^compose;
}
