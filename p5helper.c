#include <EXTERN.h>
#include <XSUB.h>
#include <perl.h>

static PerlInterpreter *my_perl;

static void xs_init (pTHX);
EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);
EXTERN_C void boot_Socket (pTHX_ CV* cv);

XS(p5_call_p6_method);

EXTERN_C void xs_init(pTHX) {
    char *file = __FILE__;
    /* DynaLoader is a special case */
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
    newXS("Perl6::Object::call_method", p5_call_p6_method, file);
}

PerlInterpreter *p5_init_perl() {
    char *embedding[] = { "", "-e", "0" };
    PERL_SYS_INIT3(0, NULL, NULL);
    my_perl = perl_alloc();
    perl_construct( my_perl );
    perl_parse(my_perl, xs_init, 3, embedding, NULL);
    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
    perl_run(my_perl);
    return my_perl;
}

void p5_destruct_perl(PerlInterpreter *my_perl) {
    perl_destruct(my_perl);
    perl_free(my_perl);
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
    return eval_pv(p, croak_on_error);
}

AV *p5_call_function(PerlInterpreter *my_perl, char *name, int len, SV *args[]) {
    dSP;
    int i;
    int count;
    AV * const retval = newAV();
    int flags = G_ARRAY;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    for (i = 0; i < len; i++) {
        XPUSHs(sv_2mortal(args[i]));
    }

    PUTBACK;

    count = perl_call_method(name, flags);
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

typedef struct {
    I32 key; /* to make sure it came from Inline */
    void *(*unwrap)();
    SV *(*call_p6_method)(char * , SV *);
} _perl6_magic;

#define PERL6_MAGIC_KEY 0x0DD515FE

SV *p5_wrap_p6_object(PerlInterpreter *my_perl, void *(*unwrap)(), SV *(*call_p6_method)(char * , SV *)) {
    SV * const inst_ptr = newSViv(0);
    SV * const inst = newSVrv(inst_ptr, "Perl6::Object");;
    _perl6_magic priv;

    /* set up magic */
    priv.key = PERL6_MAGIC_KEY;
    priv.unwrap = unwrap;
    priv.call_p6_method = call_p6_method;
    sv_magic(inst, inst, PERL_MAGIC_ext, (char *) &priv, sizeof(priv));
    MAGIC * const mg = mg_find(inst, PERL_MAGIC_ext);

    return SvREFCNT_inc(inst_ptr);
}

int p5_is_wrapped_p6_object(PerlInterpreter *my_perl, SV *obj) {
    SV * const obj_deref = SvRV(obj);
    /* check for magic! */
    MAGIC * const mg = mg_find(obj_deref, '~');
    return (mg && ((_perl6_magic*)(mg->mg_ptr))->key == PERL6_MAGIC_KEY);
}

void p5_unwrap_p6_object(PerlInterpreter *my_perl, SV *obj) {
    SV * const obj_deref = SvRV(obj);
    /* check for magic! */
    MAGIC * const mg = mg_find(obj_deref, '~');
    ((_perl6_magic*)(mg->mg_ptr))->unwrap();
}

XS(p5_call_p6_method) {
    dXSARGS;
    SV * name = ST(0);
    SvREFCNT_inc(name);
    SV * obj = ST(1);
    SvREFCNT_inc(obj);

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
    SV * retval = ((_perl6_magic*)(mg->mg_ptr))->call_p6_method(name_str, newRV((SV *) args)); //FIXME: should be newRV_noinc! args already has refcnt of 1
    SPAGAIN; /* refresh local stack pointer, could have been modified by Perl 5 code called from Perl 6 */
    sp -= items;

    if (GIMME_V == G_VOID) {
        SvREFCNT_dec(retval);
        XSRETURN_EMPTY;
    }
    if (GIMME_V == G_ARRAY) {
        AV* const av = (AV*)SvRV(retval);
        int const len = av_len(av) + 1;
        int i;
        for (i = 0; i < len; i++) {
            XPUSHs(SvREFCNT_inc(av_shift(av)));
        }
        XSRETURN(len);
    }
    else {
        AV* const av = (AV*)SvRV(retval);
        XPUSHs(SvREFCNT_inc(av_shift(av)));
        XSRETURN(1);
    }
}
