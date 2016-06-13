unit class Inline::Perl5;

use NativeCall;
use MONKEY-SEE-NO-EVAL;

class Perl5Interpreter is repr('CPointer') { }
role Perl5Package { ... };
role Perl5Parent { ... };

has Perl5Interpreter $!p5;
has Bool $!external_p5 = False;
has &!call_method;
has &!call_callable;
has Bool $!scalar_context = False;

my $default_perl5;

my constant $p5helper = %?RESOURCES<libraries/p5helper>.Str;

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

sub p5_size_of_iv() is native($p5helper)
    returns size_t { ... }

sub p5_size_of_nv() is native($p5helper)
    returns size_t { ... }

BEGIN my constant IV = p5_size_of_iv() == 8 ?? int64 !! int32;
BEGIN my constant NVSIZE = p5_size_of_nv();
BEGIN die "Cannot support { NVSIZE * 8 } bit NVs yet." if NVSIZE != 4|8;
BEGIN my constant NV = NVSIZE == 8 ?? num64 !! num32;

sub p5_init_perl() is native($p5helper)
    returns Perl5Interpreter { ... }

sub p5_inline_perl6_xs_init(Perl5Interpreter) is native($p5helper)
    { ... }

sub p5_SvIOK(Perl5Interpreter, Pointer) is native($p5helper)
    returns uint32 { ... }

sub p5_SvNOK(Perl5Interpreter, Pointer) is native($p5helper)
    returns uint32 { ... }

sub p5_SvPOK(Perl5Interpreter, Pointer) is native($p5helper)
    returns uint32 { ... }

sub p5_sv_utf8(Perl5Interpreter, Pointer) is native($p5helper)
    returns uint32 { ... }

sub p5_is_array(Perl5Interpreter, Pointer) is native($p5helper)
    returns int32 { ... }

sub p5_is_hash(Perl5Interpreter, Pointer) is native($p5helper)
    returns int32 { ... }

sub p5_is_scalar_ref(Perl5Interpreter, Pointer) is native($p5helper)
    returns int32 { ... }

sub p5_is_undef(Perl5Interpreter, Pointer) is native($p5helper)
    returns int32 { ... }

sub p5_sv_to_buf(Perl5Interpreter, Pointer, CArray[CArray[int8]]) is native($p5helper)
    returns size_t { ... }

sub p5_sv_to_char_star(Perl5Interpreter, Pointer) is native($p5helper)
    returns Str { ... }

sub p5_sv_to_av(Perl5Interpreter, Pointer) is native($p5helper)
    returns Pointer { ... }

sub p5_sv_to_hv(Perl5Interpreter, Pointer) is native($p5helper)
    returns Pointer { ... }

sub p5_sv_refcnt_dec(Perl5Interpreter, Pointer) is native($p5helper)
    { ... }

sub p5_sv_2mortal(Perl5Interpreter, Pointer) is native($p5helper)
    { ... }

sub p5_sv_refcnt_inc(Perl5Interpreter, Pointer) is native($p5helper)
    { ... }

sub p5_int_to_sv(Perl5Interpreter, IV) is native($p5helper)
    returns Pointer { ... }

sub p5_float_to_sv(Perl5Interpreter, NV) is native($p5helper)
    returns Pointer { ... }

sub p5_str_to_sv(Perl5Interpreter, size_t, Blob) is native($p5helper)
    returns Pointer { ... }

sub p5_buf_to_sv(Perl5Interpreter, size_t, Blob) is native($p5helper)
    returns Pointer { ... }

sub p5_sv_to_ref(Perl5Interpreter, Pointer) is native($p5helper)
    returns Pointer { ... }

sub p5_av_top_index(Perl5Interpreter, Pointer) is native($p5helper)
    returns int32 { ... }

sub p5_av_fetch(Perl5Interpreter, Pointer, int32) is native($p5helper)
    returns Pointer { ... }

sub p5_av_push(Perl5Interpreter, Pointer, Pointer) is native($p5helper)
    { ... }

