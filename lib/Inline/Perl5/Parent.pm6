use Inline::Perl5::Caller;

role Inline::Perl5::Parent[Str:D $package, $perl5] {
    has $!parent;

    method new(:$parent?, *@args, *%args) {
        self.CREATE.initialize-perl5-object($parent, @args, %args).BUILDALL(@args, %args);
    }

    method initialize-perl5-object($parent, @args, %args) {
        $!parent = $parent // $perl5.invoke($package, 'new', |@args, |%args.kv);
        $perl5.rebless($!parent, "Perl6::Object::$package", self);
        return self;
    }

    method unwrap-perl5-object() {
        $!parent;
    }

    method sink() { self }

    method can($name) {
        my @candidates = self.^can($name);
        return @candidates[0] if @candidates;
        return defined(self)
            ?? $perl5.invoke-parent($package, $!parent.ptr, True, 'can', [$!parent, $name], Map)
            !! $perl5.invoke($package, 'can', $name);
    }

    ::?CLASS.HOW.add_fallback(::?CLASS, -> $, $ { True },
        method ($name) {
            -> \self, |args {
                my $scalar = (
                    callframe(1).code ~~ Inline::Perl5::Caller
                    and $perl5.retrieve_scalar_context
                );
                my $parent = self.unwrap-perl5-object;
                $perl5.invoke-parent($package, $parent.ptr, $scalar, $name, [flat $parent, args.list], args.hash);
            }
        }
    );
}
