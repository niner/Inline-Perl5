#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

static void xs_init (pTHX);
EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);
EXTERN_C void boot_Socket (pTHX_ CV* cv);

typedef struct {
    I32 key; /* to make sure it came from Inline */
    IV index;
    union {
        SV *(*call_p6_method)(IV, char *, I32, SV *, SV **);
        SV *(*call_p6_callable)(IV, SV *, SV **);
    };
    void (*free_p6_object)(IV);
} _perl6_magic;

typedef struct {
    I32 key; /* to make sure it came from Inline */
    IV index;
    SV *(*call_p6_method)(IV, char *, I32, SV *, SV **);
    SV *(*hash_at_key)(IV, char *);
    SV *(*hash_assign_key)(IV, char *, SV *);
    void (*free_p6_object)(IV);
} _perl6_hash_magic;

XS(p5_call_p6_method);
XS(p5_call_p6_callable);
XS(p5_hash_at_key);
XS(p5_hash_assign_key);
XS(p5_load_module);
XS(p5_set_subname);

EXTERN_C void xs_init(pTHX) {
    char *file = __FILE__;
    /* DynaLoader is a special case */
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
    newXS("Perl6::Object::call_method", p5_call_p6_method, file);
    newXS("Perl6::Hash::FETCH", p5_hash_at_key, file);
    newXS("Perl6::Hash::STORE", p5_hash_assign_key, file);
    newXS("Perl6::Callable::call", p5_call_p6_callable, file);
    newXS("v6::load_module_impl", p5_load_module, file);
    newXS("v6::set_subname", p5_set_subname, file);
}

size_t p5_size_of_iv() {
    return IVSIZE;
}

#if NVSIZE > 8
#    define MYNVSIZE 8
#    define MYNV double
#else
#    define MYNVSIZE NVSIZE
#    define MYNV NV
#endif

size_t p5_size_of_nv() {
    return MYNVSIZE;
}

void p5_inline_perl6_xs_init(PerlInterpreter *my_perl) {
    char *file = __FILE__;
    newXS("Perl6::Object::call_method", p5_call_p6_method, file);
    newXS("Perl6::Hash::FETCH", p5_hash_at_key, file);
    newXS("Perl6::Hash::STORE", p5_hash_assign_key, file);
    newXS("Perl6::Callable::call", p5_call_p6_callable, file);
    newXS("v6::load_module_impl", p5_load_module, file);
    newXS("v6::set_subname", p5_set_subname, file);
}

static int inited = 0;
static int interpreters = 0;
static int terminate = 0;

PerlInterpreter *p5_init_perl(int argc, char **argv) {
    if (inited) {
#ifndef MULTIPLICITY
        return NULL;
#endif
    }
    else {
        inited = 1;
        PERL_SYS_INIT(&argc, &argv);
    }

    interpreters++;

    PerlInterpreter *my_perl = perl_alloc();
    PERL_SET_CONTEXT(my_perl);
    PL_perl_destruct_level = 1;
    perl_construct( my_perl );
    perl_parse(my_perl, xs_init, argc, argv, NULL);
    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
    perl_run(my_perl);

    return my_perl;
}

void p5_destruct_perl(PerlInterpreter *my_perl) {
    PL_perl_destruct_level = 1;

    POPSTACK_TO(PL_mainstack);
    dounwind(-1);
    LEAVE_SCOPE(0);

    perl_destruct(my_perl);
    perl_free(my_perl);

    if (--interpreters == 0 && terminate)
        PERL_SYS_TERM();
}

void p5_terminate() {
    terminate = 1;
}

U32 p5_SvIOK(PerlInterpreter *my_perl, SV* sv) {
    return SvIOK(sv);
}

U32 p5_SvNOK(PerlInterpreter *my_perl, SV* sv) {
    return SvNOK(sv);
}

U32 p5_SvPOK(PerlInterpreter *my_perl, SV* sv) {
    return SvPOK(sv);
}

U32 p5_sv_utf8(PerlInterpreter *my_perl, SV* sv) {
    if (SvUTF8(sv)) { // UTF-8 flag set -> can use string as-is
        return 1;
    }
    else { // pure 7 bit ASCII is valid UTF-8 as well
        STRLEN len;
        char * const pv  = SvPV(sv, len);
        STRLEN i;
        for (i = 0; i < len; i++)
            if (pv[i] < 0) // signed char!
                return 0;
        return 1;
    }
}

