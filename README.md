# TITLE

Inline::Perl5

# SYNOPSIS

```
    use Inline::Perl5;
    use DBI:from<Perl5>;

    my $dbh = DBI.connect('dbi:Pg:database=test');
    my $products = $dbh.selectall_arrayref(
    	'select * from products', {Slice => {}}
    );
```

# DESCRIPTION

Module for executing Perl 5 code and accessing Perl 5 modules from Perl 6.

Supports Perl 5 modules including XS modules. Allows passing integers,
strings, arrays, hashes, code references, file handles and objects between
Perl 5 and Perl 6. Also supports calling methods on Perl 5 objects from
Perl 6 and calling methods on Perl 6 objects from Perl 5 and subclass
Perl 5 classes in Perl 6.

# HOW DO I?

## Load a Perl 5 module

Perl 6' use statement allows you to load modules from other languages as well.
Inline::Perl5 registers as a handler for the Perl5 language. Rakudo will
automatically load Inline::Perl5 as long as it is installed:

```
    use Test::More:from<Perl5>;
```

In Perl 6 the :ver adverb is used for requiring a minimum version of a loaded
module:

```
    use Test::More:from<Perl5>:ver<1.001014>;
```

Inline::Perl5's use() method maps to Perl 5's use statement:

```
    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;
    $p5.use('Test::More');
```

## Call a Perl 5 function

Inline::Perl5 creates wrappers for loaded Perl 5 modules and their functions.
They can be used as if they were Perl 6 modules:

```
    use Test::More:from<Perl5>;
    Test::More::plan(1);
    Test::More::ok('yes', 'looks like a Perl 6 function');
```

Inline::Perl5's call($name, \*@args) method allows calling arbitrary Perl 5
functions. Use a fully qualified name (like "Test::More::ok") if the function
is not in the "main" namespace.

```
    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;
    $p5.call('print', 'Hello World');
    $p5.use('Test::More');
    $p5.call('Test::More::plan', 1);
```

Please note that since Perl 6 does not have the same concept of "context",
Perl 5 functions are always called in list context.

## Create a Perl 5 object / call a Perl 5 package method

Creating Perl 5 objects works just the same as in Perl 5: invoke their
constructor (usually called "new").

```
    use Inline::Perl5;
    use Data::Dumper:from<Perl5>;
    my $dumper = Data::Dumper.new();
```

Or using the low level methods:

```
    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;
    $p5.use('Data::Dumper');
    my $dumper = $p5.invoke('Data::Dumper', 'new');
```

Please note that since Perl 6 does not have the same concept of "context",
Perl 5 methods are always called in list context.

## Invoke a method on a Perl 5 object

Once you have a Perl 5 object in a variable it will behave just like a Perl 6
object.  You can call methods on it like on any other object.

```
    use Inline::Perl5;
    use IO::Compress::Bzip2:from<Perl5>;
    my $bzip2 = IO::Compress::Bzip2.new('/tmp/foo.bz2');
    $bzip2.print($data);
    $bzip2.close;
```

Please note that since Perl 6 does not have the same concept of "context",
Perl 5 methods are always called in list context.

## Run arbitrary Perl 5 code

Perl6's EVAL function supports multiple languages, just like the "use"
statement. It allows for execution of arbitrary Perl 5 code given as string:

```
    EVAL "print 'Hello from Perl 5';", :lang<Perl5>;
```

The low level interface to this functionality is Inline::Perl5's run($str)
method:

```
    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;

    $p5.run(q'
        sub test {
            return 'Hello from Perl 5';
        }
    ');
```

Both "EVAL" and "run" return the value of the last statement in the EVAL'ed
code.

## Call a Perl 6 function from Perl 5

Inline::Perl5 creates a Perl 5 package called "v6". This package contains
a "call" function which allows for calling Perl 6 functions from Perl 5,
same as Inline::Perl5's "call" method. It takes the name of the function
to call and passes on any additional arguments and returns the return value
of the called Perl 5 function.

```
    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;

    our sub foo($str) {
        say "Perl6 says hello to $str";
    };

    $p5.run(q:to/PERL5/);
        v6::call("foo", "Perl 5");
    PERL5
```

## Invoke a method on a Perl 6 object from Perl 5

Perl 6 objects passed to Perl 5 functions will behave just like any other
objects in Perl 5, so you can invoke methods using the -> operator.

