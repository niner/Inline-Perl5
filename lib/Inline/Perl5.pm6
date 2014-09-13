class Inline::Perl5;

class Perl5Interpreter is repr('CPointer') { }

has Perl5Interpreter $!p5;
has &!call_method;

use NativeCall;

sub native(Sub $sub) {
    my $so = 'p5helper.so';
    my Str $path;
    for @*INC {
        if ($_ ~ "/Inline/$so").IO ~~ :f {
            $path = $_ ~ "/Inline/$so";
            trait_mod:<is>($sub, :native($path));
            return;
        }
    }
    die "unable to find $so";
}

class Perl5Object { ... }

class X::Inline::Perl5::Unmarshallable is Exception {
    has Mu $.object;
    method message() {
        "Don't know how to pass object of type {$.object.^name} to Perl 5 code";
    }
}

class ObjectKeeper {
    has @!objects;
    has $!last_free = -1;

    method keep(Any:D $value) returns Int {
        if $!last_free != -1 {
            my $index = $!last_free;
            $!last_free = @!objects[$!last_free];
            @!objects[$index] = $value;
            return $index;
        }
        else {
            @!objects.push($value);
            return @!objects.end;
        }
    }

    method get(Int $index) returns Any:D {
        return @!objects[$index];
    }

    method free(Int $index) {
        @!objects[$index] = $!last_free;
        $!last_free = $index;
    }
}

sub p5_init_perl()
    returns Perl5Interpreter { ... }
    native(&p5_init_perl);
sub p5_SvIOK(Perl5Interpreter, OpaquePointer)
    returns Int { ... }
    native(&p5_SvIOK);
sub p5_SvPOK(Perl5Interpreter, OpaquePointer)
    returns Int { ... }
    native(&p5_SvPOK);
sub p5_is_array(Perl5Interpreter, OpaquePointer)
    returns Int { ... }
    native(&p5_is_array);
sub p5_is_hash(Perl5Interpreter, OpaquePointer)
    returns Int { ... }
    native(&p5_is_hash);
sub p5_is_undef(Perl5Interpreter, OpaquePointer)
    returns Int { ... }
    native(&p5_is_undef);
sub p5_sv_to_char_star(Perl5Interpreter, OpaquePointer)
    returns Str { ... }
    native(&p5_sv_to_char_star);
sub p5_sv_to_av(Perl5Interpreter, OpaquePointer)
    returns OpaquePointer { ... }
    native(&p5_sv_to_av);
sub p5_sv_to_hv(Perl5Interpreter, OpaquePointer)
    returns OpaquePointer { ... }
    native(&p5_sv_to_hv);
sub p5_sv_refcnt_dec(Perl5Interpreter, OpaquePointer)
    { ... }
    native(&p5_sv_refcnt_dec);
sub p5_sv_2mortal(Perl5Interpreter, OpaquePointer)
    { ... }
    native(&p5_sv_2mortal);
sub p5_sv_refcnt_inc(Perl5Interpreter, OpaquePointer)
    { ... }
    native(&p5_sv_refcnt_inc);
sub p5_int_to_sv(Perl5Interpreter, Int)
    returns OpaquePointer { ... }
    native(&p5_int_to_sv);
sub p5_str_to_sv(Perl5Interpreter, Str)
    returns OpaquePointer { ... }
    native(&p5_str_to_sv);
sub p5_av_top_index(Perl5Interpreter, OpaquePointer)
    returns Int { ... }
    native(&p5_av_top_index);
sub p5_av_fetch(Perl5Interpreter, OpaquePointer, Int)
    returns OpaquePointer { ... }
    native(&p5_av_fetch);
sub p5_av_push(Perl5Interpreter, OpaquePointer, OpaquePointer)
    { ... }
    native(&p5_av_push);
sub p5_hv_iterinit(Perl5Interpreter, OpaquePointer)
    returns Int { ... }
    native(&p5_hv_iterinit);
sub p5_hv_iternext(Perl5Interpreter, OpaquePointer)
    returns OpaquePointer { ... }
    native(&p5_hv_iternext);
sub p5_hv_iterkeysv(Perl5Interpreter, OpaquePointer)
    returns OpaquePointer { ... }
    native(&p5_hv_iterkeysv);
sub p5_hv_iterval(Perl5Interpreter, OpaquePointer, OpaquePointer)
    returns OpaquePointer { ... }
    native(&p5_hv_iterval);
sub p5_undef(Perl5Interpreter)
    returns OpaquePointer { ... }
    native(&p5_undef);
sub p5_newHV(Perl5Interpreter)
    returns OpaquePointer { ... }
    native(&p5_newHV);
sub p5_newAV(Perl5Interpreter)
    returns OpaquePointer { ... }
    native(&p5_newAV);
sub p5_newRV_noinc(Perl5Interpreter, OpaquePointer)
    returns OpaquePointer { ... }
    native(&p5_newRV_noinc);
sub p5_hv_store(Perl5Interpreter, OpaquePointer, Str, OpaquePointer)
    { ... }
    native(&p5_hv_store);