IV p5_sv_iv(PerlInterpreter *my_perl, SV* sv) {
    return SvIV(sv);
}

MYNV p5_sv_nv(PerlInterpreter *my_perl, SV* sv) {
    return (MYNV) SvNV(sv);
}

SV *p5_sv_rv(PerlInterpreter *my_perl, SV* sv) {
    return SvRV(sv);
}

int p5_is_object(PerlInterpreter *my_perl, SV* sv) {
    return sv_isobject(sv);
}

int p5_is_sub_ref(PerlInterpreter *my_perl, SV* sv) {
    return (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV);
}

int p5_is_array(PerlInterpreter *my_perl, SV* sv) {
    return (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV);
}

int p5_is_hash(PerlInterpreter *my_perl, SV* sv) {
    MAGIC *mg;
    return (
        (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV)
        ? ((mg = mg_find(SvRV(sv), PERL_MAGIC_tied)) && sv_isa(mg->mg_obj, "Perl6::Hash"))
            ? 2
            : 1
        : 0
    );
}

IV p5_unwrap_p6_hash(PerlInterpreter *my_perl, SV *obj) {
    MAGIC * const tie_mg = mg_find(SvRV(obj), PERL_MAGIC_tied);
    SV * const hash = tie_mg->mg_obj;
    SV * const p6hashobj = *(av_fetch((AV *) SvRV(hash), 0, 0));
    MAGIC * const mg = mg_find(SvRV(p6hashobj), '~');
    return ((_perl6_hash_magic*)(mg->mg_ptr))->index;
}

int p5_is_scalar_ref(PerlInterpreter *my_perl, SV* sv) {
    return (SvROK(sv) && SvTYPE(SvRV(sv)) < SVt_PVAV);
}

int p5_is_undef(PerlInterpreter *my_perl, SV* sv) {
    return !SvOK(sv);
}

AV *p5_sv_to_av(PerlInterpreter *my_perl, SV* sv) {
    return (AV *) SvRV(sv);
}

HV *p5_sv_to_hv(PerlInterpreter *my_perl, SV* sv) {
    return (HV *) SvRV(sv);
}

char *p5_sv_to_char_star(PerlInterpreter *my_perl, SV *sv) {
    STRLEN len;
    char * const pv  = SvPV(sv, len);
    return pv;
}

STRLEN p5_sv_to_buf(PerlInterpreter *my_perl, SV *sv, char **buf) {
    STRLEN len;
    *buf  = SvPV(sv, len);
    return len;
}

SV *p5_sv_to_ref(PerlInterpreter *my_perl, SV *sv) {
    return newRV_noinc(sv);
}

void p5_sv_refcnt_dec(PerlInterpreter *my_perl, SV *sv) {
    SvREFCNT_dec(sv);
}

void p5_sv_refcnt_inc(PerlInterpreter *my_perl, SV *sv) {
    SvREFCNT_inc(sv);
}

SV *p5_int_to_sv(PerlInterpreter *my_perl, IV value) {
    return newSViv(value);
}

SV *p5_float_to_sv(PerlInterpreter *my_perl, MYNV value) {
    return newSVnv((NV)value);
}

SV *p5_str_to_sv(PerlInterpreter *my_perl, STRLEN len, char* value) {
    return newSVpvn_flags(value, len, SVf_UTF8);
}

SV *p5_buf_to_sv(PerlInterpreter *my_perl, STRLEN len, char* value) {
    return newSVpvn_flags(value, len, 0);
}

I32 p5_av_top_index(PerlInterpreter *my_perl, AV *av) {
    return av_top_index(av);
}

SV *p5_av_fetch(PerlInterpreter *my_perl, AV *av, I32 key) {
    SV ** const item = av_fetch(av, key, 0);
    if (item)
        return *item;
    return NULL;
}

void p5_av_push(PerlInterpreter *my_perl, AV *av, SV *sv) {
    av_push(av, sv);
}

I32 p5_hv_iterinit(PerlInterpreter *my_perl, HV *hv) {
    return hv_iterinit(hv);
}

