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

PerlInterpreter *init_perl() {
    char *embedding[] = { "", "-e", "0" };
    PERL_SYS_INIT3(0, NULL, NULL);
    my_perl = perl_alloc();
    perl_construct( my_perl );
    perl_parse(my_perl, xs_init, 3, embedding, NULL);
    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
    perl_run(my_perl);
    return my_perl;
}

int Perl_SvIOK(PerlInterpreter *my_perl, SV* sv) {
    return SvIOK(sv);
}
