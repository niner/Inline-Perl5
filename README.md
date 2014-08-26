# TITLE

Inline::Perl5


# SYNOPSIS

```
    use Inline::Perl5;
    my $i = p5_init_perl();
    $i.run("use DBI; 1;");
    my $dbh = $i.call("connect", "DBI", "dbi:Pg:database=timemngt");
    say $dbh.call("selectrow_array", "select count(*) from products");
    $i.DESTROY;
```

# DESCRIPTION

Module for executing Perl 5 code and accessing Perl 5 modules from Perl 6.

Supports Perl 5 modules including XS modules. Allows passing integers and
strings between Perl 5 and Perl 6. Also supports calling methods on Perl 5
objects from Perl 6.

# AUTHOR

Stefan Seifert <nine@detonation.org>