HE *p5_hv_iternext(PerlInterpreter *my_perl, HV *hv) {
    return hv_iternext(hv);
}

SV *p5_hv_iterkeysv(PerlInterpreter *my_perl, HE *entry) {
    return hv_iterkeysv(entry);
}

SV *p5_hv_iterval(PerlInterpreter *my_perl, HV *hv, HE *entry) {
    return hv_iterval(hv, entry);
}

SV *p5_hv_fetch(PerlInterpreter *my_perl, HV *hv, STRLEN len, const char *key) {
    SV ** const item = hv_fetch(hv, key, len, 0);
    if (item)
        return *item;
    return NULL;
}

void p5_hv_store(PerlInterpreter *my_perl, HV *hv, const char *key, SV *val) {
    hv_store(hv, key, strlen(key), val, 0);
}

int p5_hv_exists(PerlInterpreter *my_perl, HV *hv, STRLEN len, const char *key) {
    return hv_exists(hv, key, len);
}

SV *p5_undef(PerlInterpreter *my_perl) {
    return &PL_sv_undef;
}

HV *p5_newHV(PerlInterpreter *my_perl) {
    return newHV();
}

AV *p5_newAV(PerlInterpreter *my_perl) {
    return newAV();
}

SV *p5_newRV_noinc(PerlInterpreter *my_perl, SV *sv) {
    return newRV_noinc(sv);
}

SV *p5_newRV_inc(PerlInterpreter *my_perl, SV *sv) {
    return newRV_inc(sv);
}

const char *p5_sv_reftype(PerlInterpreter *my_perl, SV *sv) {
    return sv_reftype(SvRV(sv), 1);
}

SV *p5_get_global(PerlInterpreter *my_perl, const char* name) {
    if (strlen(name) < 2)
        return NULL;

    if (name[0] == '$')
        return get_sv(&name[1], 0);

    if (name[0] == '@')
        return sv_2mortal(newRV_inc((SV *)get_av(&name[1], 0)));

    if (name[0] == '%')
        return sv_2mortal(newRV_inc((SV *)get_hv(&name[1], 0)));

    return NULL;
}

SV *p5_eval_pv(PerlInterpreter *my_perl, const char* p, I32 croak_on_error) {
    PERL_SET_CONTEXT(my_perl);
    return eval_pv(p, croak_on_error);
}

SV *p5_err_sv(PerlInterpreter *my_perl) {
    return sv_mortalcopy(ERRSV);
}

AV *p5_call_package_method(PerlInterpreter *my_perl, char *package, char *name, int len, SV *args[]) {
    PERL_SET_CONTEXT(my_perl);
    {
        dSP;
        int i;
        I32 count;
        AV * const retval = newAV();
        int flags = G_ARRAY | G_EVAL;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);

        XPUSHs(newSVpv(package, 0));
        for (i = 0; i < len; i++) {
            XPUSHs(sv_2mortal(args[i]));
        }

        PUTBACK;

        count = call_method(name, flags);
        SPAGAIN;

        if (count > 0)
            av_extend(retval, count - 1);

        for (i = count - 1; i >= 0; i--) {
            SV * const next = POPs;
            SvREFCNT_inc(next);

            if (av_store(retval, i, next) == NULL)
                SvREFCNT_dec(next); /* see perlguts Working with AVs */
        }

        PUTBACK;
        FREETMPS;
        LEAVE;

        return retval;
    }
}

AV *p5_call_method(PerlInterpreter *my_perl, char *package, SV *obj, I32 context, char *name, int len, SV *args[]) {
    PERL_SET_CONTEXT(my_perl);
    {
        dSP;
        int i;
        AV * const retval = newAV();
        int flags = (context ? G_SCALAR : G_ARRAY) | G_EVAL;

        ENTER;
        SAVETMPS;

        HV * const pkg = package != NULL ? gv_stashpv(package, 0) : SvSTASH((SV*)SvRV(obj));
        GV * const gv = Perl_gv_fetchmethod_autoload(aTHX_ pkg, name, TRUE);
        if (gv && isGV(gv)) {
            I32 count;
            PUSHMARK(SP);

            for (i = 0; i < len; i++) {
                XPUSHs(sv_2mortal(args[i]));
            }

            PUTBACK;

            SV * const rv = sv_2mortal(newRV((SV*)GvCV(gv)));

            count = call_sv(rv, flags);
            SPAGAIN;

            if (count > 0)
                av_extend(retval, count - 1);
            for (i = count - 1; i >= 0; i--) {
                SV * const next = POPs;
                SvREFCNT_inc(next);

                if (av_store(retval, i, next) == NULL)
                    SvREFCNT_dec(next); /* see perlguts Working with AVs */
            }
        }
        else {
            ERRSV = newSVpvf("Could not find method \"%s\" of \"%s\" object", name, HvNAME(pkg));
        }

        PUTBACK;
        FREETMPS;
        LEAVE;

        return retval;
    }
}

