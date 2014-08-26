#include <EXTERN.h>
#include <perl.h>

static PerlInterpreter *my_perl;

static void xs_init (pTHX);
EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);
EXTERN_C void boot_Socket (pTHX_ CV* cv);

EXTERN_C void xs_init(pTHX) {
    char *file = __FILE__;
    /* DynaLoader is a special case */
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
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
    char *ptr;
    ptr = SvPV(sv, len);
    return ptr;
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

SV *p5_undef(PerlInterpreter *my_perl) {
    return &PL_sv_undef;
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
        XPUSHs(args[i]);
        if (! sv_isobject(args[i]))
            sv_2mortal(args[i]);
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
