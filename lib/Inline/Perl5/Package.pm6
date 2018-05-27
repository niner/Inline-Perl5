my constant @pass_through_methods = eager |Any.^methods>>.name.grep(/^\w+$/), |<note print put say split>;
role Inline::Perl5::Package[$p5, Str $module] {
    has $!parent;

    method new(*@args, *%args) {
        if (self.^name ne $module) { # subclass
            %args<parent> = $p5.invoke($module, 'new', |@args, |%args.kv).unwrap-perl5-object;
            my $self = self.CREATE;
            $self.BUILDALL(@args, %args);
            return $self;
        }
        else {
            return $p5.invoke($module, 'new', |@args.list, |%args.hash);
        }
    }

    submethod BUILD(:$parent) {
        $!parent = $parent;
        $p5.rebless($parent, 'Perl6::Object', self) if $parent;
    }

    method unwrap-perl5-object() {
        $!parent;
    }

    multi method FALLBACK($name, *@args, *%kwargs) {
        return self.defined
            ?? $p5.invoke-parent($module, $!parent.ptr, False, $name, [flat $!parent, |@args], %kwargs)
            !! $p5.invoke($module, $name, |@args.list, |%kwargs);
    }

    for @pass_through_methods -> $name {
        next if $?CLASS.^declares_method($name);
        my $method = method (|args) {
            return self.defined
                ?? $p5.invoke-parent($module, $!parent.ptr, False, $name, [flat $!parent, args.list], args.hash.item)
                !! $p5.invoke($module, $name, args.list, args.hash);
        };
        $method.set_name($name);
        $?CLASS.^add_method(
            $name,
            $method,
        );
    }
}
