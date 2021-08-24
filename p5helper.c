#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#define declare_cbs perl6_callbacks *cbs = (perl6_callbacks*)SvIV(*hv_fetchs(PL_modglobal, "Inline::Perl5 callbacks", 0));

static void xs_init (pTHX);
EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);
EXTERN_C void boot_Socket (pTHX_ CV* cv);
int p5_is_live_wrapped_p6_object(PerlInterpreter *my_perl, SV *obj);

typedef struct {
    I32 key; /* to make sure it came from Inline */
    IV index;
    I32 is_wrapper;
} _perl6_magic;

typedef struct {
    I32 key; /* to make sure it came from Inline */
    IV index;
} _perl6_hash_magic;

typedef struct {
    SV *(*call_p6_method)(IV, char *, I32, SV *, SV **);
    SV *(*call_p6_package_method)(char *, char *, I32, SV *, SV **);
    SV *(*call_p6_callable)(IV, SV *, SV **);
    void (*free_p6_object)(IV);
    SV *(*hash_at_key)(IV, char *);
    SV *(*hash_assign_key)(IV, char *, SV *);
    SV *(*compile_to_end)(char *, char *, U32 *pos);
} perl6_callbacks;

#ifndef wrap_keyword_plugin
void Perl_wrap_keyword_plugin(pTHX_ Perl_keyword_plugin_t new_plugin, Perl_keyword_plugin_t *old_plugin_p)
{
    dVAR;

    PERL_UNUSED_CONTEXT;
    if (*old_plugin_p) return;
    if (!*old_plugin_p) {
        *old_plugin_p = PL_keyword_plugin;
        PL_keyword_plugin = new_plugin;
    }
}
#define wrap_keyword_plugin(new_plugin, old_plugin_p) Perl_wrap_keyword_plugin(aTHX_ new_plugin, old_plugin_p)
#endif

XS(p5_call_p6_method);
XS(p5_call_p6_extension_method);
XS(p5_destroy_p5_object);
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
    newXS("Perl6::Object::call_extension_method", p5_call_p6_extension_method, file);
    newXS("Perl6::Object::destroy", p5_destroy_p5_object, file);
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

static int inited = 0;

static Perl_keyword_plugin_t next_keyword_plugin;
static int raku_keyword_plugin(pTHX_ char *keyword_ptr, STRLEN keyword_len, OP **op_ptr) {
    if (memEQs(keyword_ptr, keyword_len, "raku")) {
        // read the whole source file
        while (lex_next_chunk(0));

        // move into the raku block
        lex_read_space(0);
        lex_read_to(PL_parser->bufptr + 1);

        declare_cbs;
        U32 pos;
        char *bufptr = PL_parser->bufptr;
        STRLEN len;
        char *package_name = SvPV(PL_curstname, len);
        SV *code = cbs->compile_to_end(package_name, PL_parser->bufptr, &pos);
        lex_read_to(bufptr + pos + 1);

        *op_ptr = code ? newUNOP(OP_ENTERSUB, 0, newSVOP(OP_CONST, 0, code)) : NULL;

        return KEYWORD_PLUGIN_STMT;
    }
    else {
        return next_keyword_plugin(aTHX_ keyword_ptr, keyword_len, op_ptr);
    }
}

void p5_inline_perl6_xs_init(PerlInterpreter *my_perl) {
    char *file = __FILE__;
    newXS("Perl6::Object::call_method", p5_call_p6_method, file);
    newXS("Perl6::Object::call_extension_method", p5_call_p6_extension_method, file);
    newXS("Perl6::Hash::FETCH", p5_hash_at_key, file);
    newXS("Perl6::Hash::STORE", p5_hash_assign_key, file);
    newXS("Perl6::Callable::call", p5_call_p6_callable, file);
    newXS("v6::load_module_impl", p5_load_module, file);
    newXS("v6::set_subname", p5_set_subname, file);
    inited = 1;
}

void p5_init_callbacks(
    SV  *(*call_p6_method)(IV, char * , I32, SV *, SV **),
    SV  *(*call_p6_package_method)(char *, char * , I32, SV *, SV **),
    SV  *(*call_p6_callable)(IV, SV *, SV **),
    void (*free_p6_object)(IV),
    SV  *(*hash_at_key)(IV, char *),
    SV  *(*hash_assign_key)(IV, char *, SV *),
    SV  *(*compile_to_end)(char *, char *, U32 *)
) {
    perl6_callbacks *cbs = malloc(sizeof(perl6_callbacks));
    cbs->call_p6_method   = call_p6_method;
    cbs->call_p6_package_method = call_p6_package_method;
    cbs->call_p6_callable = call_p6_callable;
    cbs->free_p6_object   = free_p6_object;
    cbs->hash_at_key      = hash_at_key;
    cbs->hash_assign_key  = hash_assign_key;
    cbs->compile_to_end   = compile_to_end;
    hv_stores(PL_modglobal, "Inline::Perl5 callbacks", newSViv((IV)cbs));
}

static int interpreters = 0;
static int terminate = 0;

PerlInterpreter *p5_init_perl(
    int argc,
    char **argv,
    SV  *(*call_p6_method)(IV, char * , I32, SV *, SV **),
    SV  *(*call_p6_package_method)(char *, char * , I32, SV *, SV **),
    SV  *(*call_p6_callable)(IV, SV *, SV **),
    void (*free_p6_object)(IV),
    SV  *(*hash_at_key)(IV, char *),
    SV  *(*hash_assign_key)(IV, char *, SV *),
    SV  *(*compile_to_end)(char *, char *, U32 *)
) {
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

    p5_init_callbacks(
        call_p6_method,
        call_p6_package_method,
        call_p6_callable,
        free_p6_object,
        hash_at_key,
        hash_assign_key,
        compile_to_end
    );

    wrap_keyword_plugin(raku_keyword_plugin, &next_keyword_plugin);

    return my_perl;
}

