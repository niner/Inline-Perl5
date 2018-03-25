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

    method Numeric() {
        my $numify = $!perl5.call('overload::Method', self, '0+');
        return $numify ?? $numify(self) !! callsame;
    }

    submethod DESTROY {
        $!perl5.sv_refcnt_dec($!ptr) if $!ptr;
        $!ptr = Pointer;
    }

    method FALLBACK($name, *@args, *%kwargs) {
        my $role := Metamodel::ParametricRoleHOW.new_type;
        my $gv := $!perl5.look-up-method($!ptr, $name)
            or die qq/Could not find method "$name" of "{$!perl5.stash-name($!ptr)}" object/;
        $role.^add_multi_method($name, method () {
            %_
                ?? $!perl5.invoke-gv-args($!ptr, $gv, Capture.new(:hash(%_)))
                !! $!perl5.invoke($!ptr, $gv)
        });
        $role.^add_multi_method($name, method (\arg) {
            %_
                ?? $!perl5.invoke-gv-args($!ptr, $gv, Capture.new(:list([arg]), :hash(%_)))
                !! $!perl5.invoke-gv-arg($!ptr, $gv, arg)
        });
        $role.^add_multi_method($name, method (|args) {
            $!perl5.invoke-gv-args($!ptr, $gv, args)
        });
        $role.^set_body_block(-> |args {});
        $role.^compose;
        self does $role;

        @args.elems || %kwargs.elems
            ?? $!perl5.invoke-gv-args($!ptr, $gv, Capture.new(:list(@args), :hash(%kwargs)))
            !! $!perl5.invoke($!ptr, $gv);
    }
}

BEGIN {
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
