#!/usr/bin/env perl6

use v6;
use Inline::Perl5;
use Test;

my $p5 = Inline::Perl5.new();
$p5.run(q:heredoc/PERL5/);
    sub test_can_positive {
        my ($p6obj) = @_;
        return $p6obj->can('foo');
    }
    sub test_can_negative {
        my ($p6obj) = @_;
        return $p6obj->can('bar');
    }
    sub call_foo_via_can {
        my ($p6obj) = @_;
        return $p6obj->can('foo')->($p6obj);
    }
    sub can_on_perl6_object_package {
        my ($name) = @_;
        return Perl6::Object->can($name);
    }
    package Bar {
        sub new {
            return bless {}, 'Bar';
        }
        sub test {
            return 1;
        }
    };
PERL5

class Foo {
    method foo {
        return 'foo';
    }
}

my $foo = Foo.new;
ok($p5.call('test_can_positive', $foo));
ok(not $p5.call('test_can_negative', $foo));
is($p5.call('call_foo_via_can', $foo), 'foo');
ok(not $p5.call('can_on_perl6_object_package', 'can'));
ok(not $p5.call('can_on_perl6_object_package', 'non_existing'));

# .can on a Perl5Object
my $bar = $p5.invoke('Bar', 'new');
ok($bar.can('test'));
ok($bar.can('sink'));
ok($bar.can('Str'));
ok($bar.can('Str')[0]($bar));
is($bar.can('test')[0]($bar), 1);
is($bar.can('not_existing').elems, 0);

done-testing;

# vim: ft=perl6
