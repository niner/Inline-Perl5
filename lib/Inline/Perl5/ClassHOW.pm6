use NativeCall;
use MONKEY-SEE-NO-EVAL;

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

    method compose(\type) {
        # Set up type checking with cache.
        Metamodel::Primitives.configure_type_checking(type,
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
        Metamodel::Primitives.install_method_cache(type, %!cache, :!authoritative);

        use nqp;
        nqp::bindattr(self, $?CLASS, '%!attribute_lookup', nqp::hash());
        nqp::bindattr(self, $?CLASS, '@!attributes', nqp::list());

        self.add_attribute(type, Attribute.new(
            :name<$!wrapped-perl5-object>,
            :type(Pointer),
            :package(type),
            :has_accessor(1),
        ));

        $!composed = True;
        my $compiler_services := $*W.get_compiler_services(Match.new) if $*W;
        self.compose_attributes(type, :$compiler_services);
        Metamodel::Primitives.compose_type(
            type,
            {
                attribute => [
                    [type, [{:name<$!wrapped-perl5-object>, :type(Pointer)},], []],
                ]
            }
        );
        nqp::bindattr(self, $?CLASS, '$!composed_repr', nqp::unbox_i(1));
        $*W.add_object(type) if $*W;

        type
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
        use nqp;
        my class NQPHash is repr('VMHash') { };
        my Mu \result := nqp::create(NQPHash);
        for %!cache {
            nqp::bindkey(result, $_.key, nqp::decont($_.value));
        }
        result
    }

    method submethod_table($type) is raw {
        use nqp;
        nqp::hash()
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

    my &find_best_dispatchee;
    method add_wrapper_method($type, $name) is raw {
        my $p5 = $!p5;
        my $module = $!name;

        my $gv := $!p5.look-up-method(self.name($type), $name)
            or die qq/Could not find method "$name" of "{self.name($type)}" object/;

        my $generic-proto := my proto method AUTOGEN(::T $: |) { * }
        my $proto := $generic-proto.instantiate_generic(%('T' => $type));
        $proto.set_name($name);
        &find_best_dispatchee //= try EVAL q:to/ROLE/;
            -> \SELF, Mu \capture {
                use nqp;
                sub add_to_cache(\SELF, \entry) {
                    nqp::scwbdisable();
                    nqp::bindattr(SELF, Routine, '$!dispatch_cache',
                        nqp::multicacheadd(
                            nqp::getattr(SELF, Routine, '$!dispatch_cache'),
                            capture, entry));
                    nqp::scwbenable();
                    entry
                }
                add_to_cache(SELF,
                    nqp::capturenamedshash(capture) || !nqp::captureposarg(capture, 0).defined
                        ?? nqp::getattr(SELF, SELF.WHAT, '&!many-args')
                        !! nqp::captureposelems(capture) == 1
                            ?? nqp::getattr(SELF, SELF.WHAT, '&!no-args')
                            !! nqp::captureposelems(capture) == 2 && !(nqp::captureposarg(capture, 1) ~~ Pair)
                                ?? nqp::getattr(SELF, SELF.WHAT, '&!one-arg')
                                !! nqp::getattr(SELF, SELF.WHAT, '&!many-args')
                )
            }
            ROLE
        &find_best_dispatchee //= try EVAL q:to/ROLE/;
            -> \SELF, Mu \capture {
                use nqp;
                nqp::capturenamedshash(capture) || !nqp::captureposarg(capture, 0).defined
                    ?? nqp::getattr(SELF, SELF.WHAT, '&!many-args')
                    !! nqp::captureposelems(capture) == 1
                        ?? nqp::getattr(SELF, SELF.WHAT, '&!no-args')
                        !! nqp::captureposelems(capture) == 2 && !(nqp::captureposarg(capture, 1) ~~ Pair)
                            ?? nqp::getattr(SELF, SELF.WHAT, '&!one-arg')
                            !! nqp::getattr(SELF, SELF.WHAT, '&!many-args')
            }
            ROLE
        &find_best_dispatchee //= -> \SELF, Mu \capture { use nqp; nqp::getattr(SELF, SELF.WHAT, '&!many-args') };
        $proto does role :: {
            has &!many-args;
            has &!one-arg;
            has &!no-args;
            method find_best_dispatchee(Mu \capture) {
                find_best_dispatchee(self, capture);
            }
            method add_methods(&many-args, &one-arg, &no-args) {
                &!many-args := &many-args;
                &!one-arg   := &one-arg;
                &!no-args   := &no-args;
            }
        }

        my $method := my sub many-args(Any $self, *@args, *%kwargs) {
            $self.defined
                ?? $p5.invoke-parent($module, $self.wrapped-perl5-object, False, $name, [flat $self, |@args], %kwargs)
                !! $p5.invoke($module, $name, |@args.list, |%kwargs)
        };
        $proto.add_dispatchee($method);

        my $defined_type := Metamodel::DefiniteHOW.new_type(:base_type($type), :definite(1));
        my $no-args := my sub no-args(Any:D $self) {
            $p5.invoke-gv($self.wrapped-perl5-object, $gv)
        };
        $proto.add_dispatchee($no-args);
        my $one-pair-arg := my sub one-pair-arg(Any:D $self, Pair \arg) {
            $p5.invoke-gv-arg($self.wrapped-perl5-object, $gv, arg)
        };
        $proto.add_dispatchee($one-pair-arg);
        my $one-arg := my sub one-arg(Any:D $self, \arg) {
            $p5.invoke-gv-simple-arg($self.wrapped-perl5-object, $gv, arg)
        };
        $proto.add_dispatchee($one-arg);
        $proto.add_methods($method, $one-arg, $no-args);

        self.add_method($type, $name, $proto)
    }

    method BUILDPLAN($type) {
        [].FLATTENABLE_LIST
    }

    method BUILDALLPLAN($type) {
        [].FLATTENABLE_LIST
    }

    method compose_attributes(\obj, :$compiler_services) {
        use nqp;
        for nqp::hllize(@!attributes) {
            $_.compose(obj, :$compiler_services)
        }
    }

    method mro(\obj) {
        use nqp;
        unless @!mro {
            my class NQPArray is repr('VMArray') {
                method push(Mu \value) { nqp::push(self, nqp::decont(value)) }
                method pop() { nqp::pop(self) }
                method unshift(Mu \value) { nqp::unshift(self, nqp::decont(value)) }
                method shift() { nqp::shift(self) }
                method list() {
                    my \list = List.new;
                    nqp::bindattr(list, List, '$!reified', self);
                    list
                }
            }
            nqp::bindattr(self, $?CLASS, '@!mro', nqp::create(NQPArray));
            nqp::bindpos(@!mro, 0, nqp::decont(obj));
            for $!base_type.HOW.mro($!base_type) {
                nqp::push(@!mro, nqp::decont($_));
            }
        }
        @!mro
    }
}