sub p5_hv_iterinit(Perl5Interpreter, Pointer) is native($p5helper)
    returns int32 { ... }

sub p5_hv_iternext(Perl5Interpreter, Pointer) is native($p5helper)
    returns Pointer { ... }

sub p5_hv_iterkeysv(Perl5Interpreter, Pointer) is native($p5helper)
    returns Pointer { ... }

sub p5_hv_iterval(Perl5Interpreter, Pointer, Pointer) is native($p5helper)
    returns Pointer { ... }

sub p5_undef(Perl5Interpreter) is native($p5helper)
    returns Pointer { ... }

sub p5_newHV(Perl5Interpreter) is native($p5helper)
    returns Pointer { ... }

sub p5_newAV(Perl5Interpreter) is native($p5helper)
    returns Pointer { ... }

sub p5_newRV_noinc(Perl5Interpreter, Pointer) is native($p5helper)
    returns Pointer { ... }

sub p5_sv_reftype(Perl5Interpreter, Pointer) is native($p5helper)
    returns Str { ... }

sub p5_hv_store(Perl5Interpreter, Pointer, Str, Pointer) is native($p5helper)
    { ... }

sub p5_call_function(Perl5Interpreter, Str, int32, CArray[Pointer]) is native($p5helper)
    returns Pointer { ... }

sub p5_call_method(Perl5Interpreter, Str, Pointer, int32, Str, int32, CArray[Pointer]) is native($p5helper)
    returns Pointer { ... }

sub p5_call_package_method(Perl5Interpreter, Str, Str, int32, CArray[Pointer]) is native($p5helper)
    returns Pointer { ... }

sub p5_call_code_ref(Perl5Interpreter, Pointer, int32, CArray[Pointer]) is native($p5helper)
    returns Pointer { ... }

sub p5_rebless_object(Perl5Interpreter, Pointer, Str, IV, &call_method (IV, Str, int32, Pointer, Pointer --> Pointer), &free_p6_object (IV)) is native($p5helper)
    { ... }

sub p5_destruct_perl(Perl5Interpreter) is native($p5helper)
    { ... }

sub p5_sv_iv(Perl5Interpreter, Pointer) is native($p5helper)
    returns IV { ... }

sub p5_sv_nv(Perl5Interpreter, Pointer) is native($p5helper)
    returns NV { ... }

sub p5_sv_rv(Perl5Interpreter, Pointer) is native($p5helper)
    returns Pointer { ... }

sub p5_is_object(Perl5Interpreter, Pointer) is native($p5helper)
    returns int32 { ... }

sub p5_is_sub_ref(Perl5Interpreter, Pointer) is native($p5helper)
    returns int32 { ... }

sub p5_eval_pv(Perl5Interpreter, Str, int32) is native($p5helper)
    returns Pointer { ... }

sub p5_err_sv(Perl5Interpreter) is native($p5helper)
    returns Pointer { ... }

sub p5_wrap_p6_object(Perl5Interpreter, IV, Pointer, &call_method (IV, Str, int32, Pointer, Pointer --> Pointer), &free_p6_object (IV)) is native($p5helper)
    returns Pointer { ... }

sub p5_wrap_p6_callable(Perl5Interpreter, IV, Pointer, &call (IV, Pointer, Pointer --> Pointer), &free_p6_object (IV)) is native($p5helper)
    returns Pointer { ... }

sub p5_wrap_p6_handle(Perl5Interpreter, IV, Pointer, &call_method (IV, Str, int32, Pointer, Pointer --> Pointer), &free_p6_object (IV)) is native($p5helper)
    returns Pointer { ... }

sub p5_is_wrapped_p6_object(Perl5Interpreter, Pointer) is native($p5helper)
    returns int32 { ... }

sub p5_unwrap_p6_object(Perl5Interpreter, Pointer) is native($p5helper)
    returns IV { ... }

sub p5_terminate() is native($p5helper)
    { ... }


