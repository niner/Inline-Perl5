use NativeCall;

my &find_best_dispatchee;
BEGIN {
    use MONKEY-SEE-NO-EVAL;
    for q:to/CODE/,
            sub find_best_dispatchee_full(\SELF, Mu \capture) {
                use nqp;
                my $arity = nqp::captureposelems(capture);
                my \entry =
                    nqp::capturenamedshash(capture) || nqp::not_i(nqp::isconcrete(nqp::captureposarg(capture, 0)))
                        ?? nqp::hllbool(nqp::islt_i($arity, 2)) || (nqp::eqaddr(nqp::captureposarg(capture, 1), Scalar)).not
                            ?? nqp::getattr(SELF, SELF.WHAT, '&!many-args')
                            !! nqp::getattr(SELF, SELF.WHAT, '&!scalar-many-args')
                        !! nqp::hllbool(nqp::iseq_i($arity, 1))
                            ?? nqp::getattr(SELF, SELF.WHAT, '&!no-args')
                            !! nqp::hllbool(nqp::iseq_i($arity, 2)) && nqp::istype(nqp::captureposarg(capture, 1), Pair).not
                                ?? nqp::eqaddr(nqp::captureposarg(capture, 1), Scalar)
                                    ?? nqp::getattr(SELF, SELF.WHAT, '&!scalar-no-args')
                                    !! nqp::getattr(SELF, SELF.WHAT, '&!one-arg')
                                !! nqp::hllbool(nqp::iseq_i($arity, 3)) && nqp::eqaddr(nqp::captureposarg(capture, 1), Scalar)
                                    ?? nqp::getattr(SELF, SELF.WHAT, '&!scalar-one-arg')
                                    !! nqp::eqaddr(nqp::captureposarg(capture, 1), Scalar)
                                        ?? nqp::getattr(SELF, SELF.WHAT, '&!scalar-many-args')
                                        !! nqp::getattr(SELF, SELF.WHAT, '&!many-args');
                nqp::scwbdisable();
                nqp::bindattr(SELF, Routine, '$!dispatch_cache',
                    nqp::multicacheadd(
                        nqp::getattr(SELF, Routine, '$!dispatch_cache'),
                        capture, entry));
                nqp::scwbenable();
                entry
            }
            CODE
        q:to/CODE/,
            sub find_best_dispatchee_medium(\SELF, Mu \capture) {
                use nqp;
                nqp::capturenamedshash(capture) || nqp::captureposarg(capture, 0).defined.not
                    ?? nqp::getattr(SELF, SELF.WHAT, '&!many-args')
                    !! nqp::captureposelems(capture) == 1
                        ?? nqp::getattr(SELF, SELF.WHAT, '&!no-args')
                        !! nqp::captureposelems(capture) == 2 && nqp::captureposarg(capture, 1).isa(Pair).not
                            ?? nqp::getattr(SELF, SELF.WHAT, '&!one-arg')
                            !! nqp::getattr(SELF, SELF.WHAT, '&!many-args')
            }
            CODE
        q:to/CODE/
            sub find_best_dispatchee_light(\SELF, Mu \capture) {
                use nqp;
                nqp::getattr(SELF, SELF.WHAT, '&!many-args')
            }
            CODE
    -> $code {
        # First check if the code compiles at all
        my $p = Proc::Async.new($*EXECUTABLE, :w);
        $p.stderr.tap: {;};
        my $start-promise = $p.start;
        await $p.print: 'my $sub = ' ~ $code;
        $p.close-stdin;
        if (await($start-promise).exitcode == 0) {
            # It seems to compile without error, so use it!
            &find_best_dispatchee = EVAL $code;
            last;
        }
    }
}

role Inline::Perl5::WrapperClass { }
role Inline::Perl5::WrapperMethod {
    has &!many-args;
    has &!scalar-many-args;
    has &!one-arg;
    has &!scalar-one-arg;
    has &!no-args;
    has &!scalar-no-args;
    method find_best_dispatchee(\SELF: Mu \capture) {
        find_best_dispatchee(SELF, capture)
    }
    method add_methods(&many-args, &scalar-many-args, &one-arg, &scalar-one-arg, &no-args, &scalar-no-args) {
        &!many-args        := &many-args;
        &!scalar-many-args := &scalar-many-args;
        &!one-arg          := &one-arg;
        &!scalar-one-arg   := &scalar-one-arg;
        &!no-args          := &no-args;
        &!scalar-no-args   := &scalar-no-args;
    }
}

