package Foo::Bar::TestV6;
use v6-inline;

has $.name;

our sub greet($me) {
    return "hello $me";
}

method hello {
    return "hello $.name";
}
