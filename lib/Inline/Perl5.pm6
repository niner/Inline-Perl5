class Inline::Perl5;

class Perl5Interpreter is repr('CPointer') { }

has Perl5Interpreter $!p5;
has Bool $!external_p5 = False;
has &!call_method;
has &!call_callable;

use NativeCall;

sub native(Sub $sub) {
    my $so = 'p5helper.so';
    state Str $path;
    unless $path {
        for @*INC {
            if "$_/Inline/$so".IO ~~ :f {
                $path = "$_/Inline/$so";
                last;
            }
        }
    }
    unless $path {
        die "unable to find Inline/$so IN \@*INC";
    }
    trait_mod:<is>($sub, :native($path));
}

class Perl5Object { ... }
class Perl5Callable { ... }

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
        @!objects[$index];
    }

    method free(Int $index) {
        @!objects[$index] = $!last_free;
        $!last_free = $index;
    }
}

sub p5_init_perl()
    returns Perl5Interpreter { ... }
    native(&p5_init_perl);
sub p5_inline_perl6_xs_init(Perl5Interpreter)
    { ... }
    native(&p5_inline_perl6_xs_init);
sub p5_SvIOK(Perl5Interpreter, OpaquePointer)
    returns int32 { ... } # should be uint32 once that's supported
    native(&p5_SvIOK);
sub p5_SvNOK(Perl5Interpreter, OpaquePointer)
    returns int32 { ... } # should be uint32 once that's supported
    native(&p5_SvNOK);
sub p5_SvPOK(Perl5Interpreter, OpaquePointer)
    returns int32 { ... } # should be uint32 once that's supported
    native(&p5_SvPOK);
sub p5_sv_utf8(Perl5Interpreter, OpaquePointer)
    returns int32 { ... } # should be uint32 once that's supported
    native(&p5_sv_utf8);
sub p5_is_array(Perl5Interpreter, OpaquePointer)
    returns int { ... }
    native(&p5_is_array);
sub p5_is_hash(Perl5Interpreter, OpaquePointer)
    returns int { ... }
    native(&p5_is_hash);
sub p5_is_undef(Perl5Interpreter, OpaquePointer)
    returns int { ... }
    native(&p5_is_undef);
sub p5_sv_to_buf(Perl5Interpreter, OpaquePointer, CArray[CArray[int8]])
    returns Int { ... }
    native(&p5_sv_to_buf);
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
sub p5_float_to_sv(Perl5Interpreter, num64)
    returns OpaquePointer { ... }
    native(&p5_float_to_sv);
sub p5_str_to_sv(Perl5Interpreter, Str)
    returns OpaquePointer { ... }
    native(&p5_str_to_sv);
sub p5_buf_to_sv(Perl5Interpreter, Int, CArray[uint8])
    returns OpaquePointer { ... }
    native(&p5_buf_to_sv);
sub p5_av_top_index(Perl5Interpreter, OpaquePointer)
    returns int32 { ... }
    native(&p5_av_top_index);
sub p5_av_fetch(Perl5Interpreter, OpaquePointer, int32)
    returns OpaquePointer { ... }
    native(&p5_av_fetch);
sub p5_av_push(Perl5Interpreter, OpaquePointer, OpaquePointer)
    { ... }
    native(&p5_av_push);
sub p5_hv_iterinit(Perl5Interpreter, OpaquePointer)
    returns int32 { ... }
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
sub p5_sv_reftype(Perl5Interpreter, OpaquePointer)
    returns Str { ... }
    native(&p5_sv_reftype);
sub p5_hv_store(Perl5Interpreter, OpaquePointer, Str, OpaquePointer)
    { ... }
    native(&p5_hv_store);
sub p5_call_function(Perl5Interpreter, Str, int, CArray[OpaquePointer])
    returns OpaquePointer { ... }
    native(&p5_call_function);
sub p5_call_method(Perl5Interpreter, Str, OpaquePointer, Str, int, CArray[OpaquePointer])
    returns OpaquePointer { ... }
    native(&p5_call_method);
