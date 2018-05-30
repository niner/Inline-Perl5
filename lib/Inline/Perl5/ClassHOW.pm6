use NativeCall;
class Inline::Perl5::ClassHOW
    does Metamodel::AttributeContainer
    does Metamodel::BaseType
    does Metamodel::MultiMethodContainer
    does Metamodel::Naming
    does Metamodel::REPRComposeProtocol
    does Metamodel::Stashing
{
    has %!cache;
    has $!p5;
    has $!composed;

    my $archetypes := Metamodel::Archetypes.new(
        :nominal(1), :inheritable(1), :augmentable(1) );
    method archetypes() {
        $archetypes
    }

    submethod BUILD(:$!p5) { }

    method new_type(:$name, :$p5) is raw {
        my $how = self.new(:$p5);
        my $type := Metamodel::Primitives.create_type($how);
        $how.set_base_type($type, Any);
        $how.set_name($type, $name);
        $how.add_stash($type);
        $type
    }

    method compose($type) {
        # Set up type checking with cache.
        Metamodel::Primitives.configure_type_checking($type,
            [Any, Mu],
            :authoritative, :call_accepts);

        # Steal methods of Any/Mu for our method cache.
        for flat Any.^method_table.pairs, Mu.^method_table.pairs {
            %!cache{.key} //= .value;
        }
        my $p5 = $!p5;
        my $module = $!name;
        %!cache<new> := my method new(\SELF: *@args, *%args) {
            if (SELF.^name ne $module) { # subclass
                my $self = Metamodel::Primitives.rebless(
                    $p5.invoke($module, 'new', |@args, |%args.kv),
                    SELF.WHAT,
                );
                $p5.rebless($self.wrapped-perl5-object, 'Perl6::Object', $self);
                $self.BUILDALL(@args, %args);
                return $self;
            }
            else {
                return $p5.invoke($module, 'new', |@args.list, |%args.hash);
            }
        };
        Metamodel::Primitives.install_method_cache($type, %!cache, :!authoritative);

        self.add_attribute($type, Attribute.new(
            :name<$!wrapped-perl5-object>,
            :type(Pointer),
            :package($type),
            :has_accessor(1),
        ));

        $!composed = True;
        self.compose_attributes($type);
        self.compose_repr($type);

        $type
    }

    method add_method($type, $name, \meth) is raw {
        %!cache{$name} := meth;
        Metamodel::Primitives.install_method_cache($type, %!cache, :!authoritative)
            if $!composed;
        meth
    }

    method declares_method($type, $name) {
        %!cache{$name}:exists
    }

    method method_table($type) is raw {
        %!cache.FLATTENABLE_HASH
    }

    method submethod_table($type) is raw {
        Map.new.FLATTENABLE_HASH
    }

    method type_check(Mu $, Mu \check) {
        for Any, Mu {
            return True if Metamodel::Primitives.is_type(check, $_);
        }
        return False;
    }

    method accepts_type(Mu $, Mu \check) {
        return False;
    }

    method find_method($type, $name) is raw {
        return if $name eq 'cstr';
        Any.^find_method($name) // self.add_wrapper_method($type, $name);
    }

    method add_wrapper_method($type, $name) is raw {
        my $p5 = $!p5;
        my $module = $!name;

        my $gv := $!p5.look-up-method(self.name($type), $name)
            or die qq/Could not find method "$name" of "{self.name($type)}" object/;

        my $generic-proto := my proto method AUTOGEN(::T $: |) { * }
        my $proto := $generic-proto.instantiate_generic(%('T' => $type));
        $proto.set_name($name);

        my $method := my method (*@args, *%kwargs) {
            self.defined
                ?? $p5.invoke-parent($module, self.wrapped-perl5-object, False, $name, [flat self, |@args], %kwargs)
                !! $p5.invoke($module, $name, |@args.list, |%kwargs)
        };
        $method.set_name($name);

        $proto.add_dispatchee($method);

        my $defined_type := Metamodel::DefiniteHOW.new_type(:base_type($type), :definite(1));
        my $generic-no-args := my method no-args(::T $:) {
            self.defined
                ?? %_
                    ?? $p5.invoke-gv-args(self.wrapped-perl5-object, $gv, Capture.new(:hash(%_)))
                    !! $p5.invoke(self.wrapped-perl5-object, $gv)
                !! $p5.invoke($module, $name, |%_);
        };
        $proto.add_dispatchee($generic-no-args.instantiate_generic(%(:T($defined_type))));
        $proto.add_dispatchee(method () {
            self.defined
                ??  %_
                    ?? $p5.invoke-gv-args(self.wrapped-perl5-object, $gv, Capture.new(:hash(%_)))
                    !! $p5.invoke(self.wrapped-perl5-object, $gv)
                !! $p5.invoke($module, $name, |%_)
        });
        $proto.add_dispatchee(method (\arg) {
            self.defined
                ?? %_
                    ?? $p5.invoke-gv-args(self.wrapped-perl5-object, $gv, Capture.new(:list([arg]), :hash(%_)))
                    !! $p5.invoke-gv-arg(self.wrapped-perl5-object, $gv, arg)
                !! $p5.invoke($module, $name, arg, |%_)
        });

        self.add_method($type, $name, $proto)
    }

    method BUILDPLAN($type) {
        [].FLATTENABLE_LIST
    }

    method BUILDALLPLAN($type) {
        [].FLATTENABLE_LIST
    }
}

=finish
my $foo := Inline::Perl5::ClassHOW.new_type(:name<Foo>);
$foo.^compose;
my $instance = $foo.new;
$foo.foo;
$instance.foo;
note $instance.^name;
$foo.^add_method('bar', my method bar() { say "bar!"; });
$instance.bar;
$instance.item;
$instance.baz;
