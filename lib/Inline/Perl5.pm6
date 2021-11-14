class Inline::Perl5 {

use MONKEY-SEE-NO-EVAL;
use Inline::Language::ObjectKeeper;
use Inline::Perl5::Interpreter;
use Inline::Perl5::Array;
use Inline::Perl5::Attributes;
use Inline::Perl5::Caller;
use Inline::Perl5::ClassHOW;
use Inline::Perl5::ClassHOW::ThreadSafe;
use Inline::Perl5::Hash;
use Inline::Perl5::Callable;
use Inline::Perl5::TypeGlob;
use Inline::Perl5::Exception;

has Inline::Perl5::Interpreter $!p5;
has Bool $!external_p5 = False;
has Bool $!scalar_context = False;
has Bool $!default;
has %!loaded_modules;
has @!required_modules;
has $!objects;
has $.thread-id;

my $default_perl5;
our $thread-safe = False;

my constant $broken-rakudo = (
    $*PERL.compiler.name eq 'rakudo'
    and $*PERL.compiler.version before v2020.05.1.261.g.169.f.63.d.90
);

# I'd like to call this from Inline::Perl5::Interpreter
# But it raises an error in the END { ... } call
use NativeCall;
my constant $p5helper = %?RESOURCES<libraries/p5helper>;
sub p5_terminate() is native($p5helper) { ... }

method interpreter() {
    $!p5
}

method object_keeper() {
    $!objects
}

multi method p6_to_p5(Int:D $value) returns Pointer {
    $!p5.p5_int_to_sv($value);
}
multi method p6_to_p5(Num:D $value) returns Pointer {
    $!p5.p5_float_to_sv($value);
}
multi method p6_to_p5(Rat:D $value) returns Pointer {
    $!p5.p5_float_to_sv($value.Num);
}
my constant $encoding-registry = try ::("Encoding::Registry");
my constant $utf8-encoder = $encoding-registry.^can('find')
    ?? $encoding-registry.find('utf8').encoder(:!replacement, :!translate-nl) # on 6.d
    !! class { method encode-chars($str) { $str.encode } }.new; # fallback for 6.c
multi method p6_to_p5(Str:D $value) returns Pointer {
    my $buf = $utf8-encoder.encode-chars($value);
    $!p5.p5_str_to_sv($buf.elems, $buf);
}
multi method p6_to_p5(IntStr:D $value) returns Pointer {
    $!p5.p5_int_to_sv($value.Int);
    # $!p5.p5_int_to_sv($value.Int);
}
multi method p6_to_p5(NumStr:D $value) returns Pointer {
    $!p5.p5_float_to_sv($value.Num);
}
multi method p6_to_p5(RatStr:D $value) returns Pointer {
    $!p5.p5_float_to_sv($value.Num);
}
multi method p6_to_p5(blob8:D $value) returns Pointer {
    $!p5.p5_buf_to_sv($value.elems, $value);
}
multi method p6_to_p5(Capture:D $value where $value.elems == 1) returns Pointer {
    $!p5.p5_sv_to_ref(self.p6_to_p5($value[0]));
}
multi method p6_to_p5(Pointer $value) returns Pointer {
    $value;
}
multi method p6_to_p5(Nil) returns Pointer {
    Pointer.new(0);
}
multi method p6_to_p5(Any:U $value) returns Pointer {
    $!p5.p5_undef();
}

method unwrap-perl5-object($value) {
    my $o = $value.wrapped-perl5-object;
    $!p5.p5_is_live_wrapped_p6_object($o)
        ?? $!p5.p5_newRV_inc($o)
        !! $!p5.p5_add_magic($o, $!objects.keep($value))
}

multi method p6_to_p5(Inline::Perl5::WrapperClass $value) {
    my $o = $value.wrapped-perl5-object;
    $!p5.p5_is_live_wrapped_p6_object($o)
        ?? $!p5.p5_newRV_inc($o)
        !! $!p5.p5_add_magic($o, $!objects.keep($value))
}

multi method p6_to_p5(Any:D $value) {
    my $index = $!objects.keep($value);

    $!p5.p5_wrap_p6_object(
        $index,
        Pointer,
    )
}
multi method p6_to_p5(Callable:D $value, Pointer $inst = Pointer) {
    my $index = $!objects.keep($value);

    $!p5.p5_wrap_p6_callable(
        $index,
        $inst,
    );
}
multi method p6_to_p5(Inline::Perl5::Callable:D $value) returns Pointer {
    $!p5.p5_sv_refcnt_inc($value.ptr);
    $value.ptr;
}
multi method p6_to_p5(Hash:D $value) returns Pointer {
    my $index = $!objects.keep($value);

    return $!p5.p5_wrap_p6_hash(
        $index,
    );
}
multi method p6_to_p5(Map:D $value) returns Pointer {
    my $hv = $!p5.p5_newHV();
    for %$value -> $item {
        my $value = self.p6_to_p5($item.value);
        $!p5.p5_hv_store($hv, $item.key, $value);
    }
    $!p5.p5_newRV_noinc($hv);
}
multi method p6_to_p5(Inline::Perl5::Hash:D $value) returns Pointer {
    $!p5.p5_newRV_inc($value.hv)
}
multi method p6_to_p5(Inline::Perl5::Array:D $value) returns Pointer {
    $!p5.p5_newRV_inc($value.av)
}
multi method p6_to_p5(Inline::Perl5::Exception:D $value) returns Pointer {
    self.p6_to_p5($value.payload)
}
multi method p6_to_p5(Positional:D $value) returns Pointer {
    my $av = $!p5.p5_newAV();
    for @$value -> $item {
        $!p5.p5_av_push($av, self.p6_to_p5($item));
    }
    $!p5.p5_newRV_inc($av);
}
multi method p6_to_p5(IO::Handle:D $value) returns Pointer {
    my $index = $!objects.keep($value);

    $!p5.p5_wrap_p6_handle(
        $index,
        Any,
    );
}
multi method p6_to_p5(Regex:D $value) {
    my $index = $!objects.keep($value);
    my @svs := CArray[Pointer].new();
    @svs[0] = $!p5.p5_wrap_p6_object(
        $index,
        Pointer,
    );

    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my $av = $!p5.p5_call_package_method(
        'v6',
        'wrap_regex',
        1,
        @svs,
        $retvals,
        $err,
        $type,
    );
    self.handle_p5_exception() if $err;
    self.p6_to_p5(self.unpack_return_values($av, $retvals, $type))
}
multi method p6_to_p5(Inline::Perl5::TypeGlob:D $value) returns Pointer {
    $value.gv
}

method p5_sv_rv(Pointer $sv) {
    return $!p5.p5_sv_rv($sv);
}

method p5_sv_reftype(Pointer $sv) {
    return $!p5.p5_sv_reftype($sv);
}

method p5_array_to_p6_array(Pointer $sv) {
    my $av = $!p5.p5_sv_to_av($sv);
    my int32 $av_len = $!p5.p5_av_top_index($av);

    my $arr = [];
    loop (my int32 $i = 0; $i <= $av_len; $i = $i + 1) {
        $arr.push(self.p5_to_p6($!p5.p5_av_fetch($av, $i)));
    }
    $arr;
}


method !p5_hash_to_writeback_p6_hash(Pointer $sv) {
    my Pointer $hv = $!p5.p5_sv_to_hv($sv);

    Inline::Perl5::Hash.new(ip5 => self, p5 => $!p5, :$hv)
}

method !p5_array_to_writeback_p6_array(Pointer $sv) {
    my Pointer $av = $!p5.p5_sv_to_av_inc($sv);

    Inline::Perl5::Array.new(ip5 => self, p5 => $!p5, :$av)
}

method !p5_hash_to_p6_hash(Pointer $sv) {
    my Pointer $hv = $!p5.p5_sv_to_hv($sv);

    my int32 $len = $!p5.p5_hv_iterinit($hv);

    my $hash = {};

    for 0 .. $len - 1 {
        my Pointer $next = $!p5.p5_hv_iternext($hv);
        my Pointer $key = $!p5.p5_hv_iterkeysv($next);
        die 'Hash entry without key!?' unless $key;
        my Str $p6_key = $!p5.p5_sv_to_char_star($key);
        my $val = self.p5_to_p6($!p5.p5_hv_iterval($hv, $next));
        $hash{$p6_key} = $val;
    }

    $hash
}

method !p5_scalar_ref_to_capture(Pointer $sv) {
    return \(self.p5_to_p6($!p5.p5_sv_rv($sv)));
}

multi method p5_to_p6(Pointer:U \value --> Any) {
}

my class Undef { };
my class Blessed { };
my class TypeGlob { };

multi method p5_to_p6(Pointer:D \value) {
    self.p5_to_p6_type(value, $!p5.p5_get_type(value))
}

multi method p5_to_p6_type(Pointer:U \value, \type --> Any) {
}

multi method p5_to_p6_type(Pointer:D \value, 4) {
    $!p5.p5_sv_iv(value);
}

multi method p5_to_p6_type(Pointer:D \value, 5) {
    my $p5 := $!p5;
    if $p5.p5_sv_utf8(value) {
        $p5.p5_sv_to_char_star(value);
    }
    else {
        my $string_ptr = CArray[CArray[int8]].new;
        $string_ptr[0] = CArray[int8];
        my $len = $p5.p5_sv_to_buf(value, $string_ptr);
        my $string := $string_ptr[0];
        blob8.new(do for ^$len { $string.AT-POS($_) });
    }
}

multi method p5_to_p6_type(Pointer:D \value, 3) {
    $!p5.p5_sv_nv(value);
}

multi method p5_to_p6_type(Pointer:D \value, 6) {
    self!p5_array_to_writeback_p6_array(value);
}

multi method p5_to_p6_type(Pointer:D \value, 7) {
    self!p5_hash_to_writeback_p6_hash(value);
}

multi method p5_to_p6_type(Pointer:D \value, 8) {
    $!objects.get($!p5.p5_unwrap_p6_hash(value));
}

multi method p5_to_p6_type(Pointer:D \value, 9) {
    Any
}

multi method p5_to_p6_type(Pointer:D \value, 2) {
    $!p5.p5_sv_refcnt_inc(value);
    Inline::Perl5::Callable.new(perl5 => self, ptr => value);
}

multi method p5_to_p6_type(Pointer:D \value, 10) {
    self!p5_scalar_ref_to_capture(value);
}

multi method p5_to_p6_type(Pointer:D \value, 0) {
    my $type = $!p5.p5_get_type(value);
    die "Unsupported type {value} ($type) in p5_to_p6";
}

multi method p5_to_p6_type(Pointer:D \value, 1) {
    if $!p5.p5_is_wrapped_p6_object(value) {
        $!objects.get($!p5.p5_unwrap_p6_object(value));
    }
    else {
        $!p5.p5_sv_refcnt_inc(value);
        my $stash-name = self.stash-name(value);

        my $class;
        if %!loaded_modules{$stash-name}:exists {
            $class := %!loaded_modules{$stash-name};
        }
        else {
            $class := self.create_wrapper_class($stash-name);
        }
        my $obj = $!p5.p5_sv_rv(value);
        $!p5.p5_sv_refcnt_inc($obj);
        $!p5.p5_sv_refcnt_dec(value);
        $class.bless(:wrapped-perl5-object($obj), :inline-perl5(self));
    }
}

multi method p5_to_p6_type(Pointer:D \value, 11) {
    $!p5.p5_sv_refcnt_inc(value);
    Inline::Perl5::TypeGlob.new(:ip5(self), :gv(value))
}

method handle_p5_exception() is hidden-from-backtrace {
    with my $error = self.p5_to_p6($!p5.p5_err_sv()) {
        if $error.WHAT !=== Str || $error ne '' {
            if $error ~~ Exception {
                $error.rethrow;
            }
            else {
                die $error.WHAT === Str ?? $error !! Inline::Perl5::Exception.new(:payload($error));
            }
        }
    }
}

method compile-to-block-end($perl) {
    my @optree := CArray[Pointer].new;
    @optree[0] = Pointer;
    my @stash := CArray[Pointer].new;
    @stash[0] = Pointer;
    my $end = $!p5.p5_compile_sv(self.p6_to_p5($perl), @optree, @stash);
    $end, @optree[0], self.p5_to_p6(@stash[0])
}

method runops(Pointer $ops --> Nil) {
    $!p5.p5_runops($ops);
}

method run($perl) {
    my $res = $!p5.p5_eval_pv($perl, 0);
    self.handle_p5_exception();
    my $retval = self.p5_to_p6($res);
    $!p5.p5_sv_refcnt_dec($res);
    $retval
}

multi method setup_arguments(@args) {
    my @svs := CArray[Pointer].new();
    my Int $i = 0;
    for @args {
        if $_.WHAT =:= Pair {
            @svs[$i++] = self.p6_to_p5($_.key);
            @svs[$i++] = self.p6_to_p5($_.value);
        }
        else {
            @svs[$i++] = self.p6_to_p5($_);
        }
    }
    return $i, @svs;
}

multi method setup_arguments(@args, %args) {
    my @svs := CArray[Pointer].new();
    my Int $j = 0;
    for @args {
        if $_.WHAT =:= Pair {
            @svs[$j++] = self.p6_to_p5($_.key);
            @svs[$j++] = self.p6_to_p5($_.value);
        }
        else {
            @svs[$j++] = self.p6_to_p5($_);
        }
    }
    for %args {
        @svs[$j++] = self.p6_to_p5($_.key);
        @svs[$j++] = self.p6_to_p5($_.value);
    }
    return $j, @svs;
}

multi method unpack_return_values(Pointer:U \av, int32 \count, int32 \type --> Nil) {
}

multi method unpack_return_values(Pointer:D \av, int32 \count, int32 \type) {
    if count == 1 {
        my \retval = self.p5_to_p6_type(av, type);
        $!p5.p5_sv_refcnt_dec(av);
        retval
    }
    else {
        Inline::Perl5::Array.new(ip5 => self, p5 => $!p5, :av(av))
    }
}

method call(Str $function, **@args, *%args) {
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my $av = $!p5.p5_call_function(
        $function,
        |self.setup_arguments(@args, %args),
        $retvals,
        $err,
        $type,
    );
    self.handle_p5_exception() if $err;
    self.unpack_return_values($av, $retvals, $type);
}

method call-args(Str $function, Capture \args) {
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my $av = $!p5.p5_call_function(
        $function,
        |self.setup_arguments(args.list, args.hash),
        $retvals,
        $err,
        $type,
    );
    self.handle_p5_exception() if $err;
    self.unpack_return_values($av, $retvals, $type);
}

method call-simple-args(Str $function, **@args) {
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my Int $j = 0;
    my @svs := CArray[Pointer].new();
    @svs.ASSIGN-POS($j++, self.p6_to_p5($_)) for @args;
    my $av = $!p5.p5_call_function(
        $function,
        $j,
        @svs,
        $retvals,
        $err,
        $type,
    );
    self.handle_p5_exception() if $err;
    self.unpack_return_values($av, $retvals, $type);
}

multi method invoke(Str $package, Str $function, **@args, *%args) {
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my $av = $!p5.p5_call_package_method(
        $package,
        $function,
        |self.setup_arguments(@args, %args),
        $retvals,
        $err,
        $type,
    );
    self.handle_p5_exception() if $err;
    self.unpack_return_values($av, $retvals, $type);
}

multi method invoke(Any:U $package, Str $base_package, Str $function, **@args, *%args) {
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my $av = $!p5.p5_call_inherited_package_method(
        $package.^name,
        $base_package,
        $function,
        |self.setup_arguments(@args, %args),
        $retvals,
        $err,
        $type,
    );
    if $type == -1 {
        # need to create the P5 wrapper package
        my @methods = $package.^methods(:local)
            .map(*.name)
            .grep(/^\w+$/)
            .grep({$_ ne 'DESTROY' and $_ ne 'isa' and $_ ne 'can'})
            .unique;
        self.run: "
            package {$package.^name} \{
                our @ISA = qw(Perl6::Object $base_package);
                sub DESTROY \{ \$_[0]->{$base_package}::DESTROY; \}
                {
                    join "\n", @methods.map: -> $name {
                        qq[sub $name \{
                            Perl6::Object::call_method('$name', \@_);
                        \}]
                    }
                }
            \}
        ";
        $av = $!p5.p5_call_inherited_package_method(
            $package.^name,
            $base_package,
            $function,
            |self.setup_arguments(@args, %args),
            $retvals,
            $err,
            $type,
        );
        %!loaded_modules{$package.^name} := $package;
    }
    self.handle_p5_exception() if $err;
    self.unpack_return_values($av, $retvals, $type);
}

multi method invoke(Pointer $obj, Str $function) {
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my $av = $!p5.p5_call_method(
        $obj,
        0,
        $function,
        1,
        $obj,
        $retvals,
        $err,
        $type,
    );
    self.handle_p5_exception() if $err;
    self.unpack_return_values($av, $retvals, $type);
}

has %!gvs;
method look-up-method(Str $module, Str $name, Bool $local) {
    %!gvs{$module}{$name} //= $!p5.p5_look_up_package_method($module, $name, $local.Int)
}

method stash-name(Pointer $obj) {
    $!p5.p5_stash_name($obj)
}

method invoke-gv(Pointer $obj, Pointer $function) {
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my $av = $!p5.p5_call_gv(
        $function,
        1,
        $obj,
        $retvals,
        $err,
        $type,
    );
    self.handle_p5_exception() if $err;
    self.unpack_return_values($av, $retvals, $type);
}

method scalar-invoke-gv(Pointer $obj, Pointer $function) {
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my $av = $!p5.p5_scalar_call_gv(
        $function,
        1,
        $obj,
        $retvals,
        $err,
        $type,
    );
    self.handle_p5_exception() if $err;
    self.unpack_return_values($av, $retvals, $type);
}

method invoke-gv-simple-arg(Pointer $obj, Pointer $function, $arg) {
    my @svs := CArray[Pointer].new();
    @svs.ASSIGN-POS(0, $obj);
    @svs.ASSIGN-POS(1, self.p6_to_p5($arg));
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my $av = $!p5.p5_call_gv(
        $function,
        2,
        nativecast(Pointer, @svs),
        $retvals,
        $err,
        $type,
    );
    self.handle_p5_exception() if $err;
    self.unpack_return_values($av, $retvals, $type);
}

method invoke-gv-arg(Pointer $obj, Pointer $function, $arg) {
    my @svs := CArray[Pointer].new();
    @svs[0] = $obj;
    if $arg.WHAT =:= Pair {
        @svs[1] = self.p6_to_p5($arg.key);
        @svs[2] = self.p6_to_p5($arg.value);
    }
    else {
        @svs[1] = self.p6_to_p5($arg);
    }
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my $av = $!p5.p5_call_gv(
        $function,
        2,
        nativecast(Pointer, @svs),
        $retvals,
        $err,
        $type,
    );
    self.handle_p5_exception() if $err;
    self.unpack_return_values($av, $retvals, $type);
}

method scalar-invoke-gv-arg(Pointer $obj, Pointer $function, $arg) {
    my @svs := CArray[Pointer].new();
    @svs[0] = $obj;
    if $arg.WHAT =:= Pair {
        @svs[1] = self.p6_to_p5($arg.key);
        @svs[2] = self.p6_to_p5($arg.value);
    }
    else {
        @svs[1] = self.p6_to_p5($arg);
    }
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my $av = $!p5.p5_scalar_call_gv(
        $function,
        2,
        nativecast(Pointer, @svs),
        $retvals,
        $err,
        $type,
    );
    self.handle_p5_exception() if $err;
    self.unpack_return_values($av, $retvals, $type);
}

method invoke-args(Pointer $obj, Str $function, Capture $args) {
    my @svs := CArray[Pointer].new();
    my Int $j = 0;
    @svs[$j++] = $obj;
    for $args.list {
        if $_.WHAT =:= Pair {
            @svs[$j++] = self.p6_to_p5($_.key);
            @svs[$j++] = self.p6_to_p5($_.value);
        }
        else {
            @svs[$j++] = self.p6_to_p5($_);
        }
    }
    for $args.hash {
        @svs[$j++] = self.p6_to_p5($_.key);
        @svs[$j++] = self.p6_to_p5($_.value);
    }
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my $av = $!p5.p5_call_method(
        $obj,
        0,
        $function,
        $j,
        nativecast(Pointer, @svs),
        $retvals,
        $err,
        $type,
    );
    self.handle_p5_exception() if $err;
    self.unpack_return_values($av, $retvals, $type);
}

method call-gv-args(Pointer $function, Capture $args) {
    my @svs := CArray[Pointer].new();
    my Int $j = 0;
    for $args.list {
        if $_.WHAT =:= Pair {
            @svs[$j++] = self.p6_to_p5($_.key);
            @svs[$j++] = self.p6_to_p5($_.value);
        }
        else {
            @svs[$j++] = self.p6_to_p5($_);
        }
    }
    for $args.hash {
        @svs[$j++] = self.p6_to_p5($_.key);
        @svs[$j++] = self.p6_to_p5($_.value);
    }
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my $av = $!p5.p5_call_gv(
        $function,
        $j,
        nativecast(Pointer, @svs),
        $retvals,
        $err,
        $type,
    );
    self.handle_p5_exception() if $err;
    self.unpack_return_values($av, $retvals, $type);
}

method invoke-gv-args(Pointer $obj, Pointer $function, Capture $args) {
    my @svs := CArray[Pointer].new();
    my Int $j = 0;
    @svs[$j++] = $obj;
    for $args.list {
        if $_.WHAT =:= Pair {
            @svs[$j++] = self.p6_to_p5($_.key);
            @svs[$j++] = self.p6_to_p5($_.value);
        }
        else {
            @svs[$j++] = self.p6_to_p5($_);
        }
    }
    for $args.hash {
        @svs[$j++] = self.p6_to_p5($_.key);
        @svs[$j++] = self.p6_to_p5($_.value);
    }
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my $av = $!p5.p5_call_gv(
        $function,
        $j,
        nativecast(Pointer, @svs),
        $retvals,
        $err,
        $type,
    );
    self.handle_p5_exception() if $err;
    self.unpack_return_values($av, $retvals, $type);
}

method scalar-invoke-gv-args(Pointer $obj, Pointer $function, Capture $args) {
    my @svs := CArray[Pointer].new();
    my Int $j = 0;
    @svs[$j++] = $obj;
    for $args.list {
        if $_.WHAT =:= Pair {
            @svs[$j++] = self.p6_to_p5($_.key);
            @svs[$j++] = self.p6_to_p5($_.value);
        }
        else {
            @svs[$j++] = self.p6_to_p5($_);
        }
    }
    for $args.hash {
        @svs[$j++] = self.p6_to_p5($_.key);
        @svs[$j++] = self.p6_to_p5($_.value);
    }
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my $av = $!p5.p5_scalar_call_gv(
        $function,
        $j,
        nativecast(Pointer, @svs),
        $retvals,
        $err,
        $type,
    );
    self.handle_p5_exception() if $err;
    self.unpack_return_values($av, $retvals, $type);
}

multi method invoke(Pointer $obj, Str $function, **@args, *%args) {
    my @svs := CArray[Pointer].new();
    my Int $j = 0;
    @svs[$j++] = $obj;
    for @args {
        if $_.WHAT =:= Pair {
            @svs[$j++] = self.p6_to_p5($_.key);
            @svs[$j++] = self.p6_to_p5($_.value);
        }
        else {
            @svs[$j++] = self.p6_to_p5($_);
        }
    }
    for %args {
        @svs[$j++] = self.p6_to_p5($_.key);
        @svs[$j++] = self.p6_to_p5($_.value);
    }
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my $av = $!p5.p5_call_method(
        $obj,
        0,
        $function,
        $j,
        nativecast(Pointer, @svs),
        $retvals,
        $err,
        $type,
    );
    self.handle_p5_exception() if $err;
    self.unpack_return_values($av, $retvals, $type);
}

method invoke-parent(Str $package, Pointer $obj, Bool $context, Str $function, @args, %args) {
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my ($j, @svs) := self.setup_arguments(@args, %args);
    my $av = $!p5.p5_call_parent_method(
        $package,
        $obj,
        $context ?? 1 !! 0,
        $function,
        $j,
        nativecast(Pointer, $j == 1 ?? @svs[0] !! @svs),
        $retvals,
        $err,
        $type,
    );
    self.handle_p5_exception() if $err;
    self.unpack_return_values($av, $retvals, $type);
}

method execute(Pointer $code_ref, **@args) {
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my $av = $!p5.p5_call_code_ref($code_ref, |self.setup_arguments(@args), $retvals, $err, $type);
    self.handle_p5_exception() if $err;
    self.unpack_return_values($av, $retvals, $type);
}

method at-key(Pointer $obj, \key) {
    my $buf = $utf8-encoder.encode-chars(key);
    self.p5_to_p6($!p5.p5_hv_fetch($obj, $buf.elems, $buf))
}

method global(Str $name) {
    self.p5_to_p6($!p5.p5_get_global($name))
}

method set_global(Str $name, $value) {
    $!p5.p5_set_global($name, self.p6_to_p5($value));
}

PROCESS::<%PERL5> := class :: does Associative {
    multi method AT-KEY($name) {
        Inline::Perl5.default_perl5.global($name)
    }
}.new;

method add-to-loaded-modules($package, $class) {
    %!loaded_modules{$package} := $class
}

method module-loaded($package) {
    %!loaded_modules{$package}:exists
}

method loaded-module($package) {
    %!loaded_modules{$package}
}

method required-modules() {
    @!required_modules
}

class Perl6Callbacks {
    has $.p5;
    method create_extension($package, $body) {
        require Inline::Perl5::Perl5Class;

        Inline::Perl5::Perl5Class::create-perl5-class($.p5, $package, $body);

        Nil
    }
    method run($code) {
        return EVAL $code;
        CONTROL {
            when CX::Warn {
                note $_.gist;
                $_.resume;
            }
        }
    }
    method call(Str $name, @args) {
        return &::($name)(|@args);
        CONTROL {
            when CX::Warn {
                note $_.gist;
                $_.resume;
            }
        }
    }
    method invoke(Str $package, Str $name, @args) {
        my %named = classify {$_.WHAT =:= Pair}, @args;
        %named<False> //= [];
        %named<True> //= [];
        my $class := ::($package);
        if $class.HOW.^isa(Metamodel::ClassHOW) and $class.^isa(Failure) {
            $class.so; # defuse the Failure
            fail "No such symbol '$package'" unless $!p5.module-loaded($package);
            $class := $!p5.loaded-module($package);
        }
        return $class."$name"(|%named<False>, |%(%named<True>));
        CONTROL {
            when CX::Warn {
                note $_.gist;
                $_.resume;
            }
        }
    }
    method create_pair(Any $key, Mu $value) {
        return $key => $value;
    }
}

method init_callbacks {
    self.run($=finish);

    self.call-simple-args('v6::init', Perl6Callbacks.new(:p5(self)));

    if $!external_p5 {
        $!p5.p5_inline_perl6_xs_init();
    }
}

method sv_refcnt_dec($obj --> Nil) {
    # Destructor may already have run. Destructors of individual P5 objects no longer work.
    $!p5.p5_sv_refcnt_dec($obj) if $!p5;
}

method install_wrapper_method(Str:D $package, Str $name, **@attributes) {
    self.call-simple-args('v6::install_p6_method_wrapper', $package, $name, |@attributes);
}

method subs_in_module(Str $module) {
    return self.run('[ grep { defined *{"' ~ $module ~ '::$_"}{CODE} } keys %' ~ $module ~ ':: ]');
}

method variables_in_module(Str $module) {
    self.call-simple-args('v6::variables_in_module', $module)
}

method import (Str $module, **@args) {
    my $before = set self.subs_in_module('main').list;
    self.invoke($module, 'import', |@args);
    my $after = set self.subs_in_module('main').list;
    return ($after ∖ ($before ∖ set @args)).keys;
}

method !require_modules(@required_modules) {
    for @required_modules -> ($module, $version, @args) {
        self.call-simple-args('v6::load_module', $module);
        self.invoke($module, 'import', |@args);
    }
}

method require_modules(@required_modules) {
    self!require_modules(@required_modules);
    @!required_modules.append: @required_modules;
}

method restore_modules() {
    self!require_modules(@!required_modules);
    for %!loaded_modules.values -> $class {
        $class.^replace_ip5($!p5);
    }
}

method required_modules() {
    @!required_modules
}

my Lock $gil .= new;
method gil() {
    $gil
}

method require(Str $module, Num $version?, Bool :$handle) {
    my @import_args;
    push @!required_modules, ($module, $version, @import_args);

    # wrap the load_module call so exceptions can be translated to Raku
    my @packages = $version
        ?? self.call-simple-args('v6::load_module', $module, $version)
        !! self.call-simple-args('v6::load_module', $module);

    return unless self eq $default_perl5; # Only create Raku packages for the primary interpreter to avoid confusion

    {
        my $module_symbol = ::($module);
        if $module_symbol.HOW.^isa(Metamodel::ClassHOW) and $module_symbol.^isa(Failure) {
            $module_symbol.Bool;
        }
    }

    my $stash := $handle ?? Stash.new !! ::GLOBAL.WHO;

    my $class;
    for @packages.grep(*.defined).grep(/<-lower -[:]>/).grep(*.starts-with: $module) -> $package {
        my $symbol = ::($package);
        $symbol.Bool if $symbol.HOW.^isa(Metamodel::ClassHOW) and $symbol.^isa(Failure); #disarm
        my $created := self!import_wrapper_class($package, $stash);
        $class := $created if $package eq $module;
    }

    my &export := sub EXPORT(**@args) {
            @import_args = @args;
            if &p5_terminate.^find_method('CALL-ME') { # looks like old rakudo without necessary fixes
                $*W.do_pragma(Any, 'precompilation', False, []);
            }
            else {
                if $*W.is_precompilation_mode {
                    my $block := { # FIXME only add once per compilation unit!
                        self.restore_interpreter;
                        self.restore_modules;
                    };
                    $*W.add_object($block);
                    my $op := $*W.add_phaser(Mu, 'INIT', $block, class :: { method cuid { (^2**128).pick }});
                }
            }
            my @symbols = self.import($module, |@args).map({
                my $name = $_;
                my $function = "main::$name";
                '&' ~ $name => sub (|args) {
                    self.call-args($function, args); # main:: because the sub got exported to main
                }
            });
            # Hack needed for rakudo versions post-lexical_module_load but before support for
            # getting a CompUnit::Handle from require was implemented.
            @symbols.unshift: $module => $class unless $handle;
            return Map.new(@symbols);
        };

    unless $handle {
        ::($module).WHO<EXPORT> := Metamodel::PackageHOW.new();
        ::($module).WHO<&EXPORT> := &export;
    }

    (CompUnit::Handle.from-unit($stash) does my role :: {
        has &!EXPORT;
        submethod with-export(&EXPORT) {
            &!EXPORT := &EXPORT;
            self
        }
        method export-package() returns Stash {
            Stash.new
        }
        method export-sub() returns Callable {
            &!EXPORT
        }
    }).with-export(&export);
}

method create_wrapper_class(Str $module, $symbols = self.subs_in_module($module)) {
    my $parents = self.global('@' ~ $module ~ '::ISA');
    my @parents = [];
    if $parents {
        for $parents.keys {
            my $parent = $parents[$_];
            @parents[$_] := (%!loaded_modules{$parent}:exists)
                    ?? %!loaded_modules{$parent}
                    !! self.create_wrapper_class($parent);
        }
    }
    @parents[@parents.elems] := Any;
    @parents[@parents.elems] := Mu;
    %!loaded_modules{$module} := my $class :=
        ($thread-safe ?? Inline::Perl5::ClassHOW::ThreadSafe !! Inline::Perl5::ClassHOW).new_type(
            :name($module),
            :@parents,
            :p5(self),
            :ip5($!p5),
        );

    # install methods
    for @$symbols -> $name {
        $class.^add_wrapper_method($name);
    }

    $class.^compose;

    $class
}

method !import_wrapper_class(Str $module, Stash $stash) {
    my $class;
    my $first-time = False;
    my $symbols;
    my $variables;

    if %!loaded_modules{$module}:exists {
        $class := %!loaded_modules{$module};
    }
    else {
        my $p5 := self;
        $first-time = True;
        $variables = self.variables_in_module($module);
        $symbols = self.subs_in_module($module);

        $class := self.create_wrapper_class($module, $symbols)
    }

    # register the new class by its name
    my @parts = $module.split('::');
    my $inner = @parts.pop;
    my $ns := $stash;
    for @parts {
        $ns{$_} := Metamodel::PackageHOW.new_type(name => $_) unless $ns{$_}:exists;
        $ns := $ns{$_}.WHO;
    }
    my @existing = $ns{$inner}.WHO.pairs;
    unless $ns{$inner}:exists {
        $ns{$inner} := $class;
        $class.WHO.BIND-KEY($_.key, $_.value) for @existing;
    }

    if $first-time {
        # install subs like Test::More::ok
        for @$symbols -> $name {
            my $full-name = "{$module}::$name";
            $class.WHO.BIND-KEY("&$name", sub (**@args) {
                self.call($full-name, |@args);
            });
        }
        for @$variables -> $name {
            $class.WHO{'$' ~ $name} := Proxy.new(
                FETCH => -> $ {
                    Inline::Perl5.default_perl5.global('$' ~ $module ~ '::' ~ $name);
                },
                STORE => -> $, $val {
                    Inline::Perl5.default_perl5.set_global('$' ~ $module ~ '::' ~ $name, $val);
                },
            );
        }
    }

    return $class;
}

method use(Str $module, **@args) {
    self.require($module);
    self.import($module, |@args);
}

submethod DESTROY {
    $!p5.p5_destruct_perl() if $!p5 and not $!external_p5;
    $!p5 := Inline::Perl5::Interpreter;
}


method default_perl5 {
    return $default_perl5 //= self.new(:default);
}

method retrieve_scalar_context() {
    my $scalar_context = $!scalar_context;
    $!scalar_context = False;
    return $scalar_context;
}

class X::Inline::Perl5::NoMultiplicity is Exception {
    method message() {
        "You need to compile perl with -Dusemultiplicity for running multiple interpreters."
    }
}

method init_data($data) {
    self.call-simple-args('v6::init_data', $data.encode);
}

method BUILD(:$!default = False, Inline::Perl5::Interpreter :$!p5, Bool :$thread-safe) {
    $Inline::Perl5::thread-safe = True if $thread-safe;
    %!gvs = Hash.new;
    self.initialize;
}

method restore_interpreter() {
    %!gvs = Hash.new;
    if $!default and $default_perl5 {
        unless self === $default_perl5 {
            $!p5 := $default_perl5.interpreter;
            $!objects = $default_perl5.object_keeper; #TOOD may actually need to merge
            $default_perl5.required_modules.append: @!required_modules;
        }
    }
    else {
        self.initialize(:reinitialize);
    }
}

has %!raku_blocks;
method add-raku-block($package, $code, $pos) {
    %!raku_blocks{$package}{$code} = {
        :$pos,
        :code(-> {
            my $class := %!raku_blocks{$package}{$code}<class>;
            for $class.^methods(:local) -> $method {
                next if $method.name eq 'DESTROY';
                next if $method.name eq 'wrapped-perl5-object';
                next if $method.name eq 'inline-perl5';
                next if $method ~~ Inline::Perl5::WrapperMethod;

                $method.does(Inline::Perl5::Attributes)
                    ?? self.install_wrapper_method($package, $method.name, |$method.attributes)
                    !! self.install_wrapper_method($package, $method.name);
            }

            Nil
        }),
    };
}

method initialize(Bool :$reinitialize) {
    $!thread-id = $*THREAD.id;
    $!objects = Inline::Language::ObjectKeeper.new;
    %!gvs = Hash.new;

    my &call_method = sub (Int $index, Str $name, Int $context, Pointer $args, Pointer $err) returns Pointer {
        my $p6obj = $!objects.get($index);
        $!scalar_context = ?$context;
        CONTROL {
            when CX::Warn {
                note $_.gist;
                $_.resume;
            }
        }
        CATCH {
            default {
                nativecast(CArray[Pointer], $err)[0] = self.p6_to_p5($_);
                return Pointer;
            }
        }
        my @args := self.p5_array_to_p6_array($args);
        self.p6_to_p5($p6obj."$name"(|@args.grep({$_ !~~ Pair}).list, |@args.grep(Pair).hash))
    }
    &call_method does Inline::Perl5::Caller;

    my &call_package_method = sub (Str $package, Str $name, Int $context, Pointer $args, Pointer $err) returns Pointer {
        CONTROL {
            when CX::Warn {
                note $_.gist;
                $_.resume;
            }
        }
        CATCH {
            default {
                nativecast(CArray[Pointer], $err)[0] = self.p6_to_p5($_);
                return Pointer;
            }
        }
        my @args := self.p5_array_to_p6_array($args);

        my %named = classify {$_.WHAT =:= Pair}, @args;
        %named<False> //= [];
        %named<True> //= [];
        my $class := ::($package);
        if $class.HOW.^isa(Metamodel::ClassHOW) and $class.^isa(Failure) {
            $class.so; # defuse the Failure
            fail "No such symbol '$package'" unless %!loaded_modules{$package}:exists;
            $class := %!loaded_modules{$package};
        }
        self.p6_to_p5($class."$name"(|%named<False>, |%(%named<True>)));
    }

    my &call_callable = sub (Int $index, Pointer $args, Pointer $err) returns Pointer {
        CONTROL {
            when CX::Warn {
                note $_.gist;
                $_.resume;
            }
        }
        CATCH {
            default {
                nativecast(CArray[Pointer], $err)[0] = self.p6_to_p5($_);
                return Pointer;
            }
        }
        self.p6_to_p5($!objects.get($index)(|self.p5_array_to_p6_array($args)))
    }

    my &hash_at_key = sub (Int $index, Str $key) returns Pointer {
        CONTROL {
            when CX::Warn {
                note $_.gist;
                $_.resume;
            }
        }
        self.p6_to_p5($!objects.get($index).AT-KEY($key))
    }

    my &hash_assign_key = sub (Int $index, Str $key, Pointer $value --> Nil) {
        CONTROL {
            when CX::Warn {
                note $_.gist;
                $_.resume;
            }
        }
        $!objects.get($index).ASSIGN-KEY($key, self.p5_to_p6($value))
    }

    sub lenient-raku-compiler() {
        use nqp;
        my $current-compiler := nqp::getcomp('Raku');
        $current-compiler := nqp::getcomp('perl6') if nqp::isnull($current-compiler);
        my $compiler := nqp::clone($current-compiler);
        $compiler.parsegrammar(
            $compiler.parsegrammar but role :: {
                token end_block_and_comp_unit { "}" .* }
                method typed_panic($type_str, *%opts) {
                    if $type_str eq "X::Syntax::Confused" and substr(self.orig, self.MATCH.pos, 1) eq q<}> {
                        $*pos = self.MATCH.pos;
                        return self.end_block_and_comp_unit;
                    };
                    $*W.throw(self.MATCH(), nqp::split("::", $type_str), |%opts);
                }
            }
        );
        $compiler
    }

    my &compile_to_end = sub (Str $package, Str $code is copy, CArray[uint32] $pos) {
        my $*P5 = self;
        my $*IP5 = $!p5;
        my $preamble = $package eq 'main' ?? '' !! "use Inline::Perl5::ClassHOW; unit perl5class GLOBAL::$package;\n";
        my $preamble_len = $preamble.chars;
        $code = "$preamble$code";
        if $reinitialize {
            $pos[0] = %!raku_blocks{$package}{$code}<pos>;
            return self.p6_to_p5(%!raku_blocks{$package}{$code}<code>);
        }
        CONTROL {
            when CX::Warn {
                note $_.gist;
                $_.resume;
            }
        }

        my $*CTXSAVE; # make sure we don't use the EVAL's MAIN context for the currently compiling compilation unit
        my $*pos;
        my $compiler := lenient-raku-compiler;

        use nqp;
        my $context := CORE::; # workaround for rakudo versions that won't give a result without outer_ctx
        my $outer_ctx := $broken-rakudo ?? nqp::getattr($context, PseudoStash, '$!ctx') !! Nil;
        my $compiled := $compiler.compile($code, :need_result($package eq 'main' ?? 0 !! 1), :$outer_ctx);
        nqp::forceouterctx(
            nqp::getattr($compiled, ForeignCode, '$!do'), $outer_ctx
        ) if $outer_ctx;

        self.add-raku-block($package, $code, $pos[0] = $*pos - $preamble_len);

        self.p6_to_p5($package eq 'main' ?? $compiled !! -> {
            %!raku_blocks{$package}{$code}<class> := my $class := $compiled();
            self.add-to-loaded-modules($package, $class);

            my $symbols = self.subs_in_module($package);

            for $class.^methods(:local) -> $method {
                next if $method.name eq 'DESTROY';
                next if $method.name eq 'wrapped-perl5-object';
                next if $method.name eq 'inline-perl5';

                $method.does(Inline::Perl5::Attributes)
                    ?? self.install_wrapper_method($package, $method.name, |$method.attributes)
                    !! self.install_wrapper_method($package, $method.name);
            }

            for @$symbols -> $name {
                next if $name eq 'DESTROY';
                next if $name eq 'wrapped-perl5-object';
                next if $name eq 'inline-perl5';
                $class.^add_wrapper_method($name);
            }

            Nil
        })
    }

    if ($*W) {
        my $block := {
            self.init_data($_) with CALLER::MY::<$=finish>;
        };
        $*W.add_object($block);
        my $op := $*W.add_phaser(Mu, 'ENTER', $block, class :: { method cuid { (^2**128).pick }});
    }

    if not $reinitialize and $!p5.defined {
        $!external_p5 = True;
        Inline::Perl5::Interpreter::p5_init_callbacks(
            &call_method,
            &call_package_method,
            &call_callable,
            -> $idx { $!objects.free($idx) },
            &hash_at_key,
            &hash_assign_key,
            &compile_to_end,
        );
    }
    else {
        my @args = @*ARGS;
        $!p5 := Inline::Perl5::Interpreter::p5_init_perl(
            @args.elems + 4,
            CArray[Str].new('', '-e', '0', '--', |@args, Str),
            &call_method,
            &call_package_method,
            &call_callable,
            -> $idx { $!objects.free($idx) },
            &hash_at_key,
            &hash_assign_key,
            &compile_to_end,
        );
        X::Inline::Perl5::NoMultiplicity.new.throw unless $!p5.defined;
    }

    self.init_callbacks();

    $default_perl5 //= self;
}