sub p5_call_package_method(Perl5Interpreter, Str, Str, int, CArray[OpaquePointer])
    returns OpaquePointer { ... }
    native(&p5_call_package_method);
sub p5_call_code_ref(Perl5Interpreter, OpaquePointer, int, CArray[OpaquePointer])
    returns OpaquePointer { ... }
    native(&p5_call_code_ref);
sub p5_rebless_object(Perl5Interpreter, OpaquePointer)
    { ... }
    native(&p5_rebless_object);
sub p5_destruct_perl(Perl5Interpreter)
    { ... }
    native(&p5_destruct_perl);
sub p5_sv_iv(Perl5Interpreter, OpaquePointer)
    returns Int { ... }
    native(&p5_sv_iv);
sub p5_sv_nv(Perl5Interpreter, OpaquePointer)
    returns num64 { ... }
    native(&p5_sv_nv);
sub p5_is_object(Perl5Interpreter, OpaquePointer)
    returns int { ... }
    native(&p5_is_object);
sub p5_is_sub_ref(Perl5Interpreter, OpaquePointer)
    returns int { ... }
    native(&p5_is_sub_ref);
sub p5_eval_pv(Perl5Interpreter, Str, int32)
    returns OpaquePointer { ... }
    native(&p5_eval_pv);
sub p5_err_sv(Perl5Interpreter)
    returns OpaquePointer { ... }
    native(&p5_err_sv);
sub p5_wrap_p6_object(Perl5Interpreter, Int, OpaquePointer, &call_method (Int, Str, OpaquePointer, OpaquePointer --> OpaquePointer), &free_p6_object (Int))
    returns OpaquePointer { ... }
    native(&p5_wrap_p6_object);
sub p5_wrap_p6_callable(Perl5Interpreter, Int, OpaquePointer, &call (Int, OpaquePointer, OpaquePointer --> OpaquePointer), &free_p6_object (Int))
    returns OpaquePointer { ... }
    native(&p5_wrap_p6_callable);
sub p5_is_wrapped_p6_object(Perl5Interpreter, OpaquePointer)
    returns int { ... }
    native(&p5_is_wrapped_p6_object);
sub p5_unwrap_p6_object(Perl5Interpreter, OpaquePointer)
    returns Int { ... }
    native(&p5_unwrap_p6_object);
sub p5_use(Perl5Interpreter, OpaquePointer)
    { ... }
    native(&p5_use);
sub p5_terminate()
    { ... }
    native(&p5_terminate);

multi method p6_to_p5(Int:D $value) returns OpaquePointer {
    p5_int_to_sv($!p5, $value);
}
multi method p6_to_p5(Num:D $value) returns OpaquePointer {
    p5_float_to_sv($!p5, $value);
}
multi method p6_to_p5(Rat:D $value) returns OpaquePointer {
    p5_float_to_sv($!p5, $value.Num);
}
multi method p6_to_p5(Str:D $value) returns OpaquePointer {
    p5_str_to_sv($!p5, $value);
}
multi method p6_to_p5(blob8:D $value) returns OpaquePointer {
    my $array = CArray[uint8].new();
    for ^$value.elems {
        $array[$_] = $value[$_];
    }
    p5_buf_to_sv($!p5, $value.elems, $array);
}
multi method p6_to_p5(Perl5Object $value) returns OpaquePointer {
    p5_sv_refcnt_inc($!p5, $value.ptr);
    $value.ptr;
}
multi method p6_to_p5(OpaquePointer $value) returns OpaquePointer {
    $value;
}
multi method p6_to_p5(Any:U $value) returns OpaquePointer {
    p5_undef($!p5);
}

my $objects = ObjectKeeper.new;

sub free_p6_object(Int $index) {
    $objects.free($index);
}

