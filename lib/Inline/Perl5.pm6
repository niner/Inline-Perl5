class Inline::Perl5 is repr('CPointer');

use NativeCall;

my Str $p5helper;
BEGIN {
    $p5helper = IO::Path.new($?FILE).directory ~ '/p5helper.so';
}

class Perl5Object { ... }

class X::Inline::Perl5::Unmarshallable is Exception {
    has Mu $.object;
    method message() {
        "Don't know how to pass object of type {$.object.^name} to Perl 5 code";
    }
}

sub p5_init_perl()
    is native($p5helper)
    returns Inline::Perl5 { * }
sub p5_SvIOK(Inline::Perl5, OpaquePointer)
    is native($p5helper)
    returns Int { * }
sub p5_SvPOK(Inline::Perl5, OpaquePointer)
    is native($p5helper)
    returns Int { * }
sub p5_is_array(Inline::Perl5, OpaquePointer)
    is native($p5helper)
    returns Int { * }
sub p5_is_hash(Inline::Perl5, OpaquePointer)
    is native($p5helper)
    returns Int { * }
sub p5_is_undef(Inline::Perl5, OpaquePointer)
    is native($p5helper)
    returns Int { * }
sub p5_sv_to_char_star(Inline::Perl5, OpaquePointer)
    is native($p5helper)
    returns Str { * }
sub p5_sv_to_av(Inline::Perl5, OpaquePointer)
    is native($p5helper)
    returns OpaquePointer { * }
sub p5_sv_to_hv(Inline::Perl5, OpaquePointer)
    is native($p5helper)
    returns OpaquePointer { * }
sub p5_int_to_sv(Inline::Perl5, Int)
    is native($p5helper)
    returns OpaquePointer { * }
sub p5_str_to_sv(Inline::Perl5, Str)
    is native($p5helper)
    returns OpaquePointer { * }
sub p5_av_top_index(Inline::Perl5, OpaquePointer)
    is native($p5helper)
    returns Int { * }
sub p5_av_fetch(Inline::Perl5, OpaquePointer, Int)
    is native($p5helper)
    returns OpaquePointer { * }
sub p5_av_push(Inline::Perl5, OpaquePointer, OpaquePointer)
    is native($p5helper)
    { * }
sub p5_hv_iterinit(Inline::Perl5, OpaquePointer)
    is native($p5helper)
    returns Int { * }
sub p5_hv_iternext(Inline::Perl5, OpaquePointer)
    is native($p5helper)
    returns OpaquePointer { * }
sub p5_hv_iterkeysv(Inline::Perl5, OpaquePointer)
    is native($p5helper)
    returns OpaquePointer { * }
sub p5_hv_iterval(Inline::Perl5, OpaquePointer, OpaquePointer)
    is native($p5helper)
    returns OpaquePointer { * }
sub p5_undef(Inline::Perl5)
    is native($p5helper)
    returns OpaquePointer { * }
sub p5_newHV(Inline::Perl5)
    is native($p5helper)
    returns OpaquePointer { * }
sub p5_newAV(Inline::Perl5)
    is native($p5helper)
    returns OpaquePointer { * }
sub p5_newRV_noinc(Inline::Perl5, OpaquePointer)
    is native($p5helper)
    returns OpaquePointer { * }
sub p5_hv_store_ent(Inline::Perl5, OpaquePointer, OpaquePointer, OpaquePointer)
    is native($p5helper)
    { * }
sub p5_call_function(Inline::Perl5, Str, Int, CArray[OpaquePointer])
    is native($p5helper)
    returns OpaquePointer { * }
sub p5_destruct_perl(Inline::Perl5)
    is native($p5helper)
    { * }
sub p5_sv_iv(Inline::Perl5, OpaquePointer)
    is native($p5helper)
    returns Int { * }
sub p5_is_object(Inline::Perl5, OpaquePointer)
    is native($p5helper)
    returns Int { * }
sub p5_eval_pv(Inline::Perl5, Str, Int)
    is native($p5helper)
    returns OpaquePointer { * }
sub p5_wrap_p6_object(Inline::Perl5, &unwrap(), &call_method(Str, OpaquePointer --> OpaquePointer))
    is native($p5helper)
    returns OpaquePointer { * }
sub p5_is_wrapped_p6_object(Inline::Perl5, OpaquePointer)
    is native($p5helper)
    returns Int { * }
sub p5_unwrap_p6_object(Inline::Perl5, OpaquePointer)
    is native($p5helper)
    { * }