# for backwards compatibility with documented interfaces
OUR::<Perl5Attributes> := Inline::Perl5::Attributes;

my Bool $inline_perl6_in_use = False;
sub init_inline_perl6_new_callback(&inline_perl5_new (Inline::Perl5::Interpreter --> Pointer)) { ... };

our sub init_inline_perl6_callback(Str $path) {
    $inline_perl6_in_use = True;
    trait_mod:<is>(&init_inline_perl6_new_callback, :native($path));

    init_inline_perl6_new_callback(sub (Inline::Perl5::Interpreter $p5) {
        my $self = Inline::Perl5.new(:p5($p5));
        return $self.p6_to_p5($self);
    });
}

END {
    # Raku does not guarantee that DESTROY methods are called at program exit.
    # Make sure at least the first Perl 5 interpreter is correctly shut down and thus can e.g.
    # flush its output buffers. This should at least fix the vast majority of use cases.
    # People who really do use multiple Perl 5 interpreters are probably experienced enough
    # to find proper workarounds for their cases.
    $default_perl5.DESTROY if $default_perl5;

    p5_terminate unless $inline_perl6_in_use;
}

}

multi sub EXPORT() {
    Map.new
}

multi sub EXPORT('thread-safe') {
    $Inline::Perl5::thread-safe = True;
    Map.new
}

