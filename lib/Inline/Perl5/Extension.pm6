use Inline::Perl5::Attributes;
use Inline::Perl5::Caller;
use Inline::Perl5::ClassHOW;
use Inline::Perl5::Object;
use NativeCall;

role Inline::Perl5::Extension[Str:D $package, $perl5] {
    has $!target;

    multi method new_shadow_of_p5_object(Inline::Perl5::Object $target) {
        self.CREATE.initialize-perl5-object($target); #.BUILDALL(my @, my %);
        Nil
    }

    multi method new_shadow_of_p5_object($target) {
        self.CREATE.initialize-perl5-object(
            $target.^mro.grep({$_.HOW ~~ Inline::Perl5::ClassHOW})
                ?? Inline::Perl5::Object.new(:ptr($target.wrapped-perl5-object), :$perl5)
                !! $target.unwrap-perl5-object
            ); #.BUILDALL(my @, my %);
        Nil
    }

    method new(*@args, *%args) {
        $perl5.invoke($package, 'new', |@args, |%args.kv)
    }

    method initialize-perl5-object($target) {
        $!target = $target;
        $perl5.p6_to_p5(self, $!target.ptr);
        $perl5.sv_refcnt_dec($!target.ptr); # Was increased by p5_to_p6 but we must not keep $!target alive
        return self;
    }

    method unwrap-perl5-object() {
        $!target;
    }

    submethod DESTROY {
        # Prevent Inline::Perl5::Object.DESTROY from decreasing the refcnt, as we did that
        # already in initialize-perl5-object
        $!target.ptr = Pointer;
    }

    method sink() { self }

    method can($name) {
        my @candidates = self.^can($name);
        return @candidates[0] if @candidates;
        return defined(self)
            ?? $perl5.invoke-parent($package, $!target.ptr, True, 'can', $!target, $name)
            !! $perl5.invoke($package, 'can', $name);
    }

    for ::?CLASS.^attributes.grep(*.has_accessor) -> $attribute {
        $perl5.install_wrapper_method($package, $attribute.name.substr(2));
    }

    for ::?CLASS.^methods -> &method {
        &method.does(Inline::Perl5::Attributes)
            ?? $perl5.install_wrapper_method($package, &method.name, |&method.attributes)
            !! $perl5.install_wrapper_method($package, &method.name);
    }

    ::?CLASS.HOW.add_fallback(::?CLASS, -> $, $ { True },
        method ($name) {
            -> \self, |args {
                my $scalar = (
                    callframe(1).code ~~ Inline::Perl5::Caller
                    and $perl5.retrieve_scalar_context
                );
                my $target = self.unwrap-perl5-object;
                $perl5.invoke-parent($package, $target.ptr, $scalar, $name, [flat $target, args.list], args.hash);
            }
        }
    );
}
