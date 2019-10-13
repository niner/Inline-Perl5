unit module Inline::Perl5::FindBestDispatchee::Full;

our sub find_best_dispatchee(\SELF, Mu \capture) is export {
    use nqp;
    my $arity = nqp::captureposelems(capture);
    my \entry =
        nqp::capturenamedshash(capture) || nqp::captureposarg(capture, 0).defined.not
            ?? nqp::hllbool(nqp::islt_i($arity, 2)) || (nqp::eqaddr(nqp::captureposarg(capture, 1), Scalar)).not
                ?? nqp::getattr(SELF, SELF.WHAT, '&!many-args')
                !! nqp::getattr(SELF, SELF.WHAT, '&!scalar-many-args')
            !! nqp::hllbool(nqp::iseq_i($arity, 1))
                ?? nqp::getattr(SELF, SELF.WHAT, '&!no-args')
                !! nqp::hllbool(nqp::iseq_i($arity, 2)) && nqp::istype(nqp::captureposarg(capture, 1), Pair).not
                    ?? nqp::eqaddr(nqp::captureposarg(capture, 1), Scalar)
                        ?? nqp::getattr(SELF, SELF.WHAT, '&!scalar-no-args')
                        !! nqp::getattr(SELF, SELF.WHAT, '&!one-arg')
                    !! nqp::hllbool(nqp::iseq_i($arity, 3)) && nqp::eqaddr(nqp::captureposarg(capture, 1), Scalar)
                        ?? nqp::getattr(SELF, SELF.WHAT, '&!scalar-one-arg')
                        !! nqp::eqaddr(nqp::captureposarg(capture, 1), Scalar)
                            ?? nqp::getattr(SELF, SELF.WHAT, '&!scalar-many-args')
                            !! nqp::getattr(SELF, SELF.WHAT, '&!many-args');
    nqp::scwbdisable();
    nqp::bindattr(SELF, Routine, '$!dispatch_cache',
        nqp::multicacheadd(
            nqp::getattr(SELF, Routine, '$!dispatch_cache'),
            capture, entry));
    nqp::scwbenable();
    entry
}