multi method p6_to_p5(Int:D $value) returns OpaquePointer {
    return p5_int_to_sv(self, $value);
}
multi method p6_to_p5(Str:D $value) returns OpaquePointer {
    return p5_str_to_sv(self, $value);
}
multi method p6_to_p5(Perl5Object $value) returns OpaquePointer {
    return $value.ptr;
}
multi method p6_to_p5(OpaquePointer $value) returns OpaquePointer {
    return $value;
}
multi method p6_to_p5(Any:U $value) returns OpaquePointer {
    return p5_undef(self);
}
my $unwrapped;
my @objects;
multi method p6_to_p5(Any:D $value) {
    @objects.push($value);
    return p5_wrap_p6_object(
        self,
        -> {
            $unwrapped = $value
        },
        sub (Str $name, OpaquePointer $args) returns OpaquePointer {
            my @retvals = $value."$name"(|self!p5_array_to_p6_array($args));
            return self.p6_to_p5(@retvals);
            CATCH { default { say $_; } }
        },
    );
    X::Inline::Perl5::Unmarshallable.new(
        :object($value),
    ).throw;
}
multi method p6_to_p5(Hash:D $value) returns OpaquePointer {
    my $hv = p5_newHV(self);
    for %$value -> $item {
        my $key = p5_str_to_sv(self, $item.key);
        my $value = self.p6_to_p5($item.value);
        p5_hv_store_ent(self, $hv, $key, $value);
    }
    return p5_newRV_noinc(self, $hv);
}
multi method p6_to_p5(Positional:D $value) returns OpaquePointer {
    my $av = p5_newAV(self);
    for @$value -> $item {
        p5_av_push(self, $av, self.p6_to_p5($item));
    }
    return p5_newRV_noinc(self, $av);
}

method !p5_array_to_p6_array(OpaquePointer $sv) {
    my $av = p5_sv_to_av(self, $sv);
    my $av_len = p5_av_top_index(self, $av);

    my $arr = [];
    loop (my $i = 0; $i <= $av_len; $i++) {
        $arr.push(self.p5_to_p6(p5_av_fetch(self, $av, $i)));
    }
    return $arr;
}
method !p5_hash_to_p6_hash(OpaquePointer $sv) {
    my OpaquePointer $hv = p5_sv_to_hv(self, $sv);

    my Int $len = p5_hv_iterinit(self, $hv);

    my $hash = {};

    for 0 .. $len - 1 {
        my OpaquePointer $next = p5_hv_iternext(self, $hv);
        my OpaquePointer $key = p5_hv_iterkeysv(self, $next);
        die 'Hash entry without key!?' unless $key;
        my Str $p6_key = p5_sv_to_char_star(self, $key);
        my $val = self.p5_to_p6(p5_hv_iterval(self, $hv, $next));
        $hash{$p6_key} = $val;
    }

    return $hash;
}

method p5_to_p6(OpaquePointer $value) {
    if p5_is_object(self, $value) {
        if p5_is_wrapped_p6_object(self, $value) {
            p5_unwrap_p6_object(self, $value);
            return $unwrapped;
        }
        else {
            return Perl5Object.new(perl5 => self, ptr => $value);
        }
    }
    elsif p5_SvIOK(self, $value) {
        return p5_sv_iv(self, $value);
    }
    elsif p5_SvPOK(self, $value) {
        return p5_sv_to_char_star(self, $value);
    }
    elsif p5_is_array(self, $value) {
        return self!p5_array_to_p6_array($value);
    }
    elsif p5_is_hash(self, $value) {
        return self!p5_hash_to_p6_hash($value);
    }
    elsif p5_is_undef(self, $value) {
        return Any;
    }
    die "Unsupported type $value in p5_to_p6";
}

method run($perl) {
    my $res = p5_eval_pv(self, $perl, 1);
    return self.p5_to_p6($res);
}

method call(Str $function, *@args) {
    my $len = @args.elems;
    my @svs := CArray[OpaquePointer].new();
    loop (my $i = 0; $i < $len; $i++) {
        @svs[$i] = self.p6_to_p5(@args[$i]);
    }

    my $av = p5_call_function(self, $function, $len, @svs);
    my $av_len = p5_av_top_index(self, $av);
    return
        if $av_len == -1;
    return self.p5_to_p6(p5_av_fetch(self, $av, 0))
        if $av_len == 0;

    my @retvals;
    loop ($i = 0; $i <= $av_len; $i++) {
        @retvals.push(self.p5_to_p6(p5_av_fetch(self, $av, $i)));
    }
    return @retvals;
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

submethod DESTROY {
    p5_destruct_perl(self);
}

class Perl5Object {
    has OpaquePointer $.ptr;
    has Inline::Perl5 $.perl5;

    Perl5Object.^add_fallback(-> $, $ { True },
        method ($name ) {
            -> \self, |args {
                $.perl5.call($name, $.ptr, args.list);
            }
        }
    );

    method sink() { self }
}


method new() returns Inline::Perl5 {
    my $i = p5_init_perl();
    $i.init_callbacks();
    return $i;
}