multi method p6_to_p5(Int:D $value) returns Pointer {
    p5_int_to_sv($!p5, $value);
}
multi method p6_to_p5(Num:D $value) returns Pointer {
    p5_float_to_sv($!p5, $value);
}
multi method p6_to_p5(Rat:D $value) returns Pointer {
    p5_float_to_sv($!p5, $value.Num);
}
multi method p6_to_p5(Str:D $value) returns Pointer {
    my $buf = $value.encode('UTF-8');
    p5_str_to_sv($!p5, $buf.elems, $buf);
}
multi method p6_to_p5(IntStr:D $value) returns Pointer {
    p5_int_to_sv($!p5, $value.Int);
}
multi method p6_to_p5(NumStr:D $value) returns Pointer {
    p5_float_to_sv($!p5, $value.Num);
}
multi method p6_to_p5(RatStr:D $value) returns Pointer {
    p5_float_to_sv($!p5, $value.Num);
}
multi method p6_to_p5(blob8:D $value) returns Pointer {
    p5_buf_to_sv($!p5, $value.elems, $value);
}
multi method p6_to_p5(Capture:D $value where $value.elems == 1) returns Pointer {
    p5_sv_to_ref($!p5, self.p6_to_p5($value[0]));
}
multi method p6_to_p5(Perl5Object $value) returns Pointer {
    p5_sv_refcnt_inc($!p5, $value.ptr);
    $value.ptr;
}
multi method p6_to_p5(Perl5Package $value) returns Pointer {
    self.p6_to_p5($value.unwrap-perl5-object());
}
multi method p6_to_p5(Perl5Parent $value) returns Pointer {
    self.p6_to_p5($value.unwrap-perl5-object());
}
multi method p6_to_p5(Pointer $value) returns Pointer {
    $value;
}
multi method p6_to_p5(Any:U $value) returns Pointer {
    p5_undef($!p5);
}

my $objects = ObjectKeeper.new;

sub free_p6_object(Int $index) {
    $objects.free($index);
}

multi method p6_to_p5(Perl5Object:D $value, Pointer $inst) {
    p5_sv_refcnt_inc($!p5, $inst);
    $inst;
}
multi method p6_to_p5(Any:D $value, Pointer $inst = Pointer) {
    my $index = $objects.keep($value);

    p5_wrap_p6_object(
        $!p5,
        $index,
        $inst,
        &!call_method,
        &free_p6_object,
    );
}
multi method p6_to_p5(Callable:D $value, Pointer $inst = Pointer) {
    my $index = $objects.keep($value);

    p5_wrap_p6_callable(
        $!p5,
        $index,
        $inst,
        &!call_callable,
        &free_p6_object,
    );
}
multi method p6_to_p5(Perl5Callable:D $value) returns Pointer {
    p5_sv_refcnt_inc($!p5, $value.ptr);
    $value.ptr;
}
multi method p6_to_p5(Hash:D $value) returns Pointer {
    my $hv = p5_newHV($!p5);
    for %$value -> $item {
        my $value = self.p6_to_p5($item.value);
        p5_hv_store($!p5, $hv, $item.key, $value);
    }
    p5_newRV_noinc($!p5, $hv);
}
multi method p6_to_p5(Positional:D $value) returns Pointer {
    my $av = p5_newAV($!p5);
    for @$value -> $item {
        p5_av_push($!p5, $av, self.p6_to_p5($item));
    }
    p5_newRV_noinc($!p5, $av);
}
multi method p6_to_p5(IO::Handle:D $value) returns Pointer {
    my $index = $objects.keep($value);

    p5_wrap_p6_handle(
        $!p5,
        $index,
        Any,
        &!call_method,
        &free_p6_object,
    );
}

method p5_sv_reftype(Pointer $sv) {
    return p5_sv_reftype($!p5, $sv);
}