multi method p6_to_p5(Perl5Object:D $value, OpaquePointer $inst) {
    p5_sv_refcnt_inc($!p5, $inst);
    $inst;
}
multi method p6_to_p5(Any:D $value, OpaquePointer $inst = OpaquePointer) {
    my $index = $objects.keep($value);

    p5_wrap_p6_object(
        $!p5,
        $index,
        $inst,
        &!call_method,
        &free_p6_object,
    );
}
multi method p6_to_p5(Callable:D $value, OpaquePointer $inst = OpaquePointer) {
    my $index = $objects.keep($value);

    p5_wrap_p6_callable(
        $!p5,
        $index,
        $inst,
        &!call_callable,
        &free_p6_object,
    );
}
multi method p6_to_p5(Perl5Callable:D $value) returns OpaquePointer {
    p5_sv_refcnt_inc($!p5, $value.ptr);
    $value.ptr;
}
multi method p6_to_p5(Hash:D $value) returns OpaquePointer {
    my $hv = p5_newHV($!p5);
    for %$value -> $item {
        my $value = self.p6_to_p5($item.value);
        p5_hv_store($!p5, $hv, $item.key, $value);
    }
    p5_newRV_noinc($!p5, $hv);
}
multi method p6_to_p5(Positional:D $value) returns OpaquePointer {
    my $av = p5_newAV($!p5);
    for @$value -> $item {
        p5_av_push($!p5, $av, self.p6_to_p5($item));
    }
    p5_newRV_noinc($!p5, $av);
}

method p5_sv_reftype(OpaquePointer $sv) {
    return p5_sv_reftype($!p5, $sv);
}

method p5_array_to_p6_array(OpaquePointer $sv) {
    my $av = p5_sv_to_av($!p5, $sv);
    my $av_len = p5_av_top_index($!p5, $av);

    my $arr = [];
    loop (my int $i = 0; $i <= $av_len; $i = $i + 1) {
        $arr.push(self.p5_to_p6(p5_av_fetch($!p5, $av, $i)));
    }
    $arr;
}
method !p5_hash_to_p6_hash(OpaquePointer $sv) {
    my OpaquePointer $hv = p5_sv_to_hv($!p5, $sv);

    my int32 $len = p5_hv_iterinit($!p5, $hv);

    my $hash = {};

    for 0 .. $len - 1 {
        my OpaquePointer $next = p5_hv_iternext($!p5, $hv);
        my OpaquePointer $key = p5_hv_iterkeysv($!p5, $next);
        die 'Hash entry without key!?' unless $key;
        my Str $p6_key = p5_sv_to_char_star($!p5, $key);
        my $val = self.p5_to_p6(p5_hv_iterval($!p5, $hv, $next));
        $hash{$p6_key} = $val;
    }

    $hash;
}

