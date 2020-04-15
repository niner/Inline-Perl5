unit module Inline::Perl5::Perl5Class;

use Inline::Perl5::Attributes;

use MONKEY-SEE-NO-EVAL;

our sub create-perl5-class($p5, $package, $body) {
    my $*P5 = $p5;
    my $*IP5 = $p5.interpreter;

    my $parents = $p5.global('@' ~ $package ~ '::ISA');
    my @parents = [];
    if $parents {
        for $parents.keys {
            my $parent = $parents[$_];
            @parents[$_] := $p5.module-loaded($parent)
                    ?? $p5.loaded-module($parent)
                    !! $p5.create_wrapper_class($parent);
        }
    }

    sub get-module($module) {
        $p5.loaded-module($module);
    }
    my $i = 0;
    my $classes = @parents.map(*.^name).map({"my constant \\parent{$i++} := get-module('$_');"}).join(' ');
    my $class := EVAL "use Inline::Perl5::ClassHOW; $classes perl5class GLOBAL::$package {(0..^$i).map({"is parent$_ "}).join }\{\n$body\n\}";
    $p5.add-to-loaded-modules($package, $class);

    my $symbols = $p5.subs_in_module($package);

    for $class.^methods(:local) -> $method {
        next if $method.name eq 'new';
        next if $method.name eq 'DESTROY';
        next if $method.name eq 'wrapped-perl5-object';

        $method.does(Inline::Perl5::Attributes)
            ?? $p5.install_wrapper_method($package, $method.name, |$method.attributes)
            !! $p5.install_wrapper_method($package, $method.name);
    }

    for @$symbols -> $name {
        next if $name eq 'DESTROY';
        next if $name eq 'wrapped-perl5-object';
        $class.^add_wrapper_method($name);
    }
}
