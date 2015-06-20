use lib 'lib', 'blib/lib';
use Inline::Perl5;
#use Test::More:from<Perl5>;
#Inline::Perl5.new.require('Test::More');
note "Inline::Perl5.new";
Inline::Perl5.new;

class Precomp::First { }