void p5_destruct_perl(PerlInterpreter *my_perl) {
    PERL_SET_CONTEXT(my_perl);

    SV **cbs_entry = hv_fetchs(PL_modglobal, "Inline::Perl5 callbacks", 0);
    perl6_callbacks *cbs = NULL;
    if (cbs_entry) {
        cbs = (perl6_callbacks*)SvIV(*cbs_entry);
    }

    PL_perl_destruct_level = 1;

    POPSTACK_TO(PL_mainstack);
    dounwind(-1);
    LEAVE_SCOPE(0);

    perl_destruct(my_perl);
    perl_free(my_perl);

    if (cbs)
        free(cbs);

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
    PERL_SET_CONTEXT(my_perl);
    if (SvUTF8(sv)) { // UTF-8 flag set -> can use string as-is
        return 1;
    }
    else { // pure 7 bit ASCII is valid UTF-8 as well
        STRLEN len;
        char * const pv  = SvPV(sv, len);
        STRLEN i;
        for (i = 0; i < len; i++)
            if ((signed char) pv[i] < 0) // signed char!
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
    PERL_SET_CONTEXT(my_perl);
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
    PERL_SET_CONTEXT(my_perl);
    return (
        (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV)
        ? ((mg = mg_find(SvRV(sv), PERL_MAGIC_tied)) && sv_isa(mg->mg_obj, "Perl6::Hash"))
            ? 2
            : 1
        : 0
    );
}

IV p5_unwrap_p6_hash(PerlInterpreter *my_perl, SV *obj) {
    PERL_SET_CONTEXT(my_perl);
    {
        MAGIC * const tie_mg = mg_find(SvRV(obj), PERL_MAGIC_tied);
        SV * const hash = tie_mg->mg_obj;
        SV * const p6hashobj = *(av_fetch((AV *) SvRV(hash), 0, 0));
        MAGIC * const mg = mg_find(SvRV(p6hashobj), '~');
        return ((_perl6_hash_magic*)(mg->mg_ptr))->index;
    }
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

AV *p5_sv_to_av_inc(PerlInterpreter *my_perl, SV* sv) {
    AV * const retval = (AV *) SvRV(sv);
    SvREFCNT_inc((SV *)retval);
    return retval;
}

HV *p5_sv_to_hv(PerlInterpreter *my_perl, SV* sv) {
    return (HV *) SvRV(sv);
}

char *p5_sv_to_char_star(PerlInterpreter *my_perl, SV *sv) {
    PERL_SET_CONTEXT(my_perl);
    {
        STRLEN len;
        char * const pv  = SvPV(sv, len);
        return pv;
    }
}

STRLEN p5_sv_to_buf(PerlInterpreter *my_perl, SV *sv, char **buf) {
    PERL_SET_CONTEXT(my_perl);
    {
        STRLEN len;
        *buf  = SvPV(sv, len);
        return len;
    }
}

SV *p5_sv_to_ref(PerlInterpreter *my_perl, SV *sv) {
    PERL_SET_CONTEXT(my_perl);
    return newRV_noinc(sv);
}

int p5_sv_refcnt(PerlInterpreter *my_perl, SV *sv) {
    PERL_SET_CONTEXT(my_perl);
    return SvREFCNT(sv);
}

void p5_sv_refcnt_dec(PerlInterpreter *my_perl, SV *sv) {
    PERL_SET_CONTEXT(my_perl);
    SvREFCNT_dec(sv);
}

void p5_sv_refcnt_inc(PerlInterpreter *my_perl, SV *sv) {
    SvREFCNT_inc(sv);
}

void p5_sv_destroy(PerlInterpreter *my_perl, SV *sv) {
    PERL_SET_CONTEXT(my_perl);
    if (!PL_in_clean_objs && !PL_in_clean_all)
        SvREFCNT_dec(sv); // don't bother during global deconstruction
}

void p5_sv_2mortal(PerlInterpreter *my_perl, SV *sv) {
    sv_2mortal(sv);
}

SV *p5_new_mortal_reference(PerlInterpreter *my_perl, SV *sv) {
    return newRV_inc(SvRV(sv));
}

SV *p5_int_to_sv(PerlInterpreter *my_perl, IV value) {
    PERL_SET_CONTEXT(my_perl);
    return newSViv(value);
}

SV *p5_float_to_sv(PerlInterpreter *my_perl, MYNV value) {
    PERL_SET_CONTEXT(my_perl);
    return newSVnv((NV)value);
}

SV *p5_str_to_sv(PerlInterpreter *my_perl, STRLEN len, char* value) {
    PERL_SET_CONTEXT(my_perl);
    return newSVpvn_flags(value, len, SVf_UTF8);
}

SV *p5_buf_to_sv(PerlInterpreter *my_perl, STRLEN len, char* value) {
    PERL_SET_CONTEXT(my_perl);
    return newSVpvn_flags(value, len, 0);
}

I32 p5_av_top_index(PerlInterpreter *my_perl, AV *av) {
    PERL_SET_CONTEXT(my_perl);
    return av_top_index(av);
}

SV *p5_av_fetch(PerlInterpreter *my_perl, AV *av, I32 key) {
    PERL_SET_CONTEXT(my_perl);
    {
        SV ** const item = av_fetch(av, key, 0);
        if (item)
            return *item;
        return NULL;
    }
}

void p5_av_store(PerlInterpreter *my_perl, AV *av, I32 key, SV *val) {
    PERL_SET_CONTEXT(my_perl);
    SvREFCNT_inc(val);
    if (av_store(av, key, val) == NULL)
        SvREFCNT_dec(val);
    return;
}

SV *p5_av_pop(PerlInterpreter *my_perl, AV *av) {
    PERL_SET_CONTEXT(my_perl);
    return av_pop(av);
}

void p5_av_push(PerlInterpreter *my_perl, AV *av, SV *sv) {
    PERL_SET_CONTEXT(my_perl);
    av_push(av, sv);
}

SV *p5_av_shift(PerlInterpreter *my_perl, AV *av) {
    PERL_SET_CONTEXT(my_perl);
    return av_shift(av);
}

void p5_av_unshift(PerlInterpreter *my_perl, AV *av, SV *sv) {
    PERL_SET_CONTEXT(my_perl);
    av_unshift(av, 1);
    SvREFCNT_inc(sv);
    if (av_store(av, 0, sv) == NULL)
        SvREFCNT_dec(sv);
}

void p5_av_delete(PerlInterpreter *my_perl, AV *av, I32 key) {
    PERL_SET_CONTEXT(my_perl);
    av_delete(av, key, G_DISCARD);
}

void p5_av_clear(PerlInterpreter *my_perl, AV *av) {
    PERL_SET_CONTEXT(my_perl);
    av_clear(av);
}

I32 p5_hv_iterinit(PerlInterpreter *my_perl, HV *hv) {
    PERL_SET_CONTEXT(my_perl);
    return hv_iterinit(hv);
}

HE *p5_hv_iternext(PerlInterpreter *my_perl, HV *hv) {
    PERL_SET_CONTEXT(my_perl);
    return hv_iternext(hv);
}

SV *p5_hv_iterkeysv(PerlInterpreter *my_perl, HE *entry) {
    PERL_SET_CONTEXT(my_perl);
    return hv_iterkeysv(entry);
}

SV *p5_hv_iterval(PerlInterpreter *my_perl, HV *hv, HE *entry) {
    PERL_SET_CONTEXT(my_perl);
    return hv_iterval(hv, entry);
}

SV *p5_hv_fetch(PerlInterpreter *my_perl, HV *hv, STRLEN len, const char *key) {
    PERL_SET_CONTEXT(my_perl);
    {
        SV ** const item = hv_fetch(hv, key, len, 0);
        if (item)
            return *item;
        return NULL;
    }
}

void p5_hv_store(PerlInterpreter *my_perl, HV *hv, const char *key, SV *val) {
    PERL_SET_CONTEXT(my_perl);
    hv_store(hv, key, strlen(key), val, 0);
}

int p5_hv_exists(PerlInterpreter *my_perl, HV *hv, STRLEN len, const char *key) {
    PERL_SET_CONTEXT(my_perl);
    return hv_exists(hv, key, len);
}

SV *p5_undef(PerlInterpreter *my_perl) {
    PERL_SET_CONTEXT(my_perl);
    return &PL_sv_undef;
}

HV *p5_newHV(PerlInterpreter *my_perl) {
    PERL_SET_CONTEXT(my_perl);
    return newHV();
}

AV *p5_newAV(PerlInterpreter *my_perl) {
    PERL_SET_CONTEXT(my_perl);
    return newAV();
}

SV *p5_newRV_noinc(PerlInterpreter *my_perl, SV *sv) {
    PERL_SET_CONTEXT(my_perl);
    return newRV_noinc(sv);
}

SV *p5_newRV_inc(PerlInterpreter *my_perl, SV *sv) {
    PERL_SET_CONTEXT(my_perl);
    return newRV_inc(sv);
}

const char *p5_sv_reftype(PerlInterpreter *my_perl, SV *sv) {
    PERL_SET_CONTEXT(my_perl);
    return sv_reftype(SvRV(sv), 1);
}

SV *p5_new_blessed_hashref(PerlInterpreter *my_perl, char *package) {
    PERL_SET_CONTEXT(my_perl);
    HV * obj = newHV();
    SV * const inst = newRV_noinc((SV*)obj);
    HV *stash = gv_stashpv(package, GV_ADD);
    (void)sv_bless(inst, stash);
    return inst;
}

I32 p5_get_type(PerlInterpreter *my_perl, SV *sv) {
    int is_hash;
    PERL_SET_CONTEXT(my_perl);
    if (p5_is_object(my_perl, sv)) {
        return 1;
    }
    else if (p5_is_sub_ref(my_perl, sv)) {
        return 2;
    }
    else if (p5_SvNOK(my_perl, sv)) {
        return 3;
    }
    else if (p5_SvIOK(my_perl, sv)) {
        return 4;
    }
    else if (p5_SvPOK(my_perl, sv)) {
        return 5;
    }
    else if (p5_is_array(my_perl, sv)) {
        return 6;
    }
    else if ((is_hash = p5_is_hash(my_perl, sv)) > 0) {
        return 6 + is_hash;
    }
    else if (p5_is_undef(my_perl, sv)) {
        return 9;
    }
    else if (p5_is_scalar_ref(my_perl, sv)) {
        return 10;
    }
    else if (SvTYPE(sv) == SVt_PVGV) {
        return 11;
    }
    else {
        return 0;
    }
}

SV *p5_get_global(PerlInterpreter *my_perl, const char* name) {
    PERL_SET_CONTEXT(my_perl);
    if (strlen(name) < 2)
        return NULL;

    if (name[0] == '$')
        return get_sv(&name[1], 0);

    if (name[0] == '@') {
        AV *av = get_av(&name[1], 0);
        return av ? sv_2mortal(newRV_inc((SV *)av)) : NULL;
    }

    if (name[0] == '%') {
        HV *hv = get_hv(&name[1], 0);
        return hv ? sv_2mortal(newRV_inc((SV *)hv)) : NULL;
    }

    return NULL;
}

void p5_set_global(PerlInterpreter *my_perl, const char* name, SV *value) {
    PERL_SET_CONTEXT(my_perl);
    if (strlen(name) < 2)
        return;

    if (name[0] == '$')
        SvSetSV(get_sv(&name[1], 0), value);

    else if (name[0] == '@')
        croak("Setting global array variable NYI");

    else if (name[0] == '%')
        croak("Setting global hash variable NYI");
}

I32 p5_compile_sv(PerlInterpreter *my_perl, SV *line, CV **cv, SV **stash) {
    PERL_SET_CONTEXT(my_perl);
    char *start = NULL;
    char start_orig;
    I32 floor;
    OP *op;

    ENTER;

    floor = start_subparse(FALSE, 0);

    if (PL_parser) {
        start = strstr(PL_parser->bufptr, SvPVX(line) + 1);
        start_orig = start[-1];
        start[-1] = '{';
        lex_read_to(start - 1);
    }
    else {
        lex_start(line, NULL, 0);
    }

    HV *new_stash = newHV();
    HV *cur_stash = PL_curstash;
    PL_curstash = new_stash;

    op = parse_block(0);

    PL_curstash = cur_stash;
    HE *he;
    while ((he = hv_iternext(new_stash))) {
        SV *key = hv_iterkeysv(he);
        SV *val = hv_iterval(new_stash, he);

        /* Put the entry into the actual target stash */
        hv_store_ent(PL_curstash, key, SvREFCNT_inc(val), HeHASH(he));

        if (   0 == strcmp(SvPV_nolen(key), "BEGIN")
            || 0 == strcmp(SvPV_nolen(key), "END")
            || 0 == strcmp(SvPV_nolen(key), "__ANON__"))
            hv_delete_ent(new_stash, key, G_DISCARD, HeHASH(he));
    }
    *stash = sv_2mortal(newRV_noinc((SV*)new_stash));

    I32 remainder = PL_parser->bufend - PL_parser->bufptr;

    *cv = newATTRSUB(floor, NULL, NULL, NULL, op);

    if (start)
        start[-1] = start_orig;
    else
        remainder -= 2; /* not sure why but it fixes things */

    LEAVE;

    return remainder;
}

void p5_runops(PerlInterpreter *my_perl, CV *cv) {
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    call_sv((SV*)cv, G_DISCARD);
    SPAGAIN;
    FREETMPS;
    LEAVE;
}

SV *p5_eval_pv(PerlInterpreter *my_perl, const char* p, I32 croak_on_error) {
    PERL_SET_CONTEXT(my_perl);
    {
        dSP;
        SV * retval;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);

        retval = eval_pv(p, croak_on_error);
        SvREFCNT_inc(retval);

        SPAGAIN;
        PUTBACK;
        FREETMPS;
        LEAVE;
        return retval;
    }
}

SV *p5_err_sv(PerlInterpreter *my_perl) {
    PERL_SET_CONTEXT(my_perl);
    return sv_mortalcopy(ERRSV);
}

void handle_p5_error(I32 *err) {
    SV *err_tmp = ERRSV;
    *err = SvTRUE(err_tmp);
}

void push_arguments(SV **sp, int len, SV *args[]) {
    int i;
    for (i = 0; i < len; i++) {
        if (args[i] != NULL) /* skip Nil which gets turned into NULL */
            XPUSHs(sv_2mortal(args[i]));
    }
    PUTBACK;
}

SV *pop_return_values(PerlInterpreter *my_perl, SV **sp, I32 count, I32 *type) {
    SV * retval = NULL;
    I32 i;

    if (count == 1) {
        retval = POPs;
        SvREFCNT_inc(retval);
        *type = p5_get_type(my_perl, retval);
    }
    else {
        if (count > 1) {
            retval = (SV *)newAV();
            av_extend((AV *)retval, count - 1);
        }

        for (i = count - 1; i >= 0; i--) {
            SV * const next = POPs;
            SvREFCNT_inc(next);

            if (av_store((AV *)retval, i, next) == NULL)
                SvREFCNT_dec(next); /* see perlguts Working with AVs */
        }
    }
    PUTBACK;

    return retval;
}

SV *p5_call_package_method(PerlInterpreter *my_perl, char *package, char *name, int len, SV *args[], I32 *count, I32 *err, I32 *type) {
    PERL_SET_CONTEXT(my_perl);
    {
        dSP;
        SV * retval = NULL;
        int flags = G_ARRAY | G_EVAL;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv(package, 0)));
        push_arguments(sp, len, args);

        *count = call_method(name, flags);
        SPAGAIN;

        handle_p5_error(err);

        retval = pop_return_values(my_perl, sp, *count, type);

        FREETMPS;
        LEAVE;

        return retval;
    }
}

