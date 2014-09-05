# TITLE

Inline::Perl5


# SYNOPSIS

```
    use Inline::Perl5;
    my $i = Inline::Perl5.new();
    $i.run('use DBI; 1;');
    my $dbh = $i.call('connect', 'DBI', 'dbi:Pg:database=timemngt');
    say $dbh.selectall_arrayref('select * from products', {Slice => {}}).perl;
    $i.DESTROY;
```

# DESCRIPTION

Module for executing Perl 5 code and accessing Perl 5 modules from Perl 6.

Supports Perl 5 modules including XS modules. Allows passing integers,
strings, arrays and hashes between Perl 5 and Perl 6. Also supports calling
methods on Perl 5 objects from Perl 6 and calling methods on Perl 6 objects
from Perl 5.

# BUILDING

You will need a perl 5 build with the -fPIC option (position independent
code). Most distributions build their Perl 5 that way. When you use perlbrew,
you have to build it as:

    perlbrew install perl-5.20.0 -Duseshrplib

and then build Inline::Perl5 with

    make

and test with

    make test


# AUTHOR

Stefan Seifert <nine@detonation.org>
