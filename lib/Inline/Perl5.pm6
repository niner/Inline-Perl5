unit class Inline::Perl5;

use MONKEY-SEE-NO-EVAL;
use Inline::Language::ObjectKeeper;
use Inline::Perl5::Interpreter;
use Inline::Perl5::Array;
use Inline::Perl5::Attributes;
use Inline::Perl5::Caller;
use Inline::Perl5::Extension;
use Inline::Perl5::Hash;
use Inline::Perl5::Object;
use Inline::Perl5::Package;
use Inline::Perl5::Parent;
use Inline::Perl5::Callable;

has Inline::Perl5::Interpreter $!p5;
has Bool $!external_p5 = False;
has Bool $!scalar_context = False;

my $default_perl5;

# I'd like to call this from Inline::Perl5::Interpreter
# But it raises an error in the END { ... } call
use NativeCall;
my constant $p5helper = %?RESOURCES<libraries/p5helper>.Str;
my constant $p5helper_resource = %?RESOURCES<libraries/p5helper>;
sub p5_terminate() is native($p5helper) { ... }


multi method p6_to_p5(Int:D $value) returns Pointer {
    $!p5.p5_int_to_sv($value);
}
multi method p6_to_p5(Num:D $value) returns Pointer {
    $!p5.p5_float_to_sv($value);
}
multi method p6_to_p5(Rat:D $value) returns Pointer {
    $!p5.p5_float_to_sv($value.Num);
}
multi method p6_to_p5(Str:D $value) returns Pointer {
    my $buf = $value.encode('UTF-8');
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
multi method p6_to_p5(Inline::Perl5::Object $value) returns Pointer {
    $!p5.p5_sv_refcnt_inc($value.ptr);
    $value.ptr;
}
multi method p6_to_p5(Inline::Perl5::Package $value) returns Pointer {
    self.p6_to_p5($value.unwrap-perl5-object());
}
multi method p6_to_p5(Inline::Perl5::Parent $value) returns Pointer {
    self.p6_to_p5($value.unwrap-perl5-object());
}
multi method p6_to_p5(Inline::Perl5::Extension $value) returns Pointer {
    self.p6_to_p5($value.unwrap-perl5-object());
}

my $objects = Inline::Language::ObjectKeeper.new; #FIXME not thread safe

multi method p6_to_p5(Inline::Perl5::Extension $value, Pointer $target) returns Pointer {
    my $index = $objects.keep($value);

    $!p5.p5_wrap_p6_object(
        $index,
        $target,
    );
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

sub free_p6_object(Int $index) {
    $objects.free($index);
}

multi method p6_to_p5(Any:D $value) {
    my $index = $objects.keep($value);

    $!p5.p5_wrap_p6_object(
        $index,
        Pointer,
    );
}
multi method p6_to_p5(Callable:D $value, Pointer $inst = Pointer) {
    my $index = $objects.keep($value);

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
    my $index = $objects.keep($value);

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
multi method p6_to_p5(Positional:D $value) returns Pointer {
    my $av = $!p5.p5_newAV();
    for @$value -> $item {
        $!p5.p5_av_push($av, self.p6_to_p5($item));
    }
    $!p5.p5_newRV_inc($av);
}
multi method p6_to_p5(IO::Handle:D $value) returns Pointer {
    my $index = $objects.keep($value);

    $!p5.p5_wrap_p6_handle(
        $index,
        Any,
    );
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

method p5_to_p6(Pointer $value, int32 $type is copy = 0) {
    return Any unless defined $value;
    $type ||= $!p5.p5_get_type($value);

    my enum P5Types <Unknown Object SubRef NV IV PV Array Hash P6Hash Undef ScalarRef>;
    given $type {
        when Object {
            if $!p5.p5_is_wrapped_p6_object($value) {
                return $objects.get($!p5.p5_unwrap_p6_object($value));
            }
            else {
                $!p5.p5_sv_refcnt_inc($value);
                return Inline::Perl5::Object.new(perl5 => self, ptr => $value);
            }
        }
        when SubRef {
            $!p5.p5_sv_refcnt_inc($value);
            return Inline::Perl5::Callable.new(perl5 => self, ptr => $value);
        }
        when NV {
            return $!p5.p5_sv_nv($value);
        }
        when IV {
            return $!p5.p5_sv_iv($value);
        }
        when PV {
            if $!p5.p5_sv_utf8($value) {
                return $!p5.p5_sv_to_char_star($value);
            }
            else {
                my $string_ptr = CArray[CArray[int8]].new;
                $string_ptr[0] = CArray[int8];
                my $len = $!p5.p5_sv_to_buf($value, $string_ptr);
                my $string := $string_ptr[0];
                return blob8.new(do for ^$len { $string.AT-POS($_) });
            }
        }
        when Array {
            return self!p5_array_to_writeback_p6_array($value);
        }
        when Hash {
            return self!p5_hash_to_writeback_p6_hash($value);
        }
        when P6Hash {
            return $objects.get($!p5.p5_unwrap_p6_hash($value));
        }
        when Undef {
            return Any;
        }
        when ScalarRef {
            return self!p5_scalar_ref_to_capture($value);
        }
    }
    die "Unsupported type $value in p5_to_p6";
}

method handle_p5_exception() is hidden-from-backtrace {
    if my $error = self.p5_to_p6($!p5.p5_err_sv()) {
        die $error;
    }
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
        if $_.isa(Pair) {
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
        if $_.isa(Pair) {
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

method !unpack_return_values($av, int32 $count, int32 $type = 0) {
    if defined $av {
        if $count == 1 {
            my $retval = self.p5_to_p6($av, $type);
            $!p5.p5_sv_refcnt_dec($av);
            $retval
        }
        else {
            Inline::Perl5::Array.new(ip5 => self, p5 => $!p5, :$av)
        }
    }
    else {
        Nil
    }
}

method call(Str $function, *@args, *%args) {
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
    self!unpack_return_values($av, $retvals, $type);
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
    self!unpack_return_values($av, $retvals, $type);
}

multi method invoke(Str $package, Str $function, *@args, *%args) {
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
    self!unpack_return_values($av, $retvals, $type);
}

multi method invoke(Pointer $obj, Str $function) {
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my $av = $!p5.p5_call_method(
        Str,
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
    self!unpack_return_values($av, $retvals, $type);
}

method invoke-args(Pointer $obj, Str $function, Capture $args) {
    my @svs := CArray[Pointer].new();
    my Int $j = 0;
    @svs[$j++] = $obj;
    for $args.list {
        if $_.isa(Pair) {
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
        Str,
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
    self!unpack_return_values($av, $retvals, $type);
}

multi method invoke(Pointer $obj, Str $function, *@args, *%args) {
    my @svs := CArray[Pointer].new();
    my Int $j = 0;
    @svs[$j++] = $obj;
    for @args {
        if $_.isa(Pair) {
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
        Str,
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
    self!unpack_return_values($av, $retvals, $type);
}

method invoke-parent(Str $package, Pointer $obj, Bool $context, Str $function, @args, %args) {
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my ($j, @svs) := self.setup_arguments(@args, %args);
    my $av = $!p5.p5_call_method(
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
    self!unpack_return_values($av, $retvals, $type);
}

method execute(Pointer $code_ref, *@args) {
    my int32 $retvals;
    my int32 $err;
    my int32 $type;
    my $av = $!p5.p5_call_code_ref($code_ref, |self.setup_arguments(@args), $retvals, $err, $type);
    self.handle_p5_exception() if $err;
    self!unpack_return_values($av, $retvals, $type);
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

class Perl6Callbacks {
    has $.p5;
    method create_extension($package, $code) {
        my $p5 = $.p5;
        EVAL "class GLOBAL::$package does Inline::Perl5::Extension['$package', \$p5] \{\n$code\n\}";
        return;
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
        my %named = classify * ~~ Pair, @args;
        %named<False> //= [];
        %named<True> //= [];
        return ::($package)."$name"(|%named<False>, |%(%named<True>));
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
            open *{main::DATA}, '<', \$data;
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

        package v6::inline;

        sub import {
            die 'v6::inline got renamed to v6-inline for compatibility with older Perl 5 versions. Sorry for the back and forth about this.';
        }

        $INC{'v6.pm'} = '';
        $INC{'v6/inline.pm'} = '';

        1;
        PERL5

    self.call('v6::init', Perl6Callbacks.new(:p5(self)));

    if $!external_p5 {
        $!p5.p5_inline_perl6_xs_init();
    }
}

method sv_refcnt_dec($obj) {
    return unless $!p5; # Destructor may already have run. Destructors of individual P5 objects no longer work.
    $!p5.p5_sv_refcnt_dec($obj);
}

method rebless(Inline::Perl5::Object $obj, Str $package, $p6obj) {
    my $index = $objects.keep($p6obj);
    $!p5.p5_rebless_object($obj.ptr, $package, $index);
}

method install_wrapper_method(Str:D $package, Str $name, *@attributes) {
    self.call('v6::install_p6_method_wrapper', $package, $name, |@attributes);
}

method subs_in_module(Str $module) {
    return self.run('[ grep { *{"' ~ $module ~ '::$_"}{CODE} } keys %' ~ $module ~ ':: ]');
}

method variables_in_module(Str $module) {
    return self.run('[ grep { *{"' ~ $module ~ '::$_"}{SCALAR} } keys %' ~ $module ~ ':: ]');
}

method import (Str $module, *@args) {
    my $before = set self.subs_in_module('main').list;
    self.invoke($module, 'import', @args.list);
    my $after = set self.subs_in_module('main').list;
    return ($after ∖ $before).keys;
}

method require(Str $module, Num $version?, Bool :$handle) {
    # wrap the load_module call so exceptions can be translated to Perl 6
    my @packages = $version
        ?? self.call('v6::load_module', $module, $version)
        !! self.call('v6::load_module', $module);

    return unless self eq $default_perl5; # Only create Perl 6 packages for the primary interpreter to avoid confusion

    if try ::($module) ~~ Inline::Perl5::Extension {
        # Wrapper package already created. Nothing left for us to do.
        return CompUnit::Handle.from-unit(Stash.new);
    }

    my $stash := $handle ?? Stash.new !! ::GLOBAL.WHO;

    my $class;
    for @packages.grep(*.defined) -> $package {
        next if try ::($package) ~~ Inline::Perl5::Extension;
        my $created := self!create_wrapper_class($package, $stash);
        $class := $created if $package eq $module;
    }

    my &export := sub EXPORT(*@args) {
            $*W.do_pragma(Any, 'precompilation', False, []);
            my @symbols = self.import($module, @args.list).map({
                my $name = $_;
                '&' ~ $name => sub (|args) {
                    self.call-args("main::$name", args); # main:: because the sub got exported to main
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

    my $compunit-handle = class :: is CompUnit::Handle {
        has &!EXPORT;
        use nqp;
        submethod fill(Stash $unit, &EXPORT) {
            nqp::p6bindattrinvres(
                nqp::p6bindattrinvres(
                  nqp::create($?CLASS),
                  CompUnit::Handle,
                  '$!unit',
                  nqp::decont($unit),
                ),
                $?CLASS,
                '&!EXPORT',
                &EXPORT,
            )
        }
        method export-package() returns Stash {
            Stash.new
        }
        method export-sub() returns Callable {
            &!EXPORT
        }
    }.fill(
        $stash,
        &export,
    );

    return $compunit-handle;
}

my %loaded_modules;
method !create_wrapper_class(Str $module, Stash $stash) {
    my $class;
    my $first-time = True;
    my $symbols = self.subs_in_module($module);
    my $variables = self.variables_in_module($module);
    if %loaded_modules{$module}:exists {
        $class := %loaded_modules{$module};
        $first-time = False;
    }
    else {
        my $p5 := self;

        %loaded_modules{$module} := $class := Metamodel::ClassHOW.new_type(name => $module);
        $class.^add_role(Inline::Perl5::Package[$p5, $module]);

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
        $class.WHO{$_.key} := $_.value for @existing;
    }

    if $first-time {
        # install subs like Test::More::ok
        for @$symbols -> $name {
            $class.WHO{"&$name"} := sub (*@args) {
                self.call("{$module}::$name", @args.list);
            }
        }
        for @$variables -> $name {
            $class.WHO{'$' ~ $name} := Proxy.new(
                FETCH => {
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

method use(Str $module, *@args) {
    self.require($module);
    self.import($module, @args.list);
}

submethod DESTROY {
    $!p5.p5_destruct_perl() if $!p5 and not $!external_p5;
    $!p5 = Inline::Perl5::Interpreter;
}


method default_perl5 {
    return $default_perl5 //= self.new();
}

method retrieve_scalar_context() {
    my $scalar_context = $!scalar_context;
    $!scalar_context = False;
    return $scalar_context;
}

class X::Inline::Perl5::NoMultiplicity is Exception {
    method message() {
        "You need to compile perl with -DMULTIPLICITY for running multiple interpreters."
    }
}

method init_data($data) {
    self.call('v6::init_data', $data);
}

method BUILD(*%args) {
    my &call_method = sub (Int $index, Str $name, Int $context, Pointer $args, Pointer $err) returns Pointer {
        my $p6obj = $objects.get($index);
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
        self.p6_to_p5(@ = $p6obj."$name"(|self.p5_array_to_p6_array($args)));
    }
    &call_method does Inline::Perl5::Caller;

    my &call_callable = sub (Int $index, Pointer $args, Pointer $err) returns Pointer {
        my $callable = $objects.get($index);
        my @retvals = $callable(|self.p5_array_to_p6_array($args));
        return self.p6_to_p5(@retvals);
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
    }

    my &hash_at_key = sub (Int $index, Str $key) returns Pointer {
        return self.p6_to_p5($objects.get($index).AT-KEY($key));
        CONTROL {
            when CX::Warn {
                note $_.gist;
                $_.resume;
            }
        }
    }

    my &hash_assign_key = sub (Int $index, Str $key, Pointer $value) {
        $objects.get($index).ASSIGN-KEY($key, self.p5_to_p6($value));
        Nil;
        CONTROL {
            when CX::Warn {
                note $_.gist;
                $_.resume;
            }
        }
    }

    if ($*W) {
        my $block := { self.init_data(CALLER::<$=finish>) if CALLER::<$=finish> };
        $*W.add_object($block);
        my $op := $*W.add_phaser(Mu, 'INIT', $block, class :: { method cuid { (^2**128).pick }});
    }

    $!external_p5 = %args<p5>:exists;
    if $!external_p5 {
        $!p5 = %args<p5>;
        Inline::Perl5::Interpreter::p5_init_callbacks(
            &call_method,
            &call_callable,
            &free_p6_object,
            &hash_at_key,
            &hash_assign_key,
        );
    }
    else {
        my @args = @*ARGS;
        $!p5 = Inline::Perl5::Interpreter::p5_init_perl(
            @args.elems + 4,
            CArray[Str].new('', '-e', '0', '--', |@args, Str),
            &call_method,
            &call_callable,
            &free_p6_object,
            &hash_at_key,
            &hash_assign_key,
        );
        X::Inline::Perl5::NoMultiplicity.new.throw unless $!p5.defined;
    }

    self.init_callbacks();

    $default_perl5 //= self;
}

# for backwards compatibility with documented interfaces
OUR::<Perl5Attributes> := Inline::Perl5::Attributes;
OUR::<Perl5Parent>     := Inline::Perl5::Parent;

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
    # Perl 6 does not guarantee that DESTROY methods are called at program exit.
    # Make sure at least the first Perl 5 interpreter is correctly shut down and thus can e.g.
    # flush its output buffers. This should at least fix the vast majority of use cases.
    # People who really do use multiple Perl 5 interpreters are probably experienced enough
    # to find proper workarounds for their cases.
    $default_perl5.DESTROY if $default_perl5;

    p5_terminate unless $inline_perl6_in_use;
}