# Perl 5 part of the bridge used by init_callbacks:

=finish

use strict;
use warnings;

package Perl6::Object;

use overload
	'""' => sub {
	    my ($self) = @_;

	    return $self->Str;
	},
	'cmp' => sub {
            my ($self, $other) = @_;

            return $self->Str cmp $other;
	};

our $AUTOLOAD;
sub AUTOLOAD {
    my ($self) = @_;
    my $name = $AUTOLOAD =~ s/.*:://r;
    Perl6::Object::call_method($name, @_);
}

sub can {
    my ($self) = shift;

    return if not ref $self and $self eq 'Perl6::Object';
    return ref $self
        ? Perl6::Object::call_method('can', $self, @_)
        : v6::invoke($self =~ s/\APerl6::Object:://r, 'can', @_);
}

sub DESTROY {
}

package Perl6::Callable;

sub new {
    my ($index) = @_;
    return sub { Perl6::Callable::call($index, @_) };
}

package Perl6::Handle;

sub new {
    my ($class, $handle) = @_;
    my $out = \do { local *FH };
    tie *$out, $class, $handle;
    return $out;
}

sub TIEHANDLE {
    my ($class, $p6obj) = @_;
    my $self = \$p6obj;
    return bless $self, $class;
}

sub PRINT {
    my ($self, @list) = @_;
    return $$self->print(@list);
}

sub READLINE {
    my ($self) = @_;
    return $$self->get;
}

package Perl6::Hash;

sub new {
    my ($class, $hash) = @_;
    my %tied;
    tie %tied, $class, $hash;
    return \%tied;
}

sub TIEHASH {
    my ($class, $p6hash) = @_;
    my $self = [ $p6hash ];
    return bless $self, $class;
}

sub DELETE {
    my ($self, $key) = @_;
    return Perl6::Object::call_method('DELETE-KEY', $self->[0], $key);
}
sub CLEAR {
    die 'CLEAR NYI';
}
sub EXISTS {
    my ($self, $key) = @_;
    return Perl6::Object::call_method('EXISTS-KEY', $self->[0], $key);
}
sub FIRSTKEY {
    my ($self) = @_;
    $self->[1] = [ Perl6::Object::call_method('keys', $self->[0]) ];
    $self->[2] = 0;
    return $self->NEXTKEY;
}
sub NEXTKEY {
    my ($self) = @_;
    return $self->[2] <= @{ $self->[1] } ? $self->[1][ $self->[2]++ ] : undef;
}
sub SCALAR {
    my ($self) = @_;
    return Perl6::Object::call_method('elems', $self->[0]);
}

package v6;

my $p6;

sub init {
    ($p6) = @_;
}

sub init_data {
    my ($data) = @_;
    no strict;
    open *{main::DATA}, '<:utf8', \$data;
}

sub uninit {
    undef $p6;
}

# wrapper for the load_module perlapi call to allow catching exceptions
sub load_module {
    # lifted from Devel::InnerPackage to avoid the dependency
    my $list_packages;
    $list_packages = sub {
        my $pack = shift; $pack .= "::" unless $pack =~ m!::$!;

        no strict 'refs';

        my @packs;
        my @stuff = grep !/^(main|)::$/, keys %{$pack};
        for my $cand (grep /::$/, @stuff) {
            $cand =~ s!::$!!;
            my @children = $list_packages->($pack.$cand);

            push @packs, "$pack$cand"
                if $cand !~ /^::/
                && (
                    defined ${"${pack}${cand}::VERSION"}
                    || @{"${pack}${cand}::ISA"}
                    || grep { defined &{"${pack}${cand}::$_"} }
                        grep { substr($_, -2, 2) ne '::' }
                        keys %{"${pack}${cand}::"}
                ); # or @children;
            push @packs, @children;
        }
        return grep {$_ !~ /::(::ISA::CACHE|SUPER)/} @packs;
    };

    v6::load_module_impl(@_);
    return map { substr $_, 2 } $list_packages->('::');
}

sub variables_in_module {
    my ($module) = @_;

    my @variables;
    no strict 'refs';
    while (my ($key, $val) = each(%{*{"$module\::"}})) {
        next if $key =~ /::\z/; # packages
        local(*ENTRY) = $val;
        push @variables, $key if defined $val && defined *ENTRY{SCALAR};
    }
    @variables
}

sub run {
    my ($code) = @_;
    return $p6->run($code);
}

sub run_to_end {
    my ($code) = @_;
    $$code = substr($$code, 2);
    my $pos = $p6->run_to_end($$code);
    $$code = substr($$code, $pos + 1);
}


sub call {
    my ($name, @args) = @_;
    return $p6->call($name, \@args);
}

sub invoke {
    my ($class, $name, @args) = @_;
    return $p6->invoke($class, $name, \@args);
}

sub named(@) {
    die "Only named arguments allowed after v6::named" if @_ % 2 != 0;
    my @args;
    while (@_) {
        push @args, $p6->create_pair(shift @_, shift @_);
    }
    return @args;
}

sub extend {
    my ($static_class, $self, $args, $dynamic_class) = @_;

    $args //= [];
    undef $dynamic_class
        if $dynamic_class and (
            $dynamic_class eq $static_class
            or $dynamic_class eq "Perl6::Object::${static_class}"
        );
    my $p6 = v6::invoke($static_class, 'new', @$args, v6::named parent => $self);
    {
        no strict 'refs';
        @{"Perl6::Object::${static_class}::ISA"} = ("Perl6::Object", $dynamic_class // (), $static_class);
    }
    return $self;
}

sub shadow_object {
    my ($static_class, $dynamic_class, $object) = @_;

    v6::invoke($static_class, 'new_shadow_of_p5_object', $object);
    return $object;
}
use mro;

sub install_function {
    my ($package, $name, $code) = @_;

    no strict 'refs';
    *{"${package}::$name"} = v6::set_subname("${package}::", $name, $code);
    return;
}

use attributes ();
sub install_p6_method_wrapper {
    my ($package, $name, @attributes) = @_;
    no strict 'refs';
    *{"${package}::$name"} = my $code = v6::set_subname("${package}::", $name, sub {
        return Perl6::Object::call_extension_method($p6, $package, $name, @_);
    });
    attributes->import($package, $code, @attributes) if @attributes;
    return;
}

{
    my @inlined;
    my $package_to_create;

    sub import {
        my $package = $package_to_create = scalar caller;
        push @inlined, $package;
    }

    use Filter::Simple sub {
        $p6->create_extension($package_to_create, $_);
        $_ = '1;';
    };
}

sub wrap_regex {
    my ($self, $regex) = @_;
    my $sub = sub {
        return $regex->ACCEPTS($_[0]);
    };
    return qr/\A(?(?{ $sub->($_) }).*|)\z/;
}

package v6::inline;

sub import {
    die 'v6::inline got renamed to v6-inline for compatibility with older Perl 5 versions. Sorry for the back and forth about this.';
}

$INC{'v6.pm'} = '';
$INC{'v6/inline.pm'} = '';

1;