class Inline::Perl5::ClassHOW
    does Metamodel::AttributeContainer
    does Metamodel::MultipleInheritance
    does Metamodel::C3MRO
    does Metamodel::BUILDPLAN
    does Metamodel::MultiMethodContainer
    does Metamodel::Naming
    does Metamodel::REPRComposeProtocol
    does Metamodel::Stashing
{
    has %!cache;
    has @!local_methods;
    has $!p5;
    has $!ip5;
    has $!composed;
    has %!gvs;
    has $!dfs_mro;
    has $!c3_mro;

    my class NQPArray is repr('VMArray') {
        use nqp;
        method push(Mu \value) { nqp::push(self, nqp::decont(value)) }
        method pop() { nqp::pop(self) }
        method unshift(Mu \value) { nqp::unshift(self, nqp::decont(value)) }
        method shift() { nqp::shift(self) }
        method elems() { nqp::elems(self) }
        method AT-POS(int $i) { nqp::atpos(self, $i) }
        method list() {
            my \list = List.new;
            nqp::bindattr(list, List, '$!reified', self);
            list
        }
    }

    my $archetypes := Metamodel::Archetypes.new(
        :nominal(1), :inheritable(1), :augmentable(1) );
    method archetypes() {
        $archetypes
    }

    submethod BUILD(:$!p5, :$!ip5) { }

    method new_type(:$name, :@parents, :$p5, :$ip5) is raw {
        my $how = self.new(:p5($p5 // $*P5), :ip5($ip5 // $*IP5));
        my $type := Metamodel::Primitives.create_type($how);
        $how.set_name($type, $name);
        $how.add_stash($type);
        $how.init;
        use nqp;
        $how.add_parent($type, nqp::decont($_)) for @parents;
        Metamodel::Primitives.configure_type_checking($type,
            (Any, Mu, Inline::Perl5::WrapperClass),
            :authoritative, :call_accepts);
        $type
    }

    method init() {
        use nqp;
        nqp::bindattr(self, $?CLASS, '%!attribute_lookup', nqp::hash());
        nqp::bindattr(self, $?CLASS, '$!dfs_mro', NQPArray.new);
        nqp::bindattr(self, $?CLASS, '@!attributes', nqp::list());
        nqp::bindattr(self, $?CLASS, '@!parents', nqp::list());
        nqp::bindattr(self, $?CLASS, '@!hides', nqp::list());
    }

    method is_composed(Mu \obj) {
        $!composed
    }

    method isa(Mu \obj, Mu \type) {
        obj =:= type
    }

    method does(Mu \obj, Mu \type) {
        type =:= Inline::Perl5::WrapperClass;
    }

    method role_typecheck_list(Mu \obj) {
        my $list := NQPArray.CREATE;
        $list.push: Inline::Perl5::WrapperClass;
        $list
    }

    method gvs(Mu $type?) {
        %!gvs;
    }

    method p5(Mu $type?) {
        $!p5;
    }

    method ip5(Mu $type?) {
        $!ip5;
    }

    method cache(Mu $type?) {
        %!cache;
    }

    method replace_ip5(Mu \type, $ip5) {
        return if $!ip5 === $ip5;
        $!ip5 = $ip5;
        for %!gvs.kv -> $module, %methods {
            for %methods.keys -> $name {
                %methods{$name} = $!p5.look-up-method($module, $name, False);
            }
        }
        self.install-perl5-destructor;
    }

    method install-perl5-destructor() {
        $!p5.run: "
            package $!name \{
                my \$destroy;
                no warnings 'redefine';
                BEGIN \{ \$destroy = defined(&{$!name}::DESTROY) ? \\&{$!name}::DESTROY : undef; \};
                {'sub DESTROY { if (Perl6::Object::destroy($_[0])) { if (defined $destroy) { $destroy->(@_) } else { $_[0]->SUPER::DESTROY } } }'}
            \}
        ";
    }

    my $destroyers := [
            my method DESTROY (\SELF:) {
                SELF.DESTROY
            },
        ].FLATTENABLE_LIST;

    method destroyers(Mu \type) {
        $destroyers
    }

    method compute_dfs_mro(Mu \type) {
        use nqp;

        my $mro := NQPArray.new;

        $mro.push: type;
        for nqp::hllize(@!parents) {
            MRO: for $_.^mro {
                my int $i = 0;
                my int $end = $mro.elems;
                while $i < $end {
                    next MRO if $mro.AT-POS($i++) =:= $_;
                }
                $mro.push: $_;
            }
        }

        $!dfs_mro := $mro;
    }

    method compute_mro(Mu \type) {
        self.Metamodel::C3MRO::compute_mro(type);
        $!c3_mro := NQPArray.new;
        $!c3_mro.push: $_<> for self.Metamodel::C3MRO::mro(type);
    }

    method mro(Mu \type) is raw {
        $!p5.call-simple-args('mro::get_mro', $!name) eq 'c3' ?? $!c3_mro !! $!dfs_mro
    }

    method compose(Mu \type) {
        use nqp;
        unless nqp::elems(@!parents) {
            nqp::push(@!parents, Any);
        }

        my $mro = $!p5.call-simple-args('mro::get_mro', $!name);
        if $mro eq 'c3' {
            self.compute_mro(type);
        }
        else {
            self.compute_dfs_mro(type);
        }

        # Set up type checking with cache.
        Metamodel::Primitives.configure_type_checking(type,
            (|self.mro(type).list, Inline::Perl5::WrapperClass),
            :authoritative, :call_accepts);

        my $p5 = $!p5;
        my $module = $!name;

        self.install-perl5-destructor;

        # Steal methods of Any/Mu for our method cache.
        if @!parents[0] =:= Any {
            for flat Any.^method_table.pairs, Mu.^method_table.pairs {
                %!cache{.key} //= .value;
            }
        }
        else {
            for <BUILDALL bless can defined isa sink WHICH WHERE WHY ACCEPTS> {
                %!cache{$_} := Mu.^method_table{$_};
            }
        }

        %!cache<Str> := my method Str(\SELF:) {
            my $stringify = $p5.call('overload::Method', SELF, '""');
            $stringify ?? $stringify(SELF) !! SELF.^name ~ '(' ~ SELF.wrapped-perl5-object.gist ~ ')'
        }
        %!cache<gist> := my method gist(\SELF:) {
            my $stringify = $p5.call('overload::Method', SELF, '""');
            $stringify ?? $stringify(SELF).gist !! SELF.^name ~ '.new()'
        }
        %!cache<Numeric> := my method Numeric(\SELF:) {
            my $numify = $p5.call('overload::Method', SELF, '0+');
            $numify ?? $numify(SELF) !! SELF.^name ~ '(' ~ SELF.wrapped-perl5-object.gist ~ ')'
        }
        %!cache<AT-KEY> := my method AT-KEY(\SELF: Str() \key) {
            $p5.at-key(SELF.wrapped-perl5-object, key)
        }
        %!cache<DESTROY> := my method DESTROY(\SELF:) {
            my $obj = SELF.wrapped-perl5-object;
            if $obj {
                SELF.^mro.first({$_.HOW.^isa(Inline::Perl5::ClassHOW)}).^ip5.p5_sv_destroy($obj);
                use nqp;
                nqp::bindattr(SELF, SELF.^mro.grep({$_.HOW.^isa(Inline::Perl5::ClassHOW)}).tail, '$!wrapped-perl5-object', Pointer);
            }
        }
        %!cache<new_shadow_of_p5_object> := my method new_shadow_of_p5_object(\SELF: \arg) {
            arg
        }
        Metamodel::Primitives.install_method_cache(type, %!cache, :!authoritative);

        use nqp;
        nqp::settypefinalize(type, 1);

        unless any(@!parents[0].^mro.list.map({$_.HOW})) ~~ Inline::Perl5::ClassHOW {
            self.add_attribute(type, Attribute.new(
                :name<$!inline-perl5>,
                :type(Any),
                :package(type),
                :has_accessor(1),
                :container_initializer{
                    my \container = Scalar.CREATE;
                    nqp::bindattr(
                        container,
                        Scalar,
                        '$!descriptor',
                        ContainerDescriptor.new(:of(Any), :name<$!inline-perl5>, :default(Any), :dynamic(0)),
                    );
                    container
                },
            )) ;
            self.add_attribute(type, Attribute.new(
                :name<$!wrapped-perl5-object>,
                :type(Pointer),
                :package(type),
                :has_accessor(1),
                :container_initializer{
                    my \container = Scalar.CREATE;
                    nqp::bindattr(
                        container,
                        Scalar,
                        '$!descriptor',
                        ContainerDescriptor.new(:of(Any), :name<$!wrapped-perl5-object>, :default(Any), :dynamic(0)),
                    );
                    container
                },
            ));
        }

        $!composed = True;
        my $compiler_services = $*W.get_compiler_services(Match.new) if $*W;
        self.compose_attributes(type, :$compiler_services);

        self.create_BUILDPLAN(type);

        self.compose_type(
            type,
            {
                attribute => self.mro(type).map(-> \parent {
                        parent,
                        parent.HOW.attributes(parent, :local).map({
                            (
                                :name($_.name),
                                :type($_.type =:= Mu ?? Any !! $_.type),
                                :inlined($_.inlined),
                                :auto_viv_container($_.auto_viv_container),
                            ).Hash
                        }).List,
                        [parent.^mro.list.elems > 1 ?? parent.^mro.list[1] !! Empty]
                }).List,
            }
        );
        nqp::bindattr(self, $?CLASS, '$!composed_repr', nqp::unbox_i(1));
        my $has_new = self.add_wrapper_method(type, 'new');
        unless $has_new {
            self.add_method(type, 'new', my method new(Any \SELF: **@a, *%h) {
                my \obj_ref = $p5.interpreter.p5_new_blessed_hashref(SELF.^name);
                my \obj = $p5.p5_sv_rv(obj_ref);
                $p5.interpreter.p5_sv_refcnt_inc(obj);
                $p5.interpreter.p5_sv_refcnt_dec(obj_ref);
                SELF.bless(|@a, |%h, :wrapped-perl5-object(obj), :inline-perl5($p5))
            });
        }
        $*W.add_object(type) if $*W;

        type
    }
    method compose_type(Mu $type, $configuration) {
        use nqp;
        multi sub to_vm_types(@array) {
            my Mu $list := nqp::list();
            for @array {
                nqp::push($list, to_vm_types($_));
            }
            $list
        }
        multi sub to_vm_types(%hash) {
            my Mu $hash := nqp::hash();
            for %hash.kv -> $k, \v {
                if $k eq 'auto_viv_container' {
                    nqp::bindkey($hash, $k, v);
                }
                else {
                    nqp::bindkey($hash, $k, to_vm_types(v));
                }
            }
            $hash
        }
        multi sub to_vm_types(Mu $other) {
            nqp::decont($other)
        }
        nqp::composetype(nqp::decont($type), to_vm_types($configuration));
        $type
    }

    method add_method(Mu $type, $name, \meth) is raw {
        %!cache{$name} := meth;
        push @!local_methods, meth;
        Metamodel::Primitives.install_method_cache($type, %!cache, :!authoritative)
            if $!composed;
        meth
    }

    method declares_method(Mu $type, $name) {
        %!cache{$name}:exists
    }

    method method_table(Mu $type) is raw {
        use nqp;
        my class NQPHash is repr('VMHash') {
            method Map() {
                my \map = Map.new;
                nqp::bindattr(map, Map, '$!storage', self);
                map
            }
        };
        my Mu \result := nqp::create(NQPHash);
        for %!cache {
            nqp::bindkey(result, $_.key, nqp::decont($_.value));
        }
        result
    }

    method submethod_table(Mu $type) is raw {
        use nqp;
        nqp::hash()
    }

    method methods(Mu $type, :$local, :$excl, :$all) {
        $local ?? @!local_methods !! %!cache.values
    }

    method type_check(Mu \type, Mu \check) {
        for self.mro(type).list {
            return True if Metamodel::Primitives.is_type(check, $_);
        }
        return False;
    }

    method accepts_type(Mu $, Mu \check) {
        return False;
    }

    method find_method(Mu $type is raw, $name) {
        return if $name eq 'cstr';
        # must not be AUTOLOADed and must not call into P5 before the object's fully constructed
        if $name eq 'BUILD' or $name eq 'TWEAK' {
            return %!cache{$name};
        }
        %!cache{$name} // self.add_wrapper_method($type, $name, :local) // do {
            for self.mro($type) {
                my $meths := $_.^method_table.Map;
                if $meths{$name}:exists {
                    my $meth := $meths{$name};
                    %!cache{$name} := $meth;
                    return $meth
                }
            }
            Nil
        }
    }

    method can($type, $name) {
        my @meths;
        for self.mro($type) {
            my %mt := $_.HOW.method_table($_).Map;
            if %mt{$name}:exists {
                @meths.push: %mt{$name}
            }
        }
        @meths
    }

    method add_wrapper_method(Mu $type, $name, Bool :$local = False) is raw {
        return if $name eq 'BUILD' | 'TWEAK' | 'wrapped-perl5-object' | 'inline-perl5';
        my $p5 = $!p5;
        my $module = $!name;

        my $gv = $!p5.look-up-method(self.name($type), $name, $local)
            or fail "Did not find method $name on $module";
        (%!gvs{self.name($type)} ||= Hash.new){$name} := $gv;

        my $generic-proto := my proto method AUTOGEN(::T $: |) { * }
        my $proto := $generic-proto.instantiate_generic(%('T' => $type));
        $proto.set_name($name);
        $proto does Inline::Perl5::WrapperMethod;

        my $many-args := my sub many-args(Any $self, **@args, *%kwargs) {
            $self.defined
                ?? $p5.invoke-parent($module, $self.wrapped-perl5-object, False, $name, List.new($self, @args.Slip).flat.Array, %kwargs)
                !! $p5.invoke($self, $module, $name, |@args, |%kwargs)
        };
        $proto.add_dispatchee($many-args);
        my $scalar-many-args := my sub scalar-many-args(Any $self, Scalar:U, **@args, *%kwargs) {
            $self.defined
                ?? $p5.invoke-parent($module, $self.wrapped-perl5-object, True, $name, [flat $self, |@args], %kwargs)
                !! $p5.invoke($self, $module, $name, |@args, |%kwargs)
        };
        $proto.add_dispatchee($scalar-many-args);

        my $defined_type := Metamodel::DefiniteHOW.new_type(:base_type($type), :definite(1));
        my $no-args := my sub no-args(Any:D \SELF) {
            my int32 $retvals;
            my int32 $err;
            my int32 $type;
            my $av = $!ip5.p5_call_parent_gv(
                $gv,
                1,
                $p5.unwrap-perl5-object(SELF),
                $retvals,
                $err,
                $type,
            );
            $p5.handle_p5_exception() if $err;
            $p5.unpack_return_values($av, $retvals, $type);
        };
        $proto.add_dispatchee($no-args);
        my $scalar-no-args := my sub scalar-no-args(Any:D \SELF, Scalar:U) {
            my int32 $retvals;
            my int32 $err;
            my int32 $type;
            my $av = $!ip5.p5_scalar_call_parent_gv(
                $gv,
                1,
                $p5.unwrap-perl5-object(SELF),
                $retvals,
                $err,
                $type,
            );
            $p5.handle_p5_exception() if $err;
            $p5.unpack_return_values($av, $retvals, $type);
        };
        $proto.add_dispatchee($scalar-no-args);
        my $one-pair-arg := my sub one-pair-arg(Any:D \SELF, Pair \arg) {
            $p5.invoke-gv-arg(SELF.wrapped-perl5-object, $gv, arg)
        };
        $proto.add_dispatchee($one-pair-arg);
        my $one-arg := my sub one-arg(Any:D \SELF, \arg) {
            my int32 $retvals = 0;
            my int32 $err = 0;
            my int32 $type = 0;
            my $av = $!ip5.p5_call_gv_two_args(
                $gv,
                $p5.unwrap-perl5-object(SELF),
                $p5.p6_to_p5(arg),
                $retvals,
                $type,
                $err,
            );
            $p5.handle_p5_exception if $err;
            $p5.unpack_return_values($av, $retvals, $type);
        };
        $proto.add_dispatchee($one-arg);
        my $scalar-one-arg := my sub scalar-one-arg(Any:D \SELF, Scalar:U, \arg) {
            my int32 $retvals = 0;
            my int32 $err = 0;
            my int32 $type = 0;
            my $av = $!ip5.p5_scalar_call_gv_two_args(
                $gv,
                $p5.unwrap-perl5-object(SELF),
                $p5.p6_to_p5(arg),
                $retvals,
                $type,
                $err,
            );
            $p5.handle_p5_exception if $err;
            $p5.unpack_return_values($av, $retvals, $type);
        };
        $proto.add_dispatchee($scalar-one-arg);
        $proto.add_methods($many-args, $scalar-many-args, $one-arg, $scalar-one-arg, $no-args, $scalar-no-args);

        self.add_method($type, $name, $proto)
    }

    method lang-rev-before(Mu \type, $rev) {
        1
    }
}

my package EXPORTHOW {
    package DECLARE {
        constant perl5class = Inline::Perl5::ClassHOW;
    }
}