sub p5_call_function(Perl5Interpreter, Str, Int, CArray[OpaquePointer])
    returns OpaquePointer { ... }
    native(&p5_call_function);
sub p5_call_method(Perl5Interpreter, Str, OpaquePointer, Str, Int, CArray[OpaquePointer])
    returns OpaquePointer { ... }
    native(&p5_call_method);
sub p5_call_package_method(Perl5Interpreter, Str, Str, Int, CArray[OpaquePointer])
    returns OpaquePointer { ... }
    native(&p5_call_package_method);
sub p5_rebless_object(Perl5Interpreter, OpaquePointer)
    { ... }
    native(&p5_rebless_object);
sub p5_destruct_perl(Perl5Interpreter)
    { ... }
    native(&p5_destruct_perl);
sub p5_sv_iv(Perl5Interpreter, OpaquePointer)
    returns Int { ... }
    native(&p5_sv_iv);
sub p5_is_object(Perl5Interpreter, OpaquePointer)
    returns Int { ... }
    native(&p5_is_object);
sub p5_eval_pv(Perl5Interpreter, Str, Int)
    returns OpaquePointer { ... }
    native(&p5_eval_pv);
sub p5_wrap_p6_object(Perl5Interpreter, Int, OpaquePointer, &call_method(Int, Str, OpaquePointer --> OpaquePointer), &free_p6_object(Int))
    returns OpaquePointer { ... }
    native(&p5_wrap_p6_object);
sub p5_is_wrapped_p6_object(Perl5Interpreter, OpaquePointer)
    returns Int { ... }
    native(&p5_is_wrapped_p6_object);
sub p5_unwrap_p6_object(Perl5Interpreter, OpaquePointer)
    returns Int { ... }
    native(&p5_unwrap_p6_object);
sub p5_terminate()
    { ... }
    native(&p5_terminate);

multi method p6_to_p5(Int:D $value) returns OpaquePointer {
    return p5_int_to_sv($!p5, $value);
}
multi method p6_to_p5(Str:D $value) returns OpaquePointer {
    return p5_str_to_sv($!p5, $value);
}
multi method p6_to_p5(Perl5Object $value) returns OpaquePointer {
    p5_sv_refcnt_inc($!p5, $value.ptr);
    return $value.ptr;
}
multi method p6_to_p5(OpaquePointer $value) returns OpaquePointer {
    return $value;
}
multi method p6_to_p5(Any:U $value) returns OpaquePointer {
    return p5_undef($!p5);
}

my $objects = ObjectKeeper.new;

sub free_p6_object(Int $index) {
    $objects.free($index);
}

multi method p6_to_p5(Perl5Object:D $value, OpaquePointer $inst) {
    p5_sv_refcnt_inc($!p5, $inst);
    return $inst;
}
multi method p6_to_p5(Any:D $value, OpaquePointer $inst = OpaquePointer) {
    my $index = $objects.keep($value);

    return p5_wrap_p6_object(
        $!p5,
        $index,
        $inst,
        &!call_method,
        &free_p6_object,
    );
}
multi method p6_to_p5(Hash:D $value) returns OpaquePointer {
    my $hv = p5_newHV($!p5);
    for %$value -> $item {
        my $value = self.p6_to_p5($item.value);
        p5_hv_store($!p5, $hv, $item.key, $value);
    }
    return p5_newRV_noinc($!p5, $hv);
}
multi method p6_to_p5(Positional:D $value) returns OpaquePointer {
    my $av = p5_newAV($!p5);
    for @$value -> $item {
        p5_av_push($!p5, $av, self.p6_to_p5($item));
    }
    return p5_newRV_noinc($!p5, $av);
}

method p5_array_to_p6_array(OpaquePointer $sv) {
    my $av = p5_sv_to_av($!p5, $sv);
    my $av_len = p5_av_top_index($!p5, $av);

    my $arr = [];
    loop (my $i = 0; $i <= $av_len; $i++) {
        $arr.push(self.p5_to_p6(p5_av_fetch($!p5, $av, $i)));
    }
    return $arr;
}
method !p5_hash_to_p6_hash(OpaquePointer $sv) {
    my OpaquePointer $hv = p5_sv_to_hv($!p5, $sv);

    my Int $len = p5_hv_iterinit($!p5, $hv);

    my $hash = {};

    for 0 .. $len - 1 {
        my OpaquePointer $next = p5_hv_iternext($!p5, $hv);
        my OpaquePointer $key = p5_hv_iterkeysv($!p5, $next);
        die 'Hash entry without key!?' unless $key;
        my Str $p6_key = p5_sv_to_char_star($!p5, $key);
        my $val = self.p5_to_p6(p5_hv_iterval($!p5, $hv, $next));
        $hash{$p6_key} = $val;
    }

    return $hash;
}