GV *p5_look_up_package_method(PerlInterpreter *my_perl, char *module, char *name, I32 local) {
    PERL_SET_CONTEXT(my_perl);
    {
        HV * const pkg = gv_stashpvn(module, strlen(module), 0);
        GV * gv = gv_fetchmeth_pvn_autoload(pkg, name, strlen(name), -1, SVf_UTF8);
        if (gv && local) {
            GV * const super_gv = gv_fetchmeth_pvn_autoload(pkg, name, strlen(name), -1, SVf_UTF8 | GV_SUPER);
            if (super_gv && (super_gv == gv || GvCV(super_gv) == GvCV(gv)))
                gv = NULL;
        }
        if (gv && isGV(gv))
            return gv;
        return NULL;
    }
}

SV *p5_call_inherited_package_method(PerlInterpreter *my_perl, char *package, char *base_package, char *name, int len, SV *args[], I32 *count, I32 *err, I32 *type) {
    PERL_SET_CONTEXT(my_perl);
    {
        dSP;
        SV * retval = NULL;
        SV * package_sv = newSVpv(package, 0);
        HV * stash = gv_stashsv(package_sv, SVf_UTF8);
        int flags = G_ARRAY | G_EVAL;

        if (stash == NULL) {
            SvREFCNT_dec(package_sv);
            *type = -1; /* signal that a wrapper package needs to be created */
            return NULL;
        }

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);

        XPUSHs(sv_2mortal(package_sv));
        push_arguments(sp, len, args);

        GV * const gv = p5_look_up_package_method(my_perl, base_package, name, 0);
        SV * const rv = GvCV(gv) ? sv_2mortal(newRV_inc((SV*)GvCV(gv))) : (SV*)gv;
        *count = call_sv(rv, flags);

        SPAGAIN;

        handle_p5_error(err);

        retval = pop_return_values(my_perl, sp, *count, type);

        FREETMPS;
        LEAVE;

        return retval;
    }
}

