unit module Inline::Perl5::FindBestDispatchee::Medium;
our sub find_best_dispatchee(\SELF, Mu \capture) is export {
    use nqp;
    nqp::capturenamedshash(capture) || nqp::captureposarg(capture, 0).defined.not
        ?? nqp::getattr(SELF, SELF.WHAT, '&!many-args')
        !! nqp::captureposelems(capture) == 1
            ?? nqp::getattr(SELF, SELF.WHAT, '&!no-args')
            !! nqp::captureposelems(capture) == 2 && nqp::captureposarg(capture, 1).isa(Pair).not
                ?? nqp::getattr(SELF, SELF.WHAT, '&!one-arg')
                !! nqp::getattr(SELF, SELF.WHAT, '&!many-args')
}