method p5_to_p6(OpaquePointer $value) {
    if p5_is_object($!p5, $value) {
        if p5_is_wrapped_p6_object($!p5, $value) {
            return $objects.get(p5_unwrap_p6_object($!p5, $value));
        }
        else {
            p5_sv_refcnt_inc($!p5, $value);
            return Perl5Object.new(perl5 => self, ptr => $value);
        }
    }
    elsif p5_SvIOK($!p5, $value) {
        return p5_sv_iv($!p5, $value);
    }
    elsif p5_SvPOK($!p5, $value) {
        return p5_sv_to_char_star($!p5, $value);
    }
    elsif p5_is_array($!p5, $value) {
        return self.p5_array_to_p6_array($value);
    }
    elsif p5_is_hash($!p5, $value) {
        return self!p5_hash_to_p6_hash($value);
    }
    elsif p5_is_undef($!p5, $value) {
        return Any;
    }
    die "Unsupported type $value in p5_to_p6";
}

method run($perl) {
    my $res = p5_eval_pv($!p5, $perl, 1);
    return self.p5_to_p6($res);
}

method !setup_arguments(@args) {
    my $len = @args.elems;
    my @svs := CArray[OpaquePointer].new();
    loop (my $i = 0; $i < $len; $i++) {
        @svs[$i] = self.p6_to_p5(@args[$i]);
    }
    return $len, @svs;
}

method !unpack_return_values($av) {
    my $av_len = p5_av_top_index($!p5, $av);

    if $av_len == -1 {
        p5_sv_refcnt_dec($!p5, $av);
        return;
    }

    if $av_len == 0 {
        my $retval = self.p5_to_p6(p5_av_fetch($!p5, $av, 0));
        p5_sv_refcnt_dec($!p5, $av);
        return $retval;
    }

    my @retvals;
    loop (my $i = 0; $i <= $av_len; $i++) {
        @retvals.push(self.p5_to_p6(p5_av_fetch($!p5, $av, $i)));
    }
    p5_sv_refcnt_dec($!p5, $av);
    return @retvals;
}

method call(Str $function, *@args) {
    return self!unpack_return_values(
        p5_call_function($!p5, $function, |self!setup_arguments(@args))
    );
}

multi method invoke(Str $package, Str $function, *@args) {
    return self!unpack_return_values(
        p5_call_package_method($!p5, $package, $function, |self!setup_arguments(@args))
    );
}

multi method invoke(OpaquePointer $obj, Str $function, *@args) {
    return self.invoke(Str, $obj, $function, @args.list);
}

multi method invoke(Str $package, OpaquePointer $obj, Str $function, *@args) {
    my $len = @args.elems;
    my @svs := CArray[OpaquePointer].new();
    @svs[0] = self.p6_to_p5(@args[0], $obj);
    loop (my $i = 1; $i < $len; $i++) {
        @svs[$i] = self.p6_to_p5(@args[$i]);
    }
    return self!unpack_return_values(
        p5_call_method($!p5, $package, $obj, $function, $len, @svs)
    );
}

method init_callbacks {
    self.run(q[
        package Perl6::Object;

        our $AUTOLOAD;
        sub AUTOLOAD {
            my ($self) = @_;
            my $name = $AUTOLOAD =~ s/.*:://r;
            Perl6::Object::call_method($name, @_);
        }
    ]);
}

method sv_refcnt_dec($obj) {
    p5_sv_refcnt_dec($!p5, $obj);
}

method rebless(Perl5Object $obj) {
    p5_rebless_object($!p5, $obj.ptr);
}

submethod DESTROY {
    p5_destruct_perl($!p5) if $!p5;
    $!p5 = Perl5Interpreter;
}

class Perl5Object {
    has OpaquePointer $.ptr;
    has Inline::Perl5 $.perl5;

    Perl5Object.^add_fallback(-> $, $ { True },
        method ($name ) {
            -> \self, |args {
                $.perl5.invoke($.ptr, $name, self, args.list);
            }
        }
    );

    method sink() { self }

    method DESTROY {
        $.perl5.sv_refcnt_dec($.ptr) if $.ptr;
        $.ptr = Any;
    }
}

method BUILD {
    $!p5 = p5_init_perl();
    self.init_callbacks();

    &!call_method = sub (Int $index, Str $name, OpaquePointer $args) returns OpaquePointer {
        my $p6obj = $objects.get($index);
        my @retvals = $p6obj."$name"(|self.p5_array_to_p6_array($args));
        return self.p6_to_p5(@retvals);
        CATCH { default { say $_; } }
    }
}

role Perl5Parent[$package] {
    has $.parent is rw;
    has Inline::Perl5 $.perl5;
    my $fallback_added = 0;

    submethod BUILD(:$perl5) {
        $!perl5 = $perl5;
        $!parent = $perl5.invoke($package, 'new');
        $perl5.rebless($!parent);

        unless $fallback_added {
            $fallback_added = 1;
            ::?CLASS.^add_fallback(-> $, $ { True },
                method ($name) {
                    -> \self, |args {
                        $.parent.perl5.invoke($package, $.parent.ptr, $name, self, args.list);
                    }
                }
            );
        }
    }
}

END {
    p5_terminate;
}