char *p5_stash_name(PerlInterpreter *my_perl, SV *obj) {
    HV * const pkg = SvSTASH((SV*)SvRV(obj));
    return HvNAME(pkg);
}

SV *p5_call_gv(PerlInterpreter *my_perl, GV *gv, int len, SV *args[], I32 *count, I32 *err, I32 *type) {
    PERL_SET_CONTEXT(my_perl);
    {
        dSP;
        int i;
        SV * retval = NULL;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);

        if (len > 1) {
            XPUSHs(args[0]);
            for (i = 1; i < len; i++) {
                if (args[i] != NULL) /* skip Nil which gets turned into NULL */
                    XPUSHs(sv_2mortal(args[i]));
            }
        }
        else if (len > 0)
            if (args != NULL) /* skip Nil which gets turned into NULL */
                XPUSHs((SV*)args);

        PUTBACK;

        SV * const rv = GvCV(gv) ? sv_2mortal(newRV_inc((SV*)GvCV(gv))) : (SV*)gv;

        *count = call_sv(rv, G_ARRAY | G_EVAL);
        SPAGAIN;

        handle_p5_error(err);
        retval = pop_return_values(my_perl, sp, *count, type);
        SPAGAIN;

        PUTBACK;
        FREETMPS;
        LEAVE;

        return retval;
    }
}

