unit module Inline::Perl5::FindBestDispatchee::Light;
our sub find_best_dispatchee(\SELF, Mu \capture) is export {
    use nqp;
    nqp::getattr(SELF, SELF.WHAT, '&!many-args')
}

