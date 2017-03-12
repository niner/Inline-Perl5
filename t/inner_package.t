#!/usr/bin/env perl6

use v6;
use lib:from<Perl5> 't/lib';
use HasInnerPackage:from<Perl5>;
use Test;

is(HasInnerPackage.func, 'has-inner-package', 'HasInnerPackage');

todo("The real test is commented out for now, since it won't compile yet.");
ok(0);
#is(InnerPackage.func, 'inner-package', 'InnerPackage');

done-testing;