void reset_wrapped_object(PerlInterpreter *my_perl, SV *obj) {
    if (SvREFCNT(obj) == 1 && SvREFCNT(SvRV(obj)) == 1) {
        MAGIC * mg = mg_find(SvRV(obj), '~');
        _perl6_magic* const p6mg = (_perl6_magic*) mg->mg_ptr;
        SV **cbs_entry = hv_fetchs(PL_modglobal, "Inline::Perl5 callbacks", 0);
        if (cbs_entry) {
            perl6_callbacks *cbs = (perl6_callbacks*)SvIV(*cbs_entry);
            cbs->free_p6_object(p6mg->index);
        }
        p6mg->index = -1;
        SvREFCNT_inc(SvRV(obj)); // keep it from dying
    }
}

SV *p5_call_parent_gv(PerlInterpreter *my_perl, GV *gv, int len, SV *args[], I32 *count, I32 *err, I32 *type) {
    PERL_SET_CONTEXT(my_perl);
    {
        dSP;
        int i;
        SV * obj;
        SV * retval = NULL;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);

        obj = len > 1 ? args[0] : (SV*) args;

        if (len > 1) {
            XPUSHs(obj);
            for (i = 1; i < len; i++) {
                if (args[i] != NULL) /* skip Nil which gets turned into NULL */
                    XPUSHs(sv_2mortal(args[i]));
            }
        }
        else if (len > 0)
            if (args != NULL) /* skip Nil which gets turned into NULL */
                XPUSHs(obj);

        PUTBACK;

        SV * const rv = GvCV(gv) ? sv_2mortal(newRV((SV*)GvCV(gv))) : (SV*)gv; /* FIXME: can be done once */

        *count = call_sv(rv, G_ARRAY | G_EVAL);
        SPAGAIN;

        handle_p5_error(err);
        retval = pop_return_values(my_perl, sp, *count, type);
        SPAGAIN;

        reset_wrapped_object(my_perl, obj);
        SvREFCNT_dec(obj);

        PUTBACK;
        FREETMPS;
        LEAVE;

        return retval;
    }
}

SV *p5_scalar_call_gv(PerlInterpreter *my_perl, GV *gv, int len, SV *args[], I32 *count, I32 *err, I32 *type) {
    PERL_SET_CONTEXT(my_perl);
    {
        dSP;
        int i;
        SV * retval = NULL;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);

        if (len > 1) {
            XPUSHs(args[0]);
            for (i = 1; i < len; i++) {
                if (args[i] != NULL) /* skip Nil which gets turned into NULL */
                    XPUSHs(sv_2mortal(args[i]));
            }
        }
        else if (len > 0)
            if (args != NULL) /* skip Nil which gets turned into NULL */
                XPUSHs((SV*)args);

        PUTBACK;

        SV * const rv = GvCV(gv) ? sv_2mortal(newRV_inc((SV*)GvCV(gv))) : (SV*)gv;

        *count = call_sv(rv, G_SCALAR | G_EVAL);
        SPAGAIN;

        handle_p5_error(err);
        retval = pop_return_values(my_perl, sp, *count, type);
        SPAGAIN;

        PUTBACK;
        FREETMPS;
        LEAVE;

        return retval;
    }
}

SV *p5_scalar_call_parent_gv(PerlInterpreter *my_perl, GV *gv, int len, SV *args[], I32 *count, I32 *err, I32 *type) {
    PERL_SET_CONTEXT(my_perl);
    {
        dSP;
        int i;
        SV * retval = NULL;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);

        if (len > 1) {
            XPUSHs(args[0]);
            for (i = 1; i < len; i++) {
                if (args[i] != NULL) /* skip Nil which gets turned into NULL */
                    XPUSHs(sv_2mortal(args[i]));
            }
        }
        else if (len > 0)
            if (args != NULL) /* skip Nil which gets turned into NULL */
                XPUSHs((SV*)args);

        PUTBACK;

        SV * const rv = GvCV(gv) ? sv_2mortal(newRV_inc((SV*)GvCV(gv))) : (SV*)gv;

        *count = call_sv(rv, G_SCALAR | G_EVAL);
        SPAGAIN;

        handle_p5_error(err);
        retval = pop_return_values(my_perl, sp, *count, type);
        SPAGAIN;

        PUTBACK;
        FREETMPS;
        LEAVE;

        return retval;
    }
}

SV *p5_call_gv_two_args(PerlInterpreter *my_perl, GV *gv, SV *arg, SV *arg2, I32 *count, I32 *type, I32 *err) {
    PERL_SET_CONTEXT(my_perl);
    {
        dSP;
        SV * retval = NULL;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);

        XPUSHs(sv_2mortal((SV*)arg));
        if (arg2 != NULL)
            XPUSHs(sv_2mortal((SV*)arg2));

        PUTBACK;

        SV * const rv = GvCV(gv) ? sv_2mortal(newRV_inc((SV*)GvCV(gv))) : (SV*)gv;

        *count = call_sv(rv, G_ARRAY | G_EVAL);
        SPAGAIN;

        handle_p5_error(err);
        retval = pop_return_values(my_perl, sp, *count, type);
        SPAGAIN;

        reset_wrapped_object(my_perl, arg);

        PUTBACK;
        FREETMPS;
        LEAVE;

        return retval;
    }
}

SV *p5_scalar_call_gv_two_args(PerlInterpreter *my_perl, GV *gv, SV *arg, SV *arg2, I32 *count, I32 *type, I32 *err) {
    PERL_SET_CONTEXT(my_perl);
    {
        dSP;
        SV * retval = NULL;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);

        XPUSHs(sv_2mortal((SV*)arg));
        if (arg2 != NULL)
            XPUSHs(sv_2mortal((SV*)arg2));

        PUTBACK;

        SV * const rv = GvCV(gv) ? sv_2mortal(newRV_inc((SV*)GvCV(gv))) : (SV*)gv;

        *count = call_sv(rv, G_SCALAR | G_EVAL);
        SPAGAIN;

        handle_p5_error(err);
        retval = pop_return_values(my_perl, sp, *count, type);
        SPAGAIN;

        PUTBACK;
        FREETMPS;
        LEAVE;

        return retval;
    }
}