AV *p5_call_function(PerlInterpreter *my_perl, char *name, int len, SV *args[]) {
    PERL_SET_CONTEXT(my_perl);
    {
        dSP;
        int i;
        I32 count;
        AV * const retval = newAV();
        int flags = G_ARRAY | G_EVAL;


        ENTER;
        SAVETMPS;

        PUSHMARK(SP);

        for (i = 0; i < len; i++) {
            XPUSHs(sv_2mortal(args[i]));
        }

        PUTBACK;

        count = call_pv(name, flags);
        SPAGAIN;

        if (count > 0)
            av_extend(retval, count - 1);
        for (i = count - 1; i >= 0; i--) {
            SV * const next = POPs;
            SvREFCNT_inc(next);

            if (av_store(retval, i, next) == NULL)
                SvREFCNT_dec(next); /* see perlguts Working with AVs */
        }

        PUTBACK;
        FREETMPS;
        LEAVE;

        return retval;
    }
}

AV *p5_call_code_ref(PerlInterpreter *my_perl, SV *code_ref, int len, SV *args[]) {
    PERL_SET_CONTEXT(my_perl);
    {
        dSP;
        int i;
        I32 count;
        AV * const retval = newAV();
        int flags = G_ARRAY | G_EVAL;


        ENTER;
        SAVETMPS;

        PUSHMARK(SP);

        for (i = 0; i < len; i++) {
            XPUSHs(sv_2mortal(args[i]));
        }

        PUTBACK;

        count = call_sv(code_ref, flags);
        SPAGAIN;

        if (count > 0)
            av_extend(retval, count - 1);
        for (i = count - 1; i >= 0; i--) {
            SV * const next = POPs;
            SvREFCNT_inc(next);

            if (av_store(retval, i, next) == NULL)
                SvREFCNT_dec(next); /* see perlguts Working with AVs */
        }

        PUTBACK;
        FREETMPS;
        LEAVE;

        return retval;
    }
}

#define PERL6_MAGIC_KEY 0x0DD515FE
#define PERL6_HASH_MAGIC_KEY 0x0DD515FF

int p5_free_perl6_obj(pTHX_ SV* obj, MAGIC *mg)
{
    if (mg) {
        _perl6_magic* const p6mg = (_perl6_magic*) mg->mg_ptr;
        p6mg->free_p6_object(p6mg->index);
    }
    return 0;
}

int p5_free_perl6_hash(pTHX_ SV* obj, MAGIC *mg)
{
    if (mg) {
        _perl6_hash_magic* const p6mg = (_perl6_hash_magic*) mg->mg_ptr;
        p6mg->free_p6_object(p6mg->index);
    }
    return 0;
}

MGVTBL p5_inline_mg_vtbl = {
    0x0,
    0x0,
    0x0,
    0x0,
    &p5_free_perl6_obj,
    0x0,
    0x0,
    0x0
};

MGVTBL p5_inline_hash_mg_vtbl = {
    0x0,
    0x0,
    0x0,
    0x0,
    &p5_free_perl6_hash,
    0x0,
    0x0,
    0x0
};

