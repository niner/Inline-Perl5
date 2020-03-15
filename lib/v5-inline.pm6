use QAST:from<NQP>;
use Inline::Perl5;

sub EXPORT(|) {
    my role Perl5Slang {
        method p5code {
            my $pos  = self.pos;
            my ($remainder, $optree) = Inline::Perl5.default_perl5.compile-to-block-end(
                    '{' ~ substr(self.target, $pos)
                );
            $remainder++;
            $*P5CODE = $optree;
            self.'!cursor_pass'(self.target.chars - $remainder);
            self
        }
        token statement_control {
            :my $*P5CODE;
            <.p5code>
        }
    }

    my Mu $MAIN-grammar := %*LANG<MAIN>;
    my $grammar := $MAIN-grammar.HOW.mixin($MAIN-grammar, Perl5Slang);

    $*LANG.define_slang(
        'MAIN',
        $grammar,
        $*LANG.actions but role :: {
            method statement_control(Mu $/) {
                my $optree = $*P5CODE;
                $*W.add_object($optree); #FIXME won't do in a precomped module
                make QAST::Op.new(
                    :op<callmethod>,
                    :name<runops>,
                    QAST::Op.new(
                        :op<callmethod>,
                        :name<default_perl5>,
                        QAST::WVal.new(:value(Inline::Perl5)),
                    ),
                    QAST::WVal.new(:value($optree))
                );
            }
        });

    Map.new
}