method p5_array_to_p6_array(Pointer $sv) {
    my $av = p5_sv_to_av($!p5, $sv);
    my int32 $av_len = p5_av_top_index($!p5, $av);

    my $arr = [];
    loop (my int32 $i = 0; $i <= $av_len; $i = $i + 1) {
        $arr.push(self.p5_to_p6(p5_av_fetch($!p5, $av, $i)));
    }
    $arr;
}
method !p5_hash_to_p6_hash(Pointer $sv) {
    my Pointer $hv = p5_sv_to_hv($!p5, $sv);

    my int32 $len = p5_hv_iterinit($!p5, $hv);

    my $hash = {};

    for 0 .. $len - 1 {
        my Pointer $next = p5_hv_iternext($!p5, $hv);
        my Pointer $key = p5_hv_iterkeysv($!p5, $next);
        die 'Hash entry without key!?' unless $key;
        my Str $p6_key = p5_sv_to_char_star($!p5, $key);
        my $val = self.p5_to_p6(p5_hv_iterval($!p5, $hv, $next));
        $hash{$p6_key} = $val;
    }

    $hash;
}

method !p5_scalar_ref_to_capture(Pointer $sv) {
    return \(self.p5_to_p6(p5_sv_rv($!p5, $sv)));
}

method p5_to_p6(Pointer $value) {
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
    elsif p5_is_scalar_ref($!p5, $value) {
        return self!p5_scalar_ref_to_capture($value);
    }
    die "Unsupported type $value in p5_to_p6";
}

method handle_p5_exception() is hidden-from-backtrace {
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
    my @svs := CArray[Pointer].new();
    my Int $j = 0;
    loop (my Int $i = 0; $i < $len; $i = $i + 1) {
        if @args[$i] ~~ Pair {
            @svs[$j++] = self.p6_to_p5(@args[$i].key);
            @svs[$j++] = self.p6_to_p5(@args[$i].value);
        }
        else {
            @svs[$j++] = self.p6_to_p5(@args[$i]);
        }
    }
    return $j, @svs;
}

method !unpack_return_values($av) {
    my int32 $av_len = p5_av_top_index($!p5, $av);

    my @retvals;
    if $av_len == -1 {
        p5_sv_refcnt_dec($!p5, $av);
        return @retvals; # avoid returning Nil when there are no return values
    }

    if $av_len == 0 {
        my $retval = self.p5_to_p6(p5_av_fetch($!p5, $av, 0));
        p5_sv_refcnt_dec($!p5, $av);
        return $retval;
    }

    loop (my int32 $i = 0; $i <= $av_len; $i = $i + 1) {
        @retvals.push(self.p5_to_p6(p5_av_fetch($!p5, $av, $i)));
    }
    p5_sv_refcnt_dec($!p5, $av);
    @retvals;
}

method call(Str $function, *@args, *%args) {
    my $av = p5_call_function($!p5, $function, |self!setup_arguments([flat @args, %args.list]));
    self.handle_p5_exception();
    self!unpack_return_values($av);
}

multi method invoke(Str $package, Str $function, *@args, *%args) {
    my $av = p5_call_package_method($!p5, $package, $function, |self!setup_arguments([flat @args.list, %args.list]));
    self.handle_p5_exception();
    self!unpack_return_values($av);
}

multi method invoke(Pointer $obj, Str $function, *@args) {
    self.invoke(Str, $obj, False, $function, |@args);
}

method invoke-parent(Str $package, Pointer $obj, Bool $context, Str $function, *@args, *%args) {
    my $av = p5_call_method($!p5, $package, $obj, $context ?? 1 !! 0, $function, |self!setup_arguments([flat @args.list, %args.list]));
    self.handle_p5_exception();
    self!unpack_return_values($av);
}

multi method invoke(Str $package, Pointer $obj, Bool $context, Str $function, *@args) {
    my $len = @args.elems;
    my @svs := CArray[Pointer].new();
    my Int $j = 0;
    @svs[$j++] = self.p6_to_p5(@args[0], $obj);
    loop (my Int $i = 1; $i < $len; $i++) {
        if @args[$i] ~~ Pair {
            @svs[$j++] = self.p6_to_p5(@args[$i].key);
            @svs[$j++] = self.p6_to_p5(@args[$i].value);
        }
        else {
            @svs[$j++] = self.p6_to_p5(@args[$i]);
        }
    }
    my $av = p5_call_method($!p5, $package, $obj, $context ?? 1 !! 0, $function, $j, @svs);
    self.handle_p5_exception();
    self!unpack_return_values($av);
}