void p5_rebless_object(PerlInterpreter *my_perl, SV *obj, char *package, IV i, SV *(*call_p6_method)(IV, char * , I32, SV *, SV **), void (*free_p6_object)(IV)) {
    SV * const inst = SvRV(obj);
    HV *stash = gv_stashpv(package, GV_ADD);
    if (stash == NULL)
        croak("Perl6::Object not found!? Forgot to call init_callbacks?");
    (void)sv_bless(obj, stash);

    _perl6_magic priv;

    /* set up magic */
    priv.key = PERL6_MAGIC_KEY;
    priv.index = i;
    priv.call_p6_method = call_p6_method;
    priv.free_p6_object = free_p6_object;
    sv_magicext(inst, inst, PERL_MAGIC_ext, &p5_inline_mg_vtbl, (char *) &priv, sizeof(priv));

}

SV *p5_wrap_p6_object(PerlInterpreter *my_perl, IV i, SV *p5obj, SV *(*call_p6_method)(IV, char * , I32, SV *, SV **), void (*free_p6_object)(IV)) {
    SV * inst;
    SV * inst_ptr;
    if (p5obj == NULL) {
        inst_ptr = newSViv(0); // will be upgraded to an RV
        inst = newSVrv(inst_ptr, "Perl6::Object");
    }
    else {
        inst_ptr = p5obj;
        inst = SvRV(inst_ptr);
        SvREFCNT_inc(inst_ptr);
    }
    _perl6_magic priv;

    /* set up magic */
    priv.key = PERL6_MAGIC_KEY;
    priv.index = i;
    priv.call_p6_method = call_p6_method;
    priv.free_p6_object = free_p6_object;
    sv_magicext(inst, inst, PERL_MAGIC_ext, &p5_inline_mg_vtbl, (char *) &priv, sizeof(priv));

    return inst_ptr;
}

SV *p5_wrap_p6_callable(PerlInterpreter *my_perl, IV i, SV *p5obj, SV *(*call)(IV, SV *, SV **), void (*free_p6_object)(IV)) {
    SV * inst;
    SV * inst_ptr;

    PERL_SET_CONTEXT(my_perl);

    if (p5obj == NULL) {
        dSP;
        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        call_pv("Perl6::Callable::new", G_SCALAR);
        SPAGAIN;

        inst_ptr = POPs;
        inst = SvRV(inst_ptr);
        SvREFCNT_inc(inst_ptr);

        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    else {
        inst_ptr = p5obj;
        inst = SvRV(inst_ptr);
        SvREFCNT_inc(inst_ptr);
    }
    _perl6_magic priv;

    /* set up magic */
    priv.key = PERL6_MAGIC_KEY;
    priv.index = i;
    priv.call_p6_callable = call;
    priv.free_p6_object = free_p6_object;
    sv_magic(inst, inst, PERL_MAGIC_ext, (char *) &priv, sizeof(priv));
    MAGIC * const mg = mg_find(inst, PERL_MAGIC_ext);
    mg->mg_virtual = &p5_inline_mg_vtbl;

    return inst_ptr;
}

SV *p5_wrap_p6_hash(
    PerlInterpreter *my_perl,
    IV i,
    SV *(*call_p6_method)(IV, char * , I32, SV *, SV **),
    SV *(*hash_at_key)(IV, char *),
    SV *(*hash_assign_key)(IV, char *, SV *),
    void (*free_p6_object)(IV)
) {
    PERL_SET_CONTEXT(my_perl);
    {
        int flags = G_SCALAR;
        dSP;

        SV * inst;
        SV * inst_ptr;
        inst_ptr = newSViv(0); // will be upgraded to an RV
        inst = newSVrv(inst_ptr, "Perl6::Object");
        _perl6_hash_magic priv;

        /* set up magic */
        priv.key = PERL6_HASH_MAGIC_KEY;
        priv.index = i;
        priv.call_p6_method  = call_p6_method;
        priv.hash_at_key     = hash_at_key;
        priv.hash_assign_key = hash_assign_key;
        priv.free_p6_object  = free_p6_object;
        sv_magicext(inst, inst, PERL_MAGIC_ext, &p5_inline_hash_mg_vtbl, (char *) &priv, sizeof(priv));

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);

        XPUSHs(newSVpv("Perl6::Hash", 0));
        XPUSHs(inst_ptr);

        PUTBACK;

        call_method("new", flags);
        SPAGAIN;

        SV *tied_handle = POPs;
        SvREFCNT_inc(tied_handle);

        PUTBACK;
        FREETMPS;
        LEAVE;

        return tied_handle;
    }
}

