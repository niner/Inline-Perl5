use Inline::Perl5::ClassHOW;
use NativeCall;

class Inline::Perl5::ClassHOW::ThreadSafe is Inline::Perl5::ClassHOW {
    method add_wrapper_method(Mu $type, $name, Bool :$local = False) is raw {
        return if $name eq 'BUILD' | 'TWEAK' | 'wrapped-perl5-object' | 'inline-perl5';
        my $*p5 = $.p5;
        my $module = $.name($type);

        my $gv = $*p5.look-up-method(self.name($type), $name, $local)
            or fail "Did not find method $name on $module";
        ($.gvs{self.name($type)} ||= Hash.new){$name} := $gv;

        my $gil = class :: {
            has $.module;
            has $.type;
            has $.orig-p5;
            method protect(&code) {
                my $thread = $*THREAD;
                my role Perl5Interpreter[$p5] {
                    has $.p5 = $p5;
                }
                unless $thread.does(Perl5Interpreter) {
                    if $thread.id == $!orig-p5.default_perl5.thread-id {
                        $thread does Perl5Interpreter[$.orig-p5];
                    }
                    else {
                        $thread does Perl5Interpreter[$.orig-p5.new(:thread-safe)];
                        my $p5 = $thread.p5;
                        $p5.gil.protect: { # Unfortunately compilation of some modules is not thread safe
                            $p5.require_modules($p5.default_perl5.required_modules);
                        }
                    }
                }
                my $*p5 = $thread.p5;
                &code.()
            }
        }.new(:$module, :$type, :orig-p5($.p5));

        my $generic-proto := my proto method AUTOGEN(::T $: |) { * }
        my $proto := $generic-proto.instantiate_generic(%('T' => $type));
        $proto.set_name($name);
        $proto does Inline::Perl5::WrapperMethod;

        my $many-args := my sub many-args(Any $self, **@args, *%kwargs) {
            $gil.protect: {
            $self.defined
                ?? $self.inline-perl5.invoke-parent($module, $self.wrapped-perl5-object, False, $name, List.new($self, @args.Slip).flat.Array, %kwargs)
                !! $*p5.invoke($self, $module, $name, |@args, |%kwargs)
            }
        };
        $proto.add_dispatchee($many-args);
        my $scalar-many-args := my sub scalar-many-args(Any $self, Scalar:U, **@args, *%kwargs) {
            $gil.protect: {
            $self.defined
                ?? $self.inline-perl5.invoke-parent($module, $self.wrapped-perl5-object, True, $name, [flat $self, |@args], %kwargs)
                !! $*p5.invoke($self, $module, $name, |@args, |%kwargs)
            }
        };
        $proto.add_dispatchee($many-args);

        my $defined_type := Metamodel::DefiniteHOW.new_type(:base_type($type), :definite(1));
        my $no-args := my sub no-args(Any:D \SELF) {
            my int32 $retvals;
            my int32 $err;
            my int32 $type;
            my $p5 = SELF.inline-perl5;
            my $av = $p5.interpreter.p5_call_parent_gv(
                $p5.look-up-method($module, $name, $local),
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
            my $p5 = SELF.inline-perl5;
            my $av = $p5.interpreter.p5_scalar_call_parent_gv(
                $p5.look-up-method($module, $name, $local),
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
            my $p5 := SELF.inline-perl5;
            $p5.invoke-gv-arg(
                SELF.wrapped-perl5-object,
                $p5.look-up-method($module, $name, $local),
                arg,
            )
        };
        $proto.add_dispatchee($one-pair-arg);
        my $one-arg := my sub one-arg(Any:D \SELF, \arg) {
            my int32 $retvals = 0;
            my int32 $err = 0;
            my int32 $type = 0;
            my $p5 = SELF.inline-perl5;
            my $av = $p5.interpreter.p5_call_gv_two_args(
                $p5.look-up-method($module, $name, $local),
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
            my $p5 = SELF.inline-perl5;
            my $av = $p5.interpreter.p5_scalar_call_gv_two_args(
                $p5.look-up-method($module, $name, $local),
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

    method compose(Mu \type) {
        callsame;
        $.cache<Str> := my method Str(\SELF:) {
            my $p5 = SELF.inline-perl5;
            my $stringify = $p5.call('overload::Method', SELF, '""');
            $stringify ?? $stringify(SELF) !! SELF.^name ~ '(' ~ SELF.wrapped-perl5-object.gist ~ ')'
        }
        $.cache<Numeric> := my method Numeric(\SELF:) {
            my $p5 = SELF.inline-perl5;
            my $numify = $p5.call('overload::Method', SELF, '0+');
            $numify ?? $numify(SELF) !! SELF.^name ~ '(' ~ SELF.wrapped-perl5-object.gist ~ ')'
        }
        $.cache<AT-KEY> := my method AT-KEY(\SELF: Str() \key) {
            my $p5 = SELF.inline-perl5;
            $p5.at-key(SELF.wrapped-perl5-object, key)
        }
        $.cache<DESTROY> := my method DESTROY(\SELF:) {
            my $p5 = SELF.inline-perl5;
            my $obj = SELF.wrapped-perl5-object;
            if $obj {
                $p5.interpreter.p5_sv_destroy($obj);
                use nqp;
                nqp::bindattr(SELF, SELF.^mro.grep({$_.HOW.^isa(Inline::Perl5::ClassHOW)}).tail, '$!wrapped-perl5-object', Pointer);
            }
        }
        Metamodel::Primitives.install_method_cache(type, $.cache, :!authoritative);
        type
    }
}
