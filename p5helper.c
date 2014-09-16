#include <EXTERN.h>
#include <XSUB.h>
#include <perl.h>

static void xs_init (pTHX);
EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);
EXTERN_C void boot_Socket (pTHX_ CV* cv);

XS(p5_call_p6_method);
XS(p5_call_p6_callable);

EXTERN_C void xs_init(pTHX) {
    char *file = __FILE__;
    /* DynaLoader is a special case */
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
    newXS("Perl6::Object::call_method", p5_call_p6_method, file);
    newXS("Perl6::Callable::call", p5_call_p6_callable, file);
}

static int inited = 0;

PerlInterpreter *p5_init_perl() {
    char *embedding[] = { "", "-e", "0" };
    if (!inited++)
        PERL_SYS_INIT3(0, NULL, NULL);
    PerlInterpreter *my_perl = perl_alloc();
    PERL_SET_CONTEXT(my_perl);
    PL_perl_destruct_level = 1;
    perl_construct( my_perl );
    perl_parse(my_perl, xs_init, 3, embedding, NULL);
    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
    perl_run(my_perl);
    return my_perl;
}

void p5_destruct_perl(PerlInterpreter *my_perl) {
    PL_perl_destruct_level = 1;
    perl_destruct(my_perl);
    perl_free(my_perl);
}

void p5_terminate() {
    if (inited)
        PERL_SYS_TERM();
}

int p5_SvIOK(PerlInterpreter *my_perl, SV* sv) {
    return SvIOK(sv);
}

int p5_SvPOK(PerlInterpreter *my_perl, SV* sv) {
    return SvPOK(sv);
}

int p5_sv_iv(PerlInterpreter *my_perl, SV* sv) {
    return SvIV(sv);
}

int p5_is_object(PerlInterpreter *my_perl, SV* sv) {
    return sv_isobject(sv);
}

int p5_is_array(PerlInterpreter *my_perl, SV* sv) {
    return (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV);
}

