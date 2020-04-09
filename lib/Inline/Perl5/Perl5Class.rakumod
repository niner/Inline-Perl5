unit module Inline::Perl5::Perl5Class;

use Inline::Perl5::Attributes;

use MONKEY-SEE-NO-EVAL;

our sub create-perl5-class($p5, $package, $body) {
    my $*P5 = $p5;
    my $*IP5 = $p5.interpreter;

    my $base_type := $p5.global('@' ~ $package ~ '::ISA')[0];
    $base_type := $base_type ?? $p5.loaded-module($base_type) !! Any;
    my $class := EVAL "use Inline::Perl5::ClassHOW; perl5class GLOBAL::$package {$base_type ?? " is $base_type " !! ""}\{\n$body\n\}";
    $p5.add-to-loaded-modules($package, $class);

    for $class.^attributes.grep(*.has_accessor) -> $attribute {
        $p5.install_wrapper_method($package, $attribute.name.substr(2));
    }

    for $class.^methods(:local) -> $method {
        next if $method.name eq 'new';
        next if $method.name eq 'DESTROY';
        next if $method.name eq 'wrapped-perl5-object';

        $method.does(Inline::Perl5::Attributes)
            ?? $p5.install_wrapper_method($package, $method.name, |$method.attributes)
            !! $p5.install_wrapper_method($package, $method.name);
    }
}
