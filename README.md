# TITLE

Inline::Perl5

[![Build Status](https://travis-ci.org/niner/Inline-Perl5.svg?branch=master)](https://travis-ci.org/niner/Inline-Perl5)

# SYNOPSIS

```raku
    use DBI:from<Perl5>;

    my $dbh = DBI.connect('dbi:Pg:database=test');
    my $products = $dbh.selectall_arrayref(
    	'select * from products', {Slice => {}}
    );
```

# DESCRIPTION

Module for executing Perl 5 code and accessing Perl 5 modules from Raku.

Supports Perl 5 modules including XS modules. Allows passing integers,
strings, arrays, hashes, code references, file handles and objects between
Perl 5 and Raku. Also supports calling methods on Perl 5 objects from
Raku and calling methods on Raku objects from Perl 5 and subclass
Perl 5 classes in Raku.

Note that installing Inline::Perl5 requires the Perl 5 library to be installed.
See the BUILDING section for more information.

# HOW DO I?

## Load a Perl 5 module

Raku's use statement allows you to load modules from other languages as well.
Inline::Perl5 registers as a handler for the Perl5 language. Rakudo will
automatically load Inline::Perl5 as long as it is installed:

```raku
    use Test::More:from<Perl5>;
```

In Raku the :ver adverb is used for requiring a minimum version of a loaded
module:

```raku
    use Test::More:from<Perl5>:ver<1.001014>;
```

Inline::Perl5's use() method maps to Perl 5's use statement:

```raku
    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;
    $p5.use('Test::More');
```

To load a Perl 5 module from a specific folder:

```raku
    use lib:from<Perl5> 'lib';
    use MyModule:from<Perl5>;
```

## Load a Perl 5 module and import functions

Just list the functions or groups you want to import

```raku
    use Digest::SHA1:from<Perl5> <sha1_hex>;
```

```raku
    use Data::Random:from<Perl5> <:all>;
```

## Call a Perl 5 function

Inline::Perl5 creates wrappers for loaded Perl 5 modules and their functions.
They can be used as if they were Raku modules:

```raku
    use Test::More:from<Perl5>;
    plan tests => 1;
    ok 'yes', 'looks like a Raku function';
```

In this example, the `plan` function exported by `Test::More` is called.

Inline::Perl5's call($name, \*@args) method allows calling arbitrary Perl 5
functions. Use a fully qualified name (like "Test::More::ok") if the function
is not in the "main" namespace.

```raku
    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;
    $p5.call('print', 'Hello World');
    $p5.use('Test::More');
    $p5.call('Test::More::plan', tests => 1);
```

Please note that since Raku does not have the same concept of "context",
Perl 5 functions are by default called in list context. See "Invoking a
method in scalar context" for how to get around that.

## Create a Perl 5 object / call a Perl 5 package method

Creating Perl 5 objects works just the same as in Perl 5: invoke their
constructor (usually called "new").

```raku
    use Inline::Perl5;
    use Data::Dumper:from<Perl5>;
    my $dumper = Data::Dumper.new;
```

Or using the low level methods:

```raku
    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;
    $p5.use('Data::Dumper');
    my $dumper = $p5.invoke('Data::Dumper', 'new');
```

Please note that since Raku does not have the same concept of "context",
Perl 5 methods are by default called in list context. See "Invoking a
method in scalar context" for how to get around that.

## Invoke a method on a Perl 5 object

Once you have a Perl 5 object in a variable it will behave just like a Raku
object.  You can call methods on it like on any other object.

```raku
    use IO::Compress::Bzip2:from<Perl5>;
    my $bzip2 = IO::Compress::Bzip2.new('/tmp/foo.bz2');
    $bzip2.print($data);
    $bzip2.close;
```

### Invoking a method in scalar context

Please note that since Raku does not have the same concept of "context",
Perl 5 methods are by default called in list context. If you need to call the
method in scalar context, you can tell it so explicitly, by passing the
`Scalar` type object as first argument:

```raku
    use IO::Compress::Bzip2:from<Perl5>;
    my $bzip2 = IO::Compress::Bzip2.new(Scalar, '/tmp/foo.bz2');
    $bzip2.print(Scalar, $data);
    $bzip2.close(Scalar);
```

This may be neccessary if the Perl 5 method exposes different behavior when
called in list and scalar context. Calling in scalar context may also improve
performance in some cases.

## Access a Perl 5 object's data directly

Most objects in Perl 5 are blessed hash references. Some of them don't even
provide accessor methods but require you to just access the hash fields
directly. This works the same in Raku:

```raku
    use Foo:from<Perl5>;
    my $foo = Foo.new;
    say $foo<some_attribute>;
```

## Run arbitrary Perl 5 code

Raku's EVAL function supports multiple languages, just like the "use"
statement. It allows for execution of arbitrary Perl 5 code given as string:

```raku
    EVAL "print 'Hello from Perl 5';", :lang<Perl5>;
```

The low level interface to this functionality is Inline::Perl5's run($str)
method:

```raku
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

## Call a Raku function from Perl 5

Inline::Perl5 creates a Perl 5 package called "v6". This package contains
a "call" function which allows for calling Raku functions from Perl 5,
same as Inline::Perl5's "call" method. It takes the name of the function
to call and passes on any additional arguments and returns the return value
of the called Perl 5 function.

```raku
    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;

    our sub foo($str) {
        say "Raku says hello to $str";
    };

    $p5.run(q:to/PERL5/);
        v6::call("foo", "Perl 5");
    PERL5
```

## Invoke a method on a Raku object from Perl 5

Raku objects passed to Perl 5 functions will behave just like any other
objects in Perl 5, so you can invoke methods using the -> operator.

```raku
    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;

    $p5.run(q'
        sub test {
            my ($raku) = @_;
            $raku->hello;
        }
    ');

    class Foo {
        method hello {
            say "Hello Raku";
        }
    }

    $p5.call('test', Foo.new);
```

## Run arbitrary Raku code from Perl 5

The "run" function in the automatically created "v6" package can be used to
execute arbitrary Raku code from Perl 5. It returns the value of the last
evaluated expression in the executed code.

```raku
    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;

    $p5.run(q:to/PERL5/);
        v6::run("say foo");
    PERL5
```

## Inherit from a Perl 5 class

Inline::Perl5 creates a corresponding Raku class for each Perl 5 module
loaded via the <code>use Foo:from<Perl5></code> or <code>$p5.use('Foo')</code>
mechanisms.

You can subclass these automatically created classes as if they were original
Raku classes:

```raku
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
write to the Perl 5 object's data, i.e. <code>$self->{foo} = 1;</code>. Read
access however is possible, i.e. <code>my $foo = self<foo>;</code>.

When <code>use</code> cannot be used to load the Perl 5 module, the
Inline::Perl5::Perl5Parent role allows can be used for subclassing.
Pass the Perl 5 package's name as parameter to the role. Pass the Inline::Perl5
object as named parameter to your classes constructor when creating objects.

```raku
    $p5.run(q:heredoc/PERL5/);

    package Foo;

    sub test {
        my ($self) = @_;

        return $self->bar;
    }

    PERL5

    class Bar does Inline::Perl5::Perl5Parent['Foo'] {
        method bar {
            return "Raku";
        }
    }

    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;
    say Bar.new(perl5 => $p5).test;
```

## Pass a scalar reference to Perl 5 code

Simply pass a [`Capture`](https://docs.raku.org/type/Capture) object containing
the object you want to pass as a reference:

```raku
    $p5obj.takes-a-scalar-ref-to-str: \("the string");
```

`HASH` and `ARRAY` references are made automatically if the Raku objects
are [containerized](https://perl6advent.wordpress.com/2017/12/02/):

```raku
    $p5obj.takes-an-array:      [<a b c>];
    $p5obj.takes-an-array-ref: $[<a b c>];
```

`CODE` objects are passed by reference automatically:

```raku
    $p5obj.takes-a-coderef: *.so;
```

`Regex` objects are passed by reference automatically:

```raku
    $p5obj.takes-a-regex: /foo/;
```

## Catch exceptions thrown by Perl 5 code

Perl 5's exceptions (die) are translated to X::AdHoc exceptions in Raku and
can be caught like any other Raku exceptions:

```raku
    {
        EVAL "die 'a Perl 5 exception!';", :lang<Perl5>;
        CATCH {
            when X::AdHoc {
                say "Caught a Perl 5 exception: $_";
            }
        }
    }
```

## Catch exceptions thrown by Raku code in Perl 5

Raku's exceptions (die) are translated to Perl 5 exceptions and
can be caught like any other Perl 5 exceptions:

```raku
    EVAL q:to:PERL5, :lang<Perl5>;
        use 5.10.0;
        eval {
            v6::run('die("test");');
        };
        say $@;
    PERL5
```

## Mix Perl 5 and Raku code in the same file

Inline::Perl5 creates a virtual module called "v6-inline". By saying
"use v6-inline;" in a Perl 5 module, you can declare that the rest of the file
is written in Raku:

```perl
    package Some::Perl5::Module;

    use v6-inline;

    has $.name;

    sub greet {
        say "Hello $.name";
    }
```

Note that this Perl 5 module obviously will only work when Inline::Perl5 is
loaded, i.e. in a Raku program or if you are using Inline::Perl6 in Perl 5.
This functionality is aimed at supporting Perl 5 frameworks (think Catalyst
or DBIx::Class or Dancer or ...) that automatically load modules and of course
expect these modules to be written in Perl 5.

# BUILDING

The oldest rakudo version supported is 2019.03.1.
The oldest perl version supported is 5.20.0.

[Jan 2022: MacOS on M1 does not build.](https://github.com/niner/Inline-Perl5/issues/171#issuecomment-1007905126)

You will need a perl 5 built with the -fPIC option (position independent
code). Most distributions build their Perl 5 that way. When you use perlbrew,
you have to build it as:

    perlbrew install perl-stable -Duseshrplib

(or, if you want to use more than one Inline::Perl5 interpeter safely, for
instance from within Raku threads, add the `-Dusemultiplicity` option as well)

If you use plenv:

    plenv install 5.24.0 -Duseshrplib

If you use the perl that comes with a Linux distribution, you may need to
install a separate package containing the perl library. Consult the table below
or the distribution documentation for details.

| Distribution             | Package name |
| -------------------------|--------------|
| Fedora/Red Hat/CentOs    | perl-libs    |
| Debian/Ubuntu/Linux Mint | libperl-dev  |
| openSUSE                 | perl         |
| Arch Linux/Manjaro       | perl         |

Build Inline::Perl5 with

    raku configure.pl6
    make

and test with

    make test

and install with

    make install

# AUTHOR

Stefan Seifert <nine@detonation.org>
