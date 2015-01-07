# TITLE

Inline::Perl5

# SYNOPSIS

```
    use Inline::Perl5;
    my $p5 = Inline::Perl5.new();
    $p5.use('DBI');
    my $dbh = $p5.invoke('DBI', 'connect', 'dbi:Pg:database=test');
    my $products = $dbh.selectall_arrayref(
    	'select * from products', {Slice => {}}
    );
```

# DESCRIPTION

Module for executing Perl 5 code and accessing Perl 5 modules from Perl 6.

Supports Perl 5 modules including XS modules. Allows passing integers,
strings, arrays and hashes between Perl 5 and Perl 6. Also supports calling
methods on Perl 5 objects from Perl 6 and calling methods on Perl 6 objects
from Perl 5.

# HOW DO I?

## Load a Perl 5 module

Inline::Perl5's use() method maps to Perl 5's use statement:

```
    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;
    $p5.use('Test::More');
```

## Call a Perl 5 function

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

## Create a Perl 5 object

Creating Perl 5 objects works just the same as in Perl 5: invoke their
constructor (usually called "new").

```
    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;
    $p5.use('Data::Dumper');
    my $dumper = $p5.invoke('Data::Dumper', 'new');
```

## Invoke a method on a Perl 5 object

Once you have a Perl 5 object in a variable it will behave just like a Perl 6
object.  You can call methods on it like on any other object.

```
    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;
    $p5.use('IO::Compress::Bzip2');
    my $bzip2 = $p5.invoke('IO::Compress::Bzip2', 'new', '/tmp/foo.bz2');
    $bzip2.print($data);
    $bzip2.close;
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

## Run arbitrary Perl 5 code

Arbitrary Perl 5 code can be executed using Inline::Perl5's run($str) method.
It accepts Perl 5 code as a string.

```
    use Inline::Perl5;
    my $p5 = Inline::Perl5.new;

    $p5.run(q'
        sub test {
            return 'Hello from Perl 5';
        }
    ');
```

## Inherit from a Perl 5 class

The Inline::Perl5::Perl5Parent role allows convenient subclassing of Perl 5
packages in Perl 6. Pass the Perl 5 package's name as parameter to the role.
Pass the Inline::Perl5 object as named parameter to your classes constructor
when creating objects.

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

# BUILDING

You will need a perl 5 build with the -fPIC option (position independent
code). Most distributions build their Perl 5 that way. When you use perlbrew,
you have to build it as:

    perlbrew install perl-5.20.0 -Duseshrplib

(or, if you want to use more than one Inline::Perl5 interpeter safely, for instance from within Perl 6 threads, add the `-Dusemultiplicity` option as well)

and then build Inline::Perl5 with

    make

and test with

    make test


# AUTHOR

Stefan Seifert <nine@detonation.org>
