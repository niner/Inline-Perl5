class Inline::Perl5::Interpreter is repr('CPointer') {
    use NativeCall;

    my constant $p5helper = %?RESOURCES<libraries/p5helper>.Str;

    our sub p5_size_of_iv() is native($p5helper)
        returns size_t { ... }

    our sub p5_size_of_nv() is native($p5helper)
        returns size_t { ... }

    BEGIN my constant IV = p5_size_of_iv() == 8 ?? int64 !! int32;
    BEGIN my constant NVSIZE = p5_size_of_nv();
    BEGIN die "Cannot support { NVSIZE * 8 } bit NVs yet." if NVSIZE != 4|8;
    BEGIN my constant NV = NVSIZE == 8 ?? num64 !! num32;

    our sub p5_init_perl(
        uint32,
        CArray[Str],
        &call_method (IV, Str, int32, Pointer, Pointer --> Pointer),
        &call (IV, Pointer, Pointer --> Pointer),
        &free_p6_object (IV),
        &hash_at_key (IV, Str --> Pointer),
        &hash_assign_key (IV, Str, Pointer),
    ) is native($p5helper)
        returns Inline::Perl5::Interpreter { ... }

    our sub p5_init_callbacks(
        &call_method (IV, Str, int32, Pointer, Pointer --> Pointer),
        &call (IV, Pointer, Pointer --> Pointer),
        &free_p6_object (IV),
        &hash_at_key (IV, Str --> Pointer),
        &hash_assign_key (IV, Str, Pointer),
    ) is native($p5helper)
        { ... }

    our sub p5_terminate() is native($p5helper)
        { ... }

    method p5_inline_perl6_xs_init() is native($p5helper)
        { ... }

    method p5_SvIOK(Pointer) is native($p5helper)
        returns uint32 { ... }

    method p5_SvNOK(Pointer) is native($p5helper)
        returns uint32 { ... }

    method p5_SvPOK(Pointer) is native($p5helper)
        returns uint32 { ... }

    method p5_sv_utf8(Pointer) is native($p5helper)
        returns uint32 { ... }

    method p5_is_array(Pointer) is native($p5helper)
        returns int32 { ... }

    method p5_is_hash(Pointer) is native($p5helper)
        returns int32 { ... }

    method p5_is_scalar_ref(Pointer) is native($p5helper)
        returns int32 { ... }

    method p5_is_undef(Pointer) is native($p5helper)
        returns int32 { ... }

    method p5_get_type(Pointer) is native($p5helper)
        returns int32 { ... }

    method p5_sv_to_buf(Pointer, CArray[CArray[int8]]) is native($p5helper)
        returns size_t { ... }

    method p5_sv_to_char_star(Pointer) is native($p5helper)
        returns Str { ... }

    method p5_sv_to_av(Pointer) is native($p5helper)
        returns Pointer { ... }

    method p5_sv_to_av_inc(Pointer) is native($p5helper)
        returns Pointer { ... }

    method p5_sv_to_hv(Pointer) is native($p5helper)
        returns Pointer { ... }

    method p5_sv_refcnt_dec(Pointer) is native($p5helper)
        { ... }

    method p5_sv_2mortal(Pointer) is native($p5helper)
        { ... }

    method p5_sv_refcnt_inc(Pointer) is native($p5helper)
        { ... }

    method p5_int_to_sv(IV) is native($p5helper)
        returns Pointer { ... }

    method p5_float_to_sv(NV) is native($p5helper)
        returns Pointer { ... }

    method p5_str_to_sv(size_t, Blob) is native($p5helper)
        returns Pointer { ... }

    method p5_buf_to_sv(size_t, Blob) is native($p5helper)
        returns Pointer { ... }

    method p5_sv_to_ref(Pointer) is native($p5helper)
        returns Pointer { ... }

    method p5_av_top_index(Pointer) is native($p5helper)
        returns int32 { ... }

    method p5_av_fetch(Pointer, int32) is native($p5helper)
        returns Pointer { ... }

    method p5_av_store(Pointer, int32, Pointer) is native($p5helper)
        { ... }

    method p5_av_pop(Pointer) is native($p5helper)
        returns Pointer { ... }

    method p5_av_push(Pointer, Pointer) is native($p5helper)
        { ... }

    method p5_av_shift(Pointer) is native($p5helper)
        returns Pointer { ... }

    method p5_av_unshift(Pointer, Pointer) is native($p5helper)
        { ... }

    method p5_av_delete(Pointer, int32) is native($p5helper)
        { ... }

    method p5_av_clear(Pointer) is native($p5helper)
        { ... }

    method p5_hv_iterinit(Pointer) is native($p5helper)
        returns int32 { ... }

    method p5_hv_iternext(Pointer) is native($p5helper)
        returns Pointer { ... }

    method p5_hv_iterkeysv(Pointer) is native($p5helper)
        returns Pointer { ... }

    method p5_hv_iterval(Pointer, Pointer) is native($p5helper)
        returns Pointer { ... }

    method p5_undef() is native($p5helper)
        returns Pointer { ... }

    method p5_newHV() is native($p5helper)
        returns Pointer { ... }

    method p5_newAV() is native($p5helper)
        returns Pointer { ... }

    method p5_newRV_inc(Pointer) is native($p5helper)
        returns Pointer { ... }

    method p5_newRV_noinc(Pointer) is native($p5helper)
        returns Pointer { ... }

    method p5_sv_reftype(Pointer) is native($p5helper)
        returns Str { ... }

    method p5_hv_fetch(Pointer, size_t, Blob) is native($p5helper)
        returns Pointer { ... }

    method p5_hv_store(Pointer, Str, Pointer) is native($p5helper)
        { ... }

    method p5_hv_exists(Pointer, size_t, Blob) is native($p5helper)
        returns int32 { ... }

    method p5_call_function(Str, int32, CArray[Pointer], int32 is rw, int32 is rw, int32 is rw) is native($p5helper)
        returns Pointer { ... }

    method p5_call_method(Str, Pointer, int32, Str, int32, Pointer, int32 is rw, int32 is rw, int32 is rw) is native($p5helper)
        returns Pointer { ... }

    method p5_call_package_method(Str, Str, int32, CArray[Pointer], int32 is rw, int32 is rw, int32 is rw) is native($p5helper)
        returns Pointer { ... }

    method p5_call_code_ref(Pointer, int32, CArray[Pointer], int32 is rw, int32 is rw, int32 is rw) is native($p5helper)
        returns Pointer { ... }

    method p5_rebless_object(Pointer, Str, IV) is native($p5helper)
        { ... }

    method p5_destruct_perl() is native($p5helper)
        { ... }

    method p5_sv_iv(Pointer) is native($p5helper)
        returns IV { ... }

    method p5_sv_nv(Pointer) is native($p5helper)
        returns NV { ... }

    method p5_sv_rv(Pointer) is native($p5helper)
        returns Pointer { ... }

    method p5_is_object(Pointer) is native($p5helper)
        returns int32 { ... }

    method p5_is_sub_ref(Pointer) is native($p5helper)
        returns int32 { ... }

    method p5_get_global(Str) is native($p5helper)
        returns Pointer { ... }

    method p5_set_global(Str, Pointer) is native($p5helper)
        { ... }

    method p5_eval_pv(Str, int32) is native($p5helper)
        returns Pointer { ... }

    method p5_err_sv() is native($p5helper)
        returns Pointer { ... }

    method p5_wrap_p6_object(IV, Pointer) is native($p5helper)
        returns Pointer { ... }

    method p5_wrap_p6_callable(IV, Pointer) is native($p5helper)
        returns Pointer { ... }

    method p5_wrap_p6_hash(
        IV,
    ) is native($p5helper)
        returns Pointer { ... }

    method p5_wrap_p6_handle(IV, Pointer) is native($p5helper)
        returns Pointer { ... }

    method p5_is_wrapped_p6_object(Pointer) is native($p5helper)
        returns int32 { ... }

    method p5_unwrap_p6_object(Pointer) is native($p5helper)
        returns IV { ... }

    method p5_unwrap_p6_hash(Pointer) is native($p5helper)
        returns IV { ... }

}

