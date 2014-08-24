#include <EXTERN.h>
#include <perl.h>

static PerlInterpreter *my_perl;

void perl_sys_init3() {
    PERL_SYS_INIT3(0, NULL, NULL);
}

void set_perl_exit_flags() {
    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
}