SV *p5_wrap_p6_handle(PerlInterpreter *my_perl, IV i, SV *p5obj, SV *(*call_p6_method)(IV, char * , I32, SV *, SV **), void (*free_p6_object)(IV)) {
    PERL_SET_CONTEXT(my_perl);
    {
        SV *handle = p5_wrap_p6_object(my_perl, i, p5obj, call_p6_method, free_p6_object);
        int flags = G_SCALAR;
        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);

        XPUSHs(newSVpv("Perl6::Handle", 0));
        XPUSHs(handle);

        PUTBACK;

        call_method("new", flags);
        SPAGAIN;

        SV *tied_handle = POPs;
        SvREFCNT_inc(tied_handle);

        PUTBACK;
        FREETMPS;
        LEAVE;

        return tied_handle;
    }
}

int p5_is_wrapped_p6_object(PerlInterpreter *my_perl, SV *obj) {
    SV * const obj_deref = SvRV(obj);
    /* check for magic! */
    MAGIC * const mg = mg_find(obj_deref, '~');
    return (mg && ((_perl6_magic*)(mg->mg_ptr))->key == PERL6_MAGIC_KEY);
}

IV p5_unwrap_p6_object(PerlInterpreter *my_perl, SV *obj) {
    SV * const obj_deref = SvRV(obj);
    MAGIC * const mg = mg_find(obj_deref, '~');
    return ((_perl6_magic*)(mg->mg_ptr))->index;
}

XS(p5_call_p6_method) {
    dXSARGS;
    SV * name = ST(0);
    SV * obj = ST(1);

    AV * args = newAV();
    av_extend(args, items - 2);
    int i;
    for (i = 0; i < items - 2; i++) {
        SV * const next = SvREFCNT_inc(ST(i + 2));
        if (av_store(args, i, next) == NULL)
            SvREFCNT_dec(next); /* see perlguts Working with AVs */
    }

    STRLEN len;
    char * const name_pv  = SvPV(name, len);

    if (!SvROK(obj)) {
        croak("Got a non-reference for obj?!");
    }
    SV * const obj_deref = SvRV(obj);
    MAGIC * const mg = mg_find(obj_deref, '~');
    _perl6_magic* const p6mg = (_perl6_magic*)(mg->mg_ptr);
    SV *err = NULL;
    SV * const args_rv = newRV_noinc((SV *) args);
    SV * retval = p6mg->call_p6_method(p6mg->index, name_pv, GIMME_V == G_SCALAR, args_rv, &err);
    SPAGAIN; /* refresh local stack pointer, could have been modified by Perl 5 code called from Perl 6 */
    SvREFCNT_dec(args_rv);
    if (err) {
        sv_2mortal(err);
        croak_sv(err);
    }
    sv_2mortal(retval);
    sp -= items;

    if (GIMME_V == G_VOID) {
        XSRETURN_EMPTY;
    }
    if (GIMME_V == G_ARRAY) {
        AV* const av = (AV*)SvRV(retval);
        I32 const len = av_len(av) + 1;
        I32 i;
        for (i = 0; i < len; i++) {
            XPUSHs(sv_2mortal(av_shift(av)));
        }
        XSRETURN(len);
    }
    else {
        AV* const av = (AV*)SvRV(retval);
        XPUSHs(sv_2mortal(av_shift(av)));
        XSRETURN(1);
    }
}

XS(p5_hash_at_key) {
    dXSARGS;
    SV * self = ST(0);
    SV * key  = ST(1);

    SV * const p6hashobj = *(av_fetch((AV *) SvRV(self), 0, 0));
    MAGIC * const mg = mg_find(SvRV(p6hashobj), '~');
    _perl6_hash_magic* const p6mg = (_perl6_hash_magic*)(mg->mg_ptr);

    STRLEN len;
    char * const key_pv  = SvPV(key, len);

    SV * retval = p6mg->hash_at_key(p6mg->index, key_pv);

    sv_2mortal(retval);
    sp -= items;

    XPUSHs(retval);
    XSRETURN(1);
}