```
    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;

    $p5.run(q'
        sub test {
            my ($perl6) = @_;
            $perl6->hello;
        }
    ');

    class Foo {
        method hello {
            say "Hello Perl 6";
        }
    }

    $p5.call('test', Foo.new);
```

## Run arbitrary Perl 6 code from Perl 5

The "run" function in the automatically created "v6" package can be used to
execute arbitrary Perl 6 code from Perl 5. It returns the value of the last
evaluated expression in the executed code.

```
    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;

    $p5.run(q:to/PERL5/);
        v6::run("say foo");
    PERL5
```

## Inherit from a Perl 5 class

Inline::Perl5 creates a corresponding Perl 6 class for each Perl 5 module
loaded via the <code>use Foo:from<Perl5></code> or <code>$p5.use('Foo')</code>
mechanisms.

You can subclass these automatically created classes as if they were original
Perl 6 classes:

```
    use Data::Dumper:from<Perl5>;
    class MyDumper is Data::Dumper {
        has $.bar;
        method foo { say "foo!"; }
    }
    my $dumper = MyDumper.new([1], bar => 1);
    say $dumper.Dump();
    say $dumper.foo;
    say $dumper.bar;
```

You can override methods and the overridden methods will be called even by the
Perl 5 methods in your base class. However, it is not yet possible to directly
access the Perl 5 object's data, i.e. <code>$self->{foo}</code>.

When <code>use</code> cannot be used to load the Perl 5 module, the
Inline::Perl5::Perl5Parent role allows can be used for subclassing.
Pass the Perl 5 package's name as parameter to the role. Pass the Inline::Perl5
object as named parameter to your classes constructor when creating objects.

```
    $p5.run(q:heredoc/PERL5/);

    package Foo;

    sub test {
        my ($self) = @_;

        return $self->bar;
    }

    PERL5

    class Bar does Inline::Perl5::Perl5Parent['Foo'] {
        method bar {
            return "Perl6";
        }
    }

    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;
    say Bar.new(perl5 => $p5).test;
```

## Catch exceptions thrown by Perl 5 code

Perl 5's exceptions (die) are translated to X::AdHoc exceptions in Perl 6 and
can be caught like any other Perl 6 exceptions:

```
    {
        EVAL "die 'a Perl 5 exception!';", :lang<Perl5>;
        CATCH {
            when X::AdHoc {
                say "Caught a Perl 5 exception: $_";
            }
        }
    }
```

## Catch exceptions thrown by Perl 6 code in Perl 5

Perl 6's exceptions (die) are translated to Perl 5 exceptions and
can be caught like any other Perl 5 exceptions:

```
    EVAL q:to:PERL5, :lang<Perl5>;
        use 5.10.0;
        eval {
            v6::run('die("test");');
        };
        say $@;
    PERL5
```

## Mix Perl 5 and Perl 6 code in the same file

Inline::Perl5 creates a virtual module called "v6::inline". By saying
"use v6::inline;" in a Perl 5 module, you can declare that the rest of the file
is written in Perl 6:

```
    package Some::Perl5::Module;

    use v6::inline;

    has $.name;

    sub greet {
        say "Hello $.name";
    }
```

Note that this Perl 5 module obviously will only work when Inline::Perl5 is
loaded, i.e. in a Perl 6 program or if you are using Inline::Perl6 in Perl 5.
This functionality is aimed at supporting Perl 5 frameworks (think Catalyst
or DBIx::Class or Dancer or ...) that automatically load modules and of course
expect these modules to be written in Perl 5.

# BUILDING

You will need a perl 5 built with the -fPIC option (position independent
code). Most distributions build their Perl 5 that way. When you use perlbrew,
you have to build it as:

    perlbrew install perl-5.20.0 -Duseshrplib

(or, if you want to use more than one Inline::Perl5 interpeter safely, for
instance from within Perl 6 threads, add the `-Dusemultiplicity` option as well)

If you use the perl that comes with a Linux distribution, you may need to
install a separate package containing the perl library. E.g. on Debian
this is called libperl-dev, on Fedora perl-libs. On openSUSE, the perl
package already contains everything needed.

Build Inline::Perl5 with

    perl6 configure.pl6

and test with

    make test


# AUTHOR

Stefan Seifert <nine@detonation.org>
