package Foo::Bar::TestV6;

sub new {
    return bless {};
}

use v6-inline;

has $.name;

submethod BUILD(:$!name) { }

our sub greet($me) {
    return "hello $me";
}

method hello {
    return "hello $.name";
}