SV *p5_call_method(PerlInterpreter *my_perl, SV *obj, I32 context, char *name, int len, SV *args[], I32 *count, I32 *err, I32 *type) {
    PERL_SET_CONTEXT(my_perl);
    {
        dSP;
        int i;
        SV * retval = NULL;
        int flags = (context ? G_SCALAR : G_ARRAY) | G_EVAL;

        ENTER;
        SAVETMPS;

        HV * const pkg = SvSTASH((SV*)SvRV(obj));
        GV * const gv = gv_fetchmethod_autoload(pkg, name, TRUE);
        if (gv && isGV(gv)) {
            PUSHMARK(SP);

            if (len > 1) {
                XPUSHs(args[0]);
                for (i = 1; i < len; i++) {
                    if (args[i] != NULL) /* skip Nil which gets turned into NULL */
                        XPUSHs(sv_2mortal(args[i]));
                }
            }
            else if (len > 0)
                if (args != NULL) /* skip Nil which gets turned into NULL */
                    XPUSHs((SV*)args);

            PUTBACK;

            SV * const rv = GvCV(gv) ? sv_2mortal(newRV_inc((SV*)GvCV(gv))) : (SV*)gv;

            *count = call_sv(rv, flags);
            SPAGAIN;

            handle_p5_error(err);
            retval = pop_return_values(my_perl, sp, *count, type);
            SPAGAIN;
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

SV *p5_call_parent_method(PerlInterpreter *my_perl, char *package, SV *parent_obj, I32 context, char *name, int len, SV *args[], I32 *count, I32 *err, I32 *type) {
    PERL_SET_CONTEXT(my_perl);
    {
        dSP;
        int i;
        SV * retval = NULL;
        int flags = (context ? G_SCALAR : G_ARRAY) | G_EVAL;

        ENTER;
        SAVETMPS;

        HV * const pkg = package != NULL ? gv_stashpv(package, 0) : SvSTASH((SV*)SvRV(parent_obj));
        GV * const gv = gv_fetchmethod_autoload(pkg, name, TRUE);
        if (gv && isGV(gv)) {
            SV * obj;

            PUSHMARK(SP);

            obj = len > 1 ? args[0] : (SV*) args;

            if (len > 1) {
                XPUSHs(obj);
                for (i = 1; i < len; i++) {
                    if (args[i] != NULL) /* skip Nil which gets turned into NULL */
                        XPUSHs(sv_2mortal(args[i]));
                }
            }
            else if (len > 0)
                if (args != NULL) /* skip Nil which gets turned into NULL */
                    XPUSHs(obj);

            PUTBACK;

            SV * const rv = GvCV(gv) ? sv_2mortal(newRV_inc((SV*)GvCV(gv))) : (SV*)gv;

            *count = call_sv(rv, flags);
            SPAGAIN;

            handle_p5_error(err);
            retval = pop_return_values(my_perl, sp, *count, type);
            SPAGAIN;

            if (p5_is_live_wrapped_p6_object(my_perl, SvRV(obj))) {
                reset_wrapped_object(my_perl, obj);
                SvREFCNT_dec(obj);
            }
        }

        PUTBACK;
        FREETMPS;
        LEAVE;

        return retval;
    }
}

SV *p5_call_function(PerlInterpreter *my_perl, char *name, int len, SV *args[], I32 *count, I32 *err, I32 *type) {
    PERL_SET_CONTEXT(my_perl);
    {
        dSP;
        SV * retval = NULL;
        int flags = G_ARRAY | G_EVAL;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        push_arguments(sp, len, args);

        *count = call_pv(name, flags);
        SPAGAIN;

        handle_p5_error(err);
        retval = pop_return_values(my_perl, sp, *count, type);

        FREETMPS;
        LEAVE;

        return retval;
    }
}

SV *p5_call_code_ref(PerlInterpreter *my_perl, SV *code_ref, int len, SV *args[], I32 *count, I32 *err, I32 *type) {
    PERL_SET_CONTEXT(my_perl);
    {
        dSP;
        SV * retval = NULL;
        int flags = G_ARRAY | G_EVAL;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        push_arguments(sp, len, args);

        *count = call_sv(code_ref, flags);
        SPAGAIN;

        handle_p5_error(err);
        retval = pop_return_values(my_perl, sp, *count, type);

        FREETMPS;
        LEAVE;

        return retval;
    }
}

#define PERL6_MAGIC_KEY 0x0DD515FE
#define PERL6_HASH_MAGIC_KEY 0x0DD515FF
#define PERL6_EXTENSION_MAGIC_KEY 0x0DD51600

int p5_free_perl6_obj(pTHX_ SV* obj, MAGIC *mg)
{
    if (mg && ((_perl6_magic*) mg->mg_ptr)->index != -1) {
        _perl6_magic* const p6mg = (_perl6_magic*) mg->mg_ptr;
        /* need to be extra careful here as PL_modglobal could have been cleaned already */
        SV **cbs_entry = hv_fetchs(PL_modglobal, "Inline::Perl5 callbacks", 0);
        if (cbs_entry) {
            perl6_callbacks *cbs = (perl6_callbacks*)SvIV(*cbs_entry);
            cbs->free_p6_object(p6mg->index);
        }
    }
    return 0;
}

int p5_free_wrapped_perl6_obj(pTHX_ SV* obj, MAGIC *mg)
{
    if (mg) {
        _perl6_magic* const p6mg = (_perl6_magic*) mg->mg_ptr;
        /* need to be extra careful here as PL_modglobal could have been cleaned already */
        if (p6mg->index != 0) {
            SV **cbs_entry = hv_fetchs(PL_modglobal, "Inline::Perl5 callbacks", 0);
            if (cbs_entry) {
                perl6_callbacks *cbs = (perl6_callbacks*)SvIV(*cbs_entry);
                cbs->free_p6_object(p6mg->index);
            }
            p6mg->index = 0;
        }
    }
    return 0;
}

int p5_free_perl6_hash(pTHX_ SV* obj, MAGIC *mg)
{
    if (mg) {
        _perl6_hash_magic* const p6mg = (_perl6_hash_magic*) mg->mg_ptr;
        /* need to be extra careful here as PL_modglobal could have been cleaned already */
        SV **cbs_entry = hv_fetchs(PL_modglobal, "Inline::Perl5 callbacks", 0);
        if (cbs_entry) {
            perl6_callbacks *cbs = (perl6_callbacks*)SvIV(*cbs_entry);
            cbs->free_p6_object(p6mg->index);
        }
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

MGVTBL p5_inline_wrapped_mg_vtbl = {
    0x0,
    0x0,
    0x0,
    0x0,
    &p5_free_wrapped_perl6_obj,
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

SV *p5_add_magic(PerlInterpreter *my_perl, SV *inst, IV i) {
    PERL_SET_CONTEXT(my_perl);
    {
        MAGIC * const mg = mg_find(inst, '~');
        if (mg && mg->mg_ptr && ((_perl6_magic*)(mg->mg_ptr))->key == PERL6_MAGIC_KEY) {
            ((_perl6_magic*)(mg->mg_ptr))->index = i;
        }
        else {
            _perl6_magic priv;

            /* set up magic */
            priv.key = PERL6_MAGIC_KEY;
            priv.index = i;
            priv.is_wrapper = 1;
            sv_magicext(inst, inst, PERL_MAGIC_ext, &p5_inline_mg_vtbl, (char *) &priv, sizeof(priv));
        }
        return newRV_noinc(inst);
    }
}

SV *p5_wrap_p6_object(PerlInterpreter *my_perl, IV i, SV *p5obj) {
    PERL_SET_CONTEXT(my_perl);
    {
        SV * inst;
        SV * inst_ptr;
        if (p5obj == NULL) {
            inst_ptr = newSViv(0); // will be upgraded to an RV
            inst = newSVrv(inst_ptr, "Perl6::Object");
        }
        else {
            inst_ptr = p5obj;
            inst = SvRV(inst_ptr);
        }
        _perl6_magic priv;

        /* set up magic */
        priv.key = p5obj == NULL ? PERL6_MAGIC_KEY : PERL6_EXTENSION_MAGIC_KEY;
        priv.index = i;
        priv.is_wrapper = 0;
        sv_magicext(inst, inst, PERL_MAGIC_ext, &p5_inline_mg_vtbl, (char *) &priv, sizeof(priv));

        return inst_ptr;
    }
}

SV *p5_wrap_p6_callable(PerlInterpreter *my_perl, IV i, SV *p5obj) {
    SV * inst;
    SV * inst_ptr;

    PERL_SET_CONTEXT(my_perl);

    if (p5obj == NULL) {
        dSP;
        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSViv(i)));
        PUTBACK;
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
    priv.is_wrapper = 0;
    sv_magic(inst, inst, PERL_MAGIC_ext, (char *) &priv, sizeof(priv));
    MAGIC * const mg = mg_find(inst, PERL_MAGIC_ext);
    mg->mg_virtual = &p5_inline_mg_vtbl;

    return inst_ptr;
}

SV *p5_wrap_p6_hash(
    PerlInterpreter *my_perl,
    IV i
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
        sv_magicext(inst, inst, PERL_MAGIC_ext, &p5_inline_hash_mg_vtbl, (char *) &priv, sizeof(priv));

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);

        XPUSHs(sv_2mortal(newSVpv("Perl6::Hash", 0)));
        XPUSHs(sv_2mortal(inst_ptr));

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

SV *p5_wrap_p6_handle(PerlInterpreter *my_perl, IV i, SV *p5obj) {
    PERL_SET_CONTEXT(my_perl);
    {
        SV *handle = p5_wrap_p6_object(my_perl, i, p5obj);
        int flags = G_SCALAR;
        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);

        XPUSHs(sv_2mortal(newSVpv("Perl6::Handle", 0)));
        XPUSHs(sv_2mortal(handle));

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
    PERL_SET_CONTEXT(my_perl);
    {
        SV * const obj_deref = SvRV(obj);
        /* check for magic! */
        MAGIC * const mg = mg_find(obj_deref, '~');
        return (mg && mg->mg_ptr && ((_perl6_magic*)(mg->mg_ptr))->key == PERL6_MAGIC_KEY);
    }
}

int p5_is_live_wrapped_p6_object(PerlInterpreter *my_perl, SV *obj) {
    PERL_SET_CONTEXT(my_perl);
    {
        /* check for magic! */
        MAGIC * const mg = mg_find(obj, '~');
        return (
            mg
            && mg->mg_ptr
            && ((_perl6_magic*)(mg->mg_ptr))->key == PERL6_MAGIC_KEY
            && ((_perl6_magic*)(mg->mg_ptr))->index != -1
            && ((_perl6_magic*)(mg->mg_ptr))->is_wrapper == 1
        );
    }
}

IV p5_unwrap_p6_object(PerlInterpreter *my_perl, SV *obj) {
    PERL_SET_CONTEXT(my_perl);
    {
        SV * const obj_deref = SvRV(obj);
        MAGIC * const mg = mg_find(obj_deref, '~');
        return ((_perl6_magic*)(mg->mg_ptr))->index;
    }
}

AV *create_args_array(const I32 ax, I32 items, I32 num_fixed_args) {
    AV * args = newAV();
    av_extend(args, items - num_fixed_args);
    int i;
    for (i = 0; i < items - num_fixed_args; i++) {
        SV * const next = SvREFCNT_inc(ST(i + num_fixed_args));
        if (av_store(args, i, next) == NULL)
            SvREFCNT_dec(next); /* see perlguts Working with AVs */
    }
    return args;
}

void return_retval(const I32 ax, SV **sp, SV *retval) {
    if (retval == NULL || GIMME_V == G_VOID) {
        XSRETURN_EMPTY;
    }
    if (GIMME_V == G_ARRAY) {
        if (SvROK(retval) && SvTYPE(SvRV(retval)) == SVt_PVAV) {
            AV* const av = (AV*)SvRV(retval);
            I32 const len = av_len(av) + 1;
            I32 i;
            for (i = 0; i < len; i++) {
                XPUSHs(sv_2mortal(av_shift(av)));
            }
            XSRETURN(len);
        }
        else {
            XPUSHs(retval);
            XSRETURN(1);
        }
    }
    else {
        if (SvROK(retval) && SvTYPE(SvRV(retval)) == SVt_PVAV) {
            AV* const av = (AV*)SvRV(retval);
            XPUSHs(sv_2mortal(av_shift(av)));
            XSRETURN(1);
        }
        else {
            XPUSHs(retval);
            XSRETURN(1);
        }
    }
}

void handle_p6_error(SV *err) {
    if (err) {
        sv_2mortal(err);
        croak_sv(err);
    }
}

void post_callback(const I32 ax, SV **sp, I32 items, SV * const args_rv, SV *err, SV *retval) {
    /* refresh local stack pointer, could have been modified by Perl 5 code called from Perl 6 */
    SPAGAIN;
    SvREFCNT_dec(args_rv);
    handle_p6_error(err);
    sv_2mortal(retval);
    sp -= items;
    return return_retval(ax, sp, retval);
}

XS(p5_call_p6_method) {
    dXSARGS;
    SV * name = ST(0);
    SV * obj = ST(1);

    AV *args = create_args_array(ax, items, 2);

    STRLEN len;
    char * const name_pv  = SvPV(name, len);

    if (!SvROK(obj)) {
        croak("Got a non-reference for obj in p5_call_p6_method calling %s?!", name_pv);
    }
    SV * const obj_deref = SvRV(obj);
    MAGIC * const mg = mg_find(obj_deref, '~');
    if (!mg) {
        XSRETURN_EMPTY;
        return;
    }
    _perl6_magic* const p6mg = (_perl6_magic*)(mg->mg_ptr);
    if (p6mg->index < 0) {
        if (PL_in_clean_objs || PL_in_clean_all || 0 == strcmp(name_pv, "can")) {
            XSRETURN_EMPTY;
            return;
        }
        else {
            croak("p5_call_p6_method %s on a reset object?", name_pv);
        }
    }
    SV *err = NULL;
    SV * const args_rv = newRV_noinc((SV *) args);

    declare_cbs;
    SV * retval = cbs->call_p6_method(p6mg->index, name_pv, GIMME_V == G_SCALAR, args_rv, &err);
    return post_callback(ax, sp, items, args_rv, err, retval);
}

XS(p5_destroy_p5_object) {
    dXSARGS;
    SV * obj = ST(0);
    SV * const inst = SvRV(obj);
    MAGIC * mg = mg_find(inst, '~');
    int destroyed = 1;
    if (mg) {
        _perl6_magic* const p6mg = (_perl6_magic*) mg->mg_ptr;
        /* need to be extra careful here as PL_modglobal could have been cleaned already */
        if (
            (      p6mg->key == PERL6_MAGIC_KEY
                || p6mg->key == PERL6_HASH_MAGIC_KEY
                || p6mg->key == PERL6_EXTENSION_MAGIC_KEY
            )
            && p6mg->index != -1
            && !PL_in_clean_objs
        ) {
            SV **cbs_entry = hv_fetchs(PL_modglobal, "Inline::Perl5 callbacks", 0);
            if (cbs_entry) {
                perl6_callbacks *cbs = (perl6_callbacks*)SvIV(*cbs_entry);
                cbs->free_p6_object(p6mg->index);
            }
            p6mg->index = -1;
            SvREFCNT_inc(inst); // resurrect it!
            destroyed = 0;
        }
    }
    sp -= items;
    XPUSHs(sv_2mortal(newSViv(destroyed && !PL_in_clean_objs)));
    XSRETURN(1);
}

MAGIC *find_shadow_magic(SV *p6cb, SV *static_class, SV *obj) {
    SV * const obj_deref = SvRV(obj);
    MAGIC * mg = mg_find(obj_deref, '~');
    if (mg == NULL || ((_perl6_magic*)(mg->mg_ptr))->key != PERL6_EXTENSION_MAGIC_KEY) {
        /* need to create the shadow object here */

        AV * method_args = newAV();
        SV * method_args_rv = newRV_noinc((SV *) method_args);
        av_extend(method_args, 1);
        SvREFCNT_inc(obj);
        av_store(method_args, 0, obj);

        AV * args = newAV();
        av_extend(args, 3);
        SvREFCNT_inc(static_class);
        av_store(args, 0, static_class);
        av_store(args, 1, newSVpvs("new_shadow_of_p5_object"));
        av_store(args, 2, method_args_rv);

        MAGIC * const p6cb_mg = mg_find(SvRV(p6cb), '~');
        _perl6_magic* const p6cb_p6mg = (_perl6_magic*)(p6cb_mg->mg_ptr);
        SV *err = NULL;
        SV * const args_rv = newRV_noinc((SV *) args);

        declare_cbs;
        cbs->call_p6_method(p6cb_p6mg->index, "invoke", 1, args_rv, &err);
        SvREFCNT_dec(args_rv);
        handle_p6_error(err);

        mg = mg_find(obj_deref, '~');
    }
    return mg;
}

XS(p5_call_p6_extension_method) {
    dXSARGS;
    SV * p6cb = ST(0);
    SV * static_class = ST(1);
    SV * name = ST(2);
    SV * obj = ST(3);
    SV * err = NULL;

    STRLEN len;
    char * const name_pv  = SvPV(name, len);

    if (!SvROK(obj)) {
        if (SvPOK(obj)) {
            char * const package_pv  = SvPV(obj, len);
            AV *args = create_args_array(ax, items, 4);
            SV * const args_rv = newRV_noinc((SV *) args);
            declare_cbs;
            SV * retval = cbs->call_p6_package_method(package_pv, name_pv, GIMME_V == G_SCALAR, args_rv, &err);
            return post_callback(ax, sp, items, args_rv, err, retval);
        }
        else {
            croak("Got a non-reference for obj in p5_call_p6_extension_method?!");
        }
    }
    MAGIC * mg = find_shadow_magic(p6cb, static_class, obj);
    _perl6_magic* const p6mg = (_perl6_magic*)(mg->mg_ptr);

    AV *args = create_args_array(ax, items, 4);
    SV * const args_rv = newRV_noinc((SV *) args);

    declare_cbs;
    SV * retval = cbs->call_p6_method(p6mg->index, name_pv, GIMME_V == G_SCALAR, args_rv, &err);
    return post_callback(ax, sp, items, args_rv, err, retval);
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

    declare_cbs;
    SV * retval = cbs->hash_at_key(p6mg->index, key_pv);

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

    declare_cbs;
    cbs->hash_assign_key(p6mg->index, key_pv, val);

    sp -= items;

    XSRETURN_EMPTY;
}

XS(p5_call_p6_callable) {
    dXSARGS;
    SV * index = ST(0);

    AV *args = create_args_array(ax, items, 1);

    SV *err = NULL;
    SV * const args_rv = newRV_noinc((SV *) args);

    declare_cbs;
    SV * retval = cbs->call_p6_callable(SvIV(index), args_rv, &err);
    return post_callback(ax, sp, items, args_rv, err, retval);
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