method p5_to_p6(OpaquePointer $value) {
    return Any unless defined $value;
    if p5_is_object($!p5, $value) {
        if p5_is_wrapped_p6_object($!p5, $value) {
            return $objects.get(p5_unwrap_p6_object($!p5, $value));
        }
        else {
            p5_sv_refcnt_inc($!p5, $value);
            return Perl5Object.new(perl5 => self, ptr => $value);
        }
    }
    elsif p5_is_sub_ref($!p5, $value) {
        p5_sv_refcnt_inc($!p5, $value);
        return Perl5Callable.new(perl5 => self, ptr => $value);
    }
    elsif p5_SvNOK($!p5, $value) {
        return p5_sv_nv($!p5, $value);
    }
    elsif p5_SvIOK($!p5, $value) {
        return p5_sv_iv($!p5, $value);
    }
    elsif p5_SvPOK($!p5, $value) {
        if p5_sv_utf8($!p5, $value) {
            return p5_sv_to_char_star($!p5, $value);
        }
        else {
            my $string_ptr = CArray[CArray[int8]].new;
            $string_ptr[0] = CArray[int8];
            my $len = p5_sv_to_buf($!p5, $value, $string_ptr);
            my $buf = Buf.new;
            for 0..^$len {
                $buf[$_] = $string_ptr[0][$_];
            }
            return $buf;
        }
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

method handle_p5_exception() is hidden_from_backtrace {
    if my $error = self.p5_to_p6(p5_err_sv($!p5)) {
        die $error;
    }
}

method run($perl) {
    my $res = p5_eval_pv($!p5, $perl, 0);
    self.handle_p5_exception();
    self.p5_to_p6($res);
}

method !setup_arguments(@args) {
    my $len = @args.elems;
    my @svs := CArray[OpaquePointer].new();
    loop (my Int $i = 0; $i < $len; $i = $i + 1) {
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
    loop (my int32 $i = 0; $i <= $av_len; $i = $i + 1) {
        @retvals.push(self.p5_to_p6(p5_av_fetch($!p5, $av, $i)));
    }
    p5_sv_refcnt_dec($!p5, $av);
    @retvals;
}

method call(Str $function, *@args) {
    my $av = p5_call_function($!p5, $function, |self!setup_arguments(@args));
    self.handle_p5_exception();
    self!unpack_return_values($av);
}

multi method invoke(Str $package, Str $function, *@args) {
    my $av = p5_call_package_method($!p5, $package, $function, |self!setup_arguments(@args));
    self.handle_p5_exception();
    self!unpack_return_values($av);
}

multi method invoke(OpaquePointer $obj, Str $function, *@args) {
    self.invoke(Str, $obj, $function, @args.list);
}

multi method invoke(Str $package, OpaquePointer $obj, Str $function, *@args) {
    my $len = @args.elems;
    my @svs := CArray[OpaquePointer].new();
    @svs[0] = self.p6_to_p5(@args[0], $obj);
    loop (my Int $i = 1; $i < $len; $i++) {
        @svs[$i] = self.p6_to_p5(@args[$i]);
    }
    my $av = p5_call_method($!p5, $package, $obj, $function, $len, @svs);
    self.handle_p5_exception();
    self!unpack_return_values($av);
}

method execute(OpaquePointer $code_ref, *@args) {
    my $av = p5_call_code_ref($!p5, $code_ref, |self!setup_arguments(@args));
    self.handle_p5_exception();
    self!unpack_return_values($av);
}

class Perl6Callbacks {
    has $.p5;
    method create($package, $code) {
        EVAL "class GLOBAL::$package \{\n$code\n\}";
        return;
    }
    method run($code) {
        return $!p5.p6_to_p5(EVAL $code);
    }
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

        sub can {
            return Perl6::Object::call_method('can', @_);
        }

        package Perl6::Callable;

        use overload '&{}' => \&deref_call, fallback => 1;

        sub deref_call {
            my ($self) = @_;
            return sub {
                $self->call(@_);
            }
        }

        package v6;

        my $package;
        my $p6;

        sub init {
            ($p6) = @_;
        }

        sub uninit {
            undef $p6;
        }

        sub run {
            my ($code) = @_;
            return $p6->run($code);
        }

        sub import {
            $package = scalar caller;
        }

        use Filter::Simple sub {
            $p6->create($package, $_);
            $_ = '1;';
        };

        $INC{'v6.pm'} = undef;

        1;
    ]);

    self.call('v6::init', Perl6Callbacks.new(:p5(self)));

    if $!external_p5 {
        p5_inline_perl6_xs_init($!p5);
    }
}

method sv_refcnt_dec($obj) {
    p5_sv_refcnt_dec($!p5, $obj);
}

method rebless(Perl5Object $obj) {
    p5_rebless_object($!p5, $obj.ptr);
}

my %perl5_for_imported_packages;
class Perl5Package {
    method new(*@args) {
        return %perl5_for_imported_packages{self.perl.Str}.invoke(self.perl.Str, 'new', @args.list);
    }

    method FALLBACK($name, *@args) {
        %perl5_for_imported_packages{self.perl.Str}.invoke(self.perl.Str, $name, @args.list);
    }
}

method require(Str $module) {
    my $module_sv = self.p6_to_p5($module);
    p5_use($!p5, $module_sv);

    EVAL "class GLOBAL::$module is Perl5Package \{ \}";

    ::($module).WHO<EXPORT> := Metamodel::PackageHOW.new();
    ::($module).WHO<&EXPORT> := sub EXPORT(*@args) {
        self.invoke($module, 'import', @args.list);
        return EnumMap.new();
    };
    my $symbols = self.run('[ grep { *{"' ~ $module ~ '::$_"}{CODE} } keys %' ~ $module ~ ':: ]');
    for @$symbols -> $name {
        ::($module).WHO{"&$name"} := sub (*@args) {
            self.call("{$module}::$name", @args.list);
        }
    }

    %perl5_for_imported_packages{$module} = self;
}

method use(Str $module, *@args) {
    self.require($module);
    self.invoke($module, 'import', @args.list);
}

submethod DESTROY {
    p5_destruct_perl($!p5) if $!p5 and not $!external_p5;
    $!p5 = Perl5Interpreter;
}

class Perl5Object {
    has OpaquePointer $.ptr;
    has Inline::Perl5 $.perl5;

    method sink() { self }

    method DESTROY {
        $!perl5.sv_refcnt_dec($!ptr) if $!ptr;
        $!ptr = OpaquePointer;
    }
}

class Perl5Callable {
    has OpaquePointer $.ptr;
    has Inline::Perl5 $.perl5;

    method postcircumfix:<( )>(\args) {
        $.perl5.execute($.ptr, |args);
    }

    method DESTROY {
        $!perl5.sv_refcnt_dec($!ptr) if $!ptr;
        $!ptr = OpaquePointer;
    }
}

my $default_perl5;
method BUILD(:$p5) {
    $!p5 = $p5 // p5_init_perl();
    $!external_p5 = defined $p5;

    &!call_method = sub (Int $index, Str $name, OpaquePointer $args, OpaquePointer $err) returns OpaquePointer {
        my $p6obj = $objects.get($index);
        my @retvals = $p6obj."$name"(|self.p5_array_to_p6_array($args));
        return self.p6_to_p5(@retvals);
        CATCH {
            default {
                nativecast(CArray[OpaquePointer], $err)[0] = self.p6_to_p5($_);
                return OpaquePointer;
            }
        }
    }

    &!call_callable = sub (Int $index, OpaquePointer $args, OpaquePointer $err) returns OpaquePointer {
        my $callable = $objects.get($index);
        my @retvals = $callable(|self.p5_array_to_p6_array($args));
        return self.p6_to_p5(@retvals);
        CATCH {
            default {
                nativecast(CArray[OpaquePointer], $err)[0] = self.p6_to_p5($_);
                return OpaquePointer;
            }
        }
    }

    self.init_callbacks();

    $default_perl5 //= self;
}

role Perl5Parent[$package] {
    has $.parent;

    submethod BUILD(:$perl5, :$parent?, *@args, *%args) {
        $!parent = $parent // $perl5.invoke($package, 'new', |@args, |%args.kv);
        $perl5.rebless($!parent);
    }

    ::?CLASS.HOW.add_fallback(::?CLASS, -> $, $ { True },
        method ($name) {
            -> \self, |args {
                $.parent.perl5.invoke($package, $.parent.ptr, $name, self, args.list);
            }
        }
    );
}

BEGIN {
    Perl5Object.^add_fallback(-> $, $ { True },
        method ($name ) {
            -> \self, |args {
                $.perl5.invoke($.ptr, $name, self, args.list);
            }
        }
    );
}

class Perl5ModuleLoader {
    method load_module($module_name, %opts, *@GLOBALish, :$line, :$file) {
        $default_perl5 //= Inline::Perl5.new();
        $default_perl5.require($module_name);

        return ::($module_name).WHO;
    }
}

nqp::getcurhllsym('ModuleLoader').p6ml.register_language_module_loader('Perl5', Perl5ModuleLoader);

END {
    p5_terminate;
}