XS(p5_hash_assign_key) {
    dXSARGS;
    SV * self = ST(0);
    SV * key  = ST(1);
    SV * val  = ST(2);

    SV * const p6hashobj = *(av_fetch((AV *) SvRV(self), 0, 0));
    MAGIC * const mg = mg_find(SvRV(p6hashobj), '~');
    _perl6_hash_magic* const p6mg = (_perl6_hash_magic*)(mg->mg_ptr);

    STRLEN len;
    char * const key_pv  = SvPV(key, len);

    p6mg->hash_assign_key(p6mg->index, key_pv, val);

    sp -= items;

    XSRETURN_EMPTY;
}

XS(p5_call_p6_callable) {
    dXSARGS;
    SV * obj = ST(0);

    AV * args = newAV();
    av_extend(args, items - 1);
    int i;
    for (i = 0; i < items - 1; i++) {
        SV * const next = SvREFCNT_inc(ST(i + 1));
        if (av_store(args, i, next) == NULL)
            SvREFCNT_dec(next); /* see perlguts Working with AVs */
    }

    if (!SvROK(obj))
        croak("Tried to call a Perl 6 method on a non-object!?");
    SV * const obj_deref = SvRV(obj);
    MAGIC * const mg = mg_find(obj_deref, '~');
    _perl6_magic* const p6mg = (_perl6_magic*)(mg->mg_ptr);
    SV *err = NULL;
    SV * const args_rv = newRV_noinc((SV *) args);
    SV * retval = p6mg->call_p6_callable(p6mg->index, args_rv, &err);
    SPAGAIN; /* refresh local stack pointer, could have been modified by Perl 5 code called from Perl 6 */
    SvREFCNT_dec(args_rv);
    if (err) {
        sv_2mortal(err);
        croak_sv(err);
    }
    sv_2mortal(retval);
    sp -= items;

    if (GIMME_V == G_VOID) {
        XSRETURN_EMPTY;
    }
    if (GIMME_V == G_ARRAY) {
        AV* const av = (AV*)SvRV(retval);
        I32 const len = av_len(av) + 1;
        I32 i;
        for (i = 0; i < len; i++) {
            XPUSHs(sv_2mortal(av_shift(av)));
        }
        XSRETURN(len);
    }
    else {
        AV* const av = (AV*)SvRV(retval);
        XPUSHs(sv_2mortal(av_shift(av)));
        XSRETURN(1);
    }
}

XS(p5_load_module) {
    dXSARGS;
    SV * module  = ST(0);
    SV * version = NULL;
    SvREFCNT_inc(module);  /* decremented by load_module */
    if (items == 2) {
        version = ST(1);
        SvREFCNT_inc(version); /* decremented by load_module */
    }
    load_module(PERL_LOADMOD_NOIMPORT, module, version);
    SPAGAIN;
    sp -= items;
    XSRETURN_EMPTY;
}

static MGVTBL subname_vtbl;

XS(p5_set_subname) {
    dXSARGS;
    SV *package = ST(0);
    SV *name    = ST(1);
    SV *sub     = ST(2);
    CV *code    = (CV *) SvRV(sub);
    HV *stash   = GvHV(gv_fetchsv(package, TRUE, SVt_PVHV));
    GV *gv = (GV *) newSV(0);
    MAGIC *mg;

    gv_init_sv(gv, stash, name, GV_ADDMULTI);

    /*
     * p5_set_subname needs to create a GV to store the name. The CvGV field of
     * a CV is not refcounted, so perl wouldn't know to SvREFCNT_dec() this GV
     * if it destroys the containing CV. We use a MAGIC with an empty vtable
     * simply for the side-effect of using MGf_REFCOUNTED to store the
     * actually-counted reference to the GV.
     */
    Newxz(mg, 1, MAGIC);
    mg->mg_moremagic = SvMAGIC(code);
    mg->mg_type = PERL_MAGIC_ext;
    mg->mg_virtual = &subname_vtbl;
    SvMAGIC_set(code, mg);
    mg->mg_flags |= MGf_REFCOUNTED;
    mg->mg_obj = (SV *) gv;
    SvRMAGICAL_on(code);
    CvANON_off(code);
#ifndef CvGV_set
    CvGV(code) = gv;
#else
    CvGV_set(code, gv);
#endif
    sp -= items;
    PUSHs(sub);
    XSRETURN(1);
}