int p5_is_hash(PerlInterpreter *my_perl, SV* sv) {
    return (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV);
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

void p5_sv_refcnt_dec(PerlInterpreter *my_perl, SV *sv) {
    SvREFCNT_dec(sv);
}

void p5_sv_refcnt_inc(PerlInterpreter *my_perl, SV *sv) {
    SvREFCNT_inc(sv);
}

SV *p5_int_to_sv(PerlInterpreter *my_perl, int value) {
    return newSViv(value);
}

SV *p5_str_to_sv(PerlInterpreter *my_perl, char* value) {
    return newSVpv(value, 0);
}

int p5_av_top_index(PerlInterpreter *my_perl, AV *av) {
    return av_top_index(av);
}

SV *p5_av_fetch(PerlInterpreter *my_perl, AV *av, int key) {
    return *av_fetch(av, key, 0);
}

void p5_av_push(PerlInterpreter *my_perl, AV *av, SV *sv) {
    av_push(av, sv);
}

int p5_hv_iterinit(PerlInterpreter *my_perl, HV *hv) {
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

void p5_hv_store(PerlInterpreter *my_perl, HV *hv, const char *key, SV *val) {
    hv_store(hv, key, strlen(key), val, 0);
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

SV *p5_eval_pv(PerlInterpreter *my_perl, const char* p, I32 croak_on_error) {
    PERL_SET_CONTEXT(my_perl);
    return eval_pv(p, croak_on_error);
}

SV *p5_err_sv(PerlInterpreter *my_perl) {
    return ERRSV;
}

AV *p5_call_package_method(PerlInterpreter *my_perl, char *package, char *name, int len, SV *args[]) {
    dSP;
    int i;
    int count;
    AV * const retval = newAV();
    int flags = G_ARRAY | G_EVAL;

    PERL_SET_CONTEXT(my_perl);

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

AV *p5_call_method(PerlInterpreter *my_perl, char *package, SV *obj, char *name, int len, SV *args[]) {
    dSP;
    int i;
    int count;
    AV * const retval = newAV();
    int flags = G_ARRAY | G_EVAL;

    PERL_SET_CONTEXT(my_perl);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    for (i = 0; i < len; i++) {
        XPUSHs(sv_2mortal(args[i]));
    }

    PUTBACK;

    HV * const pkg = package != NULL ? gv_stashpv(package, 0) : SvSTASH((SV*)SvRV(obj));
    GV * const gv = Perl_gv_fetchmethod_autoload(aTHX_ pkg, name, FALSE);
    if (gv && isGV(gv)) {
        SV * const rv = sv_2mortal(newRV((SV*)GvCV(gv)));

        count = call_sv(rv, flags);
        SPAGAIN;

        av_extend(retval, count - 1);
        for (i = count - 1; i >= 0; i--) {
            SV * const next = POPs;
            SvREFCNT_inc(next);

            if (av_store(retval, i, next) == NULL)
                SvREFCNT_dec(next); /* see perlguts Working with AVs */
        }
    }
    else {
        croak("Could not find method \"%s\" of \"%s\" object", name, HvNAME(pkg));
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return retval;
}

AV *p5_call_function(PerlInterpreter *my_perl, char *name, int len, SV *args[]) {
    dSP;
    int i;
    int count;
    AV * const retval = newAV();
    int flags = G_ARRAY | G_EVAL;

    PERL_SET_CONTEXT(my_perl);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    for (i = 0; i < len; i++) {
        XPUSHs(sv_2mortal(args[i]));
    }

    PUTBACK;

    count = call_pv(name, flags);
    SPAGAIN;

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

void p5_rebless_object(PerlInterpreter *my_perl, SV *obj) {
    SV * const inst = SvRV(obj);
    SV * const inst_ptr = newRV_noinc(inst);
    HV *stash = gv_stashpv("Perl6::Object", 0);
    if (stash == NULL)
        croak("Perl6::Object not found!? Forgot to call init_callbacks?");
    (void)sv_bless(inst_ptr, stash);
}

typedef struct {
    I32 key; /* to make sure it came from Inline */
    IV index;
    union {
        SV *(*call_p6_method)(int, char *, SV *, SV **);
        SV *(*call_p6_callable)(int, SV *, SV **);
    };
    void (*free_p6_object)(int);
} _perl6_magic;

#define PERL6_MAGIC_KEY 0x0DD515FE

int p5_free_perl6_obj(pTHX_ SV* obj, MAGIC *mg)
{
    if (mg) {
        _perl6_magic* const p6mg = (_perl6_magic*) mg->mg_ptr;
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

SV *p5_wrap_p6_object(PerlInterpreter *my_perl, IV i, SV *p5obj, SV *(*call_p6_method)(int, char * , SV *, SV **), void (*free_p6_object)(int)) {
    SV * inst;
    SV * inst_ptr;
    if (p5obj == NULL) {
        inst_ptr = newSViv(0);
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
    sv_magic(inst, inst, PERL_MAGIC_ext, (char *) &priv, sizeof(priv));
    MAGIC * const mg = mg_find(inst, PERL_MAGIC_ext);
    mg->mg_virtual = &p5_inline_mg_vtbl;

    return inst_ptr;
}

SV *p5_wrap_p6_callable(PerlInterpreter *my_perl, IV i, SV *p5obj, SV *(*call)(int, SV *, SV **), void (*free_p6_object)(int)) {
    SV * inst;
    SV * inst_ptr;
    if (p5obj == NULL) {
        inst_ptr = newSViv(0);
        inst = newSVrv(inst_ptr, "Perl6::Callable");
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

int p5_is_wrapped_p6_object(PerlInterpreter *my_perl, SV *obj) {
    SV * const obj_deref = SvRV(obj);
    /* check for magic! */
    MAGIC * const mg = mg_find(obj_deref, '~');
    return (mg && ((_perl6_magic*)(mg->mg_ptr))->key == PERL6_MAGIC_KEY);
}

int p5_unwrap_p6_object(PerlInterpreter *my_perl, SV *obj) {
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
    char * const name_str = savepvn(name_pv, len);

    SV * const obj_deref = SvRV(obj);
    MAGIC * const mg = mg_find(obj_deref, '~');
    _perl6_magic* const p6mg = (_perl6_magic*)(mg->mg_ptr);
    SV *err = NULL;
    SV * retval = p6mg->call_p6_method(p6mg->index, name_str, newRV_noinc((SV *) args), &err);
    SPAGAIN; /* refresh local stack pointer, could have been modified by Perl 5 code called from Perl 6 */
    SvREFCNT_dec(args);
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
        int const len = av_len(av) + 1;
        int i;
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

    SV * const obj_deref = SvRV(obj);
    MAGIC * const mg = mg_find(obj_deref, '~');
    _perl6_magic* const p6mg = (_perl6_magic*)(mg->mg_ptr);
    SV *err = NULL;
    SV * retval = p6mg->call_p6_callable(p6mg->index, newRV_noinc((SV *) args), &err);
    SPAGAIN; /* refresh local stack pointer, could have been modified by Perl 5 code called from Perl 6 */
    SvREFCNT_dec(args);
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
        int const len = av_len(av) + 1;
        int i;
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
