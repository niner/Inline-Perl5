use nqp;
class Inline::Perl5::ClassHOW {
    has $!name;
    has %!cache;

    submethod BUILD(:$!name) { }

    method new_type(:$name) is raw {
        my $how = self.new(:$name);
        my $type := Metamodel::Primitives.create_type($how);
        nqp::setdebugtypename($type, $name);
        $type
    }

    method name($) {
        $!name
    }

    method compose($type) {
        # Set up type checking with cache.
        Metamodel::Primitives.configure_type_checking($type,
            [Any, Mu],
            :authoritative, :call_accepts);

        # Steal methods of Any/Mu for our method cache.
        for flat Any.^method_table.pairs, Mu.^method_table.pairs {
            %!cache{.key} //= .value;
        }
        %!cache<foo> := method foo($type:) {
            say "foo!";
        };
        %!cache<new> := method new($type:) {
            $type.CREATE
        }
        Metamodel::Primitives.install_method_cache($type, %!cache, :!authoritative);

        Metamodel::Primitives.compose_type($type, {attribute => []});

        $type
    }

    method cache_method($type, $name, \meth) is raw {
        %!cache{$name} := meth;
        Metamodel::Primitives.install_method_cache($type, %!cache, :!authoritative);
        meth
    }

    method type_check(Mu $, Mu \check) {
        for Any, Mu {
            return True if Metamodel::Primitives.is_type(check, $_);
        }
        return False;
    }

    method accepts_type(Mu $, Mu \check) {
        return False;
    }

    method find_method($type, $name) is raw {
        say "finding method $name";
        my $meth := Any.^find_method($name);
        $meth or $meth := self.cache_method($type, $name, my method () {
            say $name ~ '!';
        });
        $meth
    }
}

my $foo := Inline::Perl5::ClassHOW.new_type(:name<Foo>);
$foo.^compose;
my $instance = $foo.new;
$foo.foo;
$instance.foo;
$foo.^cache_method('bar', my method bar() { say "bar!"; });
$instance.bar;
$instance.item;
$instance.baz;