method execute(Pointer $code_ref, *@args) {
    my $av = p5_call_code_ref($!p5, $code_ref, |self!setup_arguments(@args));
    self.handle_p5_exception();
    self!unpack_return_values($av);
}

class Perl6Callbacks {
    has $.p5;
    method create($package, $code) {
        my $p5 = $.p5;
        EVAL "class GLOBAL::$package does Perl5Parent['$package', \$p5] \{\n$code\n\}";
        return;
    }
    method run($code) {
        return EVAL $code;
        CONTROL {
            note $_.gist;
            $_.resume;
        }
    }
    method call(Str $name, @args) {
        return &::($name)(|@args);
        CONTROL {
            note $_.gist;
            $_.resume;
        }
    }
    method invoke(Str $package, Str $name, @args) {
        my %named = classify * ~~ Pair, @args;
        %named<False> //= [];
        %named<True> //= [];
        return ::($package)."$name"(|%named<False>, |%(%named<True>));
        CONTROL {
            note $_.gist;
            $_.resume;
        }
    }
    method create_pair(Any $key, Mu $value) {
        return $key => $value;
    }
}

method init_callbacks {
    self.run(q:to/PERL5/);
        use strict;
        use warnings;

        package Perl6::Object;

        use overload '""' => sub {
            my ($self) = @_;

            return $self->Str;
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
            my $sub;
            $sub = sub { Perl6::Callable::call($sub, @_) };
            return $sub;
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

        package v6;

        my $p6;

        sub init {
            ($p6) = @_;
        }

        sub uninit {
            undef $p6;
        }

        # wrapper for the load_module perlapi call to allow catching exceptions
        sub load_module {
            v6::load_module_impl(@_);
        }

        sub run {
            my ($code) = @_;
            return $p6->run($code);
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

        sub import {
            die 'v6-inline got renamed to v6::inline to allow passing an import list';
        }

        package v6::inline;
        use mro;

        my $package_to_create;

        sub import {
            my ($class, %args) = @_;
            my $package = $package_to_create = scalar caller;
            foreach my $constructor (@{ $args{constructors} }) {
                no strict 'refs';
                *{"${package}::$constructor"} = v6::set_subname("${package}::", $constructor, sub {
                    my ($class, @args) = @_;
                    my $self = $class->next::method(@args);
                    return v6::extend($package, $self, \@args, $class);
                });
            }
        }

        use Filter::Simple sub {
            $p6->create($package_to_create, $_);
            $_ = '1;';
        };

        $INC{'v6.pm'} = '';
        $INC{'v6/inline.pm'} = '';

        1;
        PERL5

    self.call('v6::init', Perl6Callbacks.new(:p5(self)));

    if $!external_p5 {
        p5_inline_perl6_xs_init($!p5);
    }
}

method sv_refcnt_dec($obj) {
    return unless $!p5; # Destructor may already have run. Destructors of individual P5 objects no longer work.
    p5_sv_refcnt_dec($!p5, $obj);
}

method rebless(Perl5Object $obj, Str $package, $p6obj) {
    my $index = $objects.keep($p6obj);
    p5_rebless_object($!p5, $obj.ptr, $package, $index, &!call_method, &free_p6_object);
}

role Perl5Package[Inline::Perl5 $p5, Str $module] {
    has $!parent;

    method new(*@args, *%args) {
        if (self.perl.Str ne $module) { # subclass
            %args<parent> = $p5.invoke($module, 'new', |@args, |%args.kv);
            my $self = self.bless();
            $self.BUILDALL(@args, %args);
            return $self;
        }
        else {
            return $p5.invoke($module, 'new', @args.list, %args.hash);
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
            ?? $p5.invoke-parent($module, $!parent.ptr, False, $name, $!parent, |@args, |%kwargs)
            !! $p5.invoke($module, $name, |@args.list, |%kwargs);
    }

    for Any.^methods>>.name.list, <say> -> $name {
        next if $?CLASS.^declares_method($name);
        my $method = method (|args) {
            return self.defined
                ?? $p5.invoke-parent($module, $!parent.ptr, False, $name, $!parent, args.list, args.hash)
                !! $p5.invoke($module, $name, args.list, args.hash);
        };
        $method.set_name($name);
        $?CLASS.^add_method(
            $name,
            $method,
        );
    }
}

method subs_in_module(Str $module) {
    return self.run('[ grep { *{"' ~ $module ~ '::$_"}{CODE} } keys %' ~ $module ~ ':: ]');
}

method import (Str $module, *@args) {
    my $before = set self.subs_in_module('main').list;
    self.invoke($module, 'import', @args.list);
    my $after = set self.subs_in_module('main').list;
    return ($after ∖ $before).keys;
}

my $loaded_modules = SetHash.new;
method require(Str $module, Num $version?) {
    # wrap the load_module call so exceptions can be translated to Perl 6
    if $version {
        self.call('v6::load_module', $module, $version);
    }
    else {
        self.call('v6::load_module', $module);
    }

    return unless self eq $default_perl5; # Only create Perl 6 packages for the primary interpreter to avoid confusion
    return if $loaded_modules{$module};
    $loaded_modules{$module} = True;

    my $p5 := self;

    my $class := Metamodel::ClassHOW.new_type( name => $module );
    $class.^add_role(Perl5Package[$p5, $module]);
    my $symbols = self.subs_in_module($module);

    # install methods
    for @$symbols -> $name {
        next if $name eq 'new';
        my $method = my method (*@args, *%kwargs) {
            self.FALLBACK($name, |@args, |%kwargs);
        }
        $method.set_name($name);
        $class.^add_method($name, $method);
    }

    $class.^compose;

    # register the new class by its name
    my @parts = $module.split('::');
    my $inner = @parts.pop;
    my $ns := ::GLOBAL.WHO;
    for @parts {
        $ns{$_} := Metamodel::PackageHOW.new_type(name => $_) unless $ns{$_}:exists;
        $ns := $ns{$_}.WHO;
    }
    my @existing = $ns{$inner}.WHO.pairs;
    $ns{$inner} := $class;
    $class.WHO{$_.key} := $_.value for @existing;

    # install subs like Test::More::ok
    for @$symbols -> $name {
        ::($module).WHO{"&$name"} := sub (*@args) {
            self.call("{$module}::$name", @args.list);
        }
    }

    ::($module).WHO<EXPORT> := Metamodel::PackageHOW.new();
    ::($module).WHO<&EXPORT> := sub EXPORT(*@args) {
        $*W.do_pragma(Any, 'precompilation', False, []);
        return Map.new(self.import($module, @args.list).map({
            my $name = $_;
            '&' ~ $name => sub (*@args, *%args) {
                self.call("main::$name", |@args.list, %args.list); # main:: because the sub got exported to main
            }
        }));
    };
}

method use(Str $module, *@args) {
    self.require($module);
    self.import($module, @args.list);
}

submethod DESTROY {
    p5_destruct_perl($!p5) if $!p5 and not $!external_p5;
    $!p5 = Perl5Interpreter;
}

class Perl5Object {
    has Pointer $.ptr;
    has Inline::Perl5 $.perl5;

    method sink() { self }

    method Str() {
        my $stringify = $!perl5.call('overload::Method', self, '""');
        return $stringify ?? $stringify(self) !! callsame;
    }

    method DESTROY {
        $!perl5.sv_refcnt_dec($!ptr) if $!ptr;
        $!ptr = Pointer;
    }
}

class Perl5Callable does Callable {
    has Pointer $.ptr;
    has Inline::Perl5 $.perl5;

    method CALL-ME(*@args) {
        $.perl5.execute($.ptr, @args);
    }

    method DESTROY {
        $!perl5.sv_refcnt_dec($!ptr) if $!ptr;
        $!ptr = Pointer;
    }
}

method default_perl5 {
    return $default_perl5 //= self.new();
}

method retrieve_scalar_context() {
    my $scalar_context = $!scalar_context;
    $!scalar_context = False;
    return $scalar_context;
}

role Perl5Caller {
}

class X::Inline::Perl5::NoMultiplicity is Exception {
    method message() {
        "You need to compile perl with -DMULTIPLICITY for running multiple interpreters."
    }
}

method BUILD(*%args) {
    $!external_p5 = %args<p5>:exists;
    $!p5 = $!external_p5 ?? %args<p5> !! p5_init_perl();
    X::Inline::Perl5::NoMultiplicity.new.throw unless $!p5.defined;

    &!call_method = sub (Int $index, Str $name, Int $context, Pointer $args, Pointer $err) returns Pointer {
        my $p6obj = $objects.get($index);
        $!scalar_context = ?$context;
        my @retvals = $p6obj."$name"(|self.p5_array_to_p6_array($args));
        return self.p6_to_p5(@retvals);
        CONTROL {
            note $_.gist;
            $_.resume;
        }
        CATCH {
            default {
                nativecast(CArray[Pointer], $err)[0] = self.p6_to_p5($_);
                return Pointer;
            }
        }
    }
    &!call_method does Perl5Caller;

    &!call_callable = sub (Int $index, Pointer $args, Pointer $err) returns Pointer {
        my $callable = $objects.get($index);
        my @retvals = $callable(|self.p5_array_to_p6_array($args));
        return self.p6_to_p5(@retvals);
        CONTROL {
            note $_.gist;
            $_.resume;
        }
        CATCH {
            default {
                nativecast(CArray[Pointer], $err)[0] = self.p6_to_p5($_);
                return Pointer;
            }
        }
    }

    self.init_callbacks();

    $default_perl5 //= self;
}

role Perl5Parent[Str:D $package, Inline::Perl5:D $perl5] {
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
            ?? $perl5.invoke-parent($package, $!parent.ptr, True, 'can', $!parent, $name)
            !! $perl5.invoke($package, 'can', $name);
    }

    ::?CLASS.HOW.add_fallback(::?CLASS, -> $, $ { True },
        method ($name) {
            -> \self, |args {
                my $scalar = (
                    callframe(1).code ~~ Perl5Caller
                    and $perl5.retrieve_scalar_context
                );
                my $parent = self.unwrap-perl5-object;
                $perl5.invoke-parent($package, $parent.ptr, $scalar, $name, $parent, args.list, args.hash);
            }
        }
    );
}

BEGIN {
    Perl5Object.^add_fallback(-> $, $ { True },
        method ($name ) {
            -> \self, |args {
                $.perl5.invoke($.ptr, $name, self, args.list, args.hash);
            }
        }
    );
    for Any.^methods>>.name -> $name {
        Perl5Object.^add_method(
            $name,
            method (|args) {
                $.perl5.invoke($.ptr, $name, self, args.list, args.hash);
            }
        );
    }
    Perl5Object.^compose;
}

my Bool $inline_perl6_in_use = False;
sub init_inline_perl6_new_callback(&inline_perl5_new (Perl5Interpreter --> Pointer)) { ... };

our sub init_inline_perl6_callback(Str $path) {
    $inline_perl6_in_use = True;
    trait_mod:<is>(&init_inline_perl6_new_callback, :native($path));

    init_inline_perl6_new_callback(sub (Perl5Interpreter $p5) {
        my $self = Inline::Perl5.new(:p5($p5));
        return $self.p6_to_p5($self);
    });
}

END {
    # Perl 6 does not guarantee that DESTROY methods are called at program exit.
    # Make sure at least the first Perl 5 interpreter is correctly shut down and thus can e.g.
    # flush its output buffers. This should at least fix the vast majority of use cases.
    # People who really do use multiple Perl 5 interpreters are probably experienced enough
    # to find proper workarounds for their cases.
    $default_perl5.DESTROY if $default_perl5;

    p5_terminate unless $inline_perl6_in_use;
}
