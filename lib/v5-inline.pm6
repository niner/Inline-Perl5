use QAST:from<NQP>;
use Inline::Perl5;
use experimental :rakuast;

sub EXPORT(|) {
    my role Perl5Slang {
        method p5code {
            my $pos  = self.pos;
            my $p5 = Inline::Perl5.default_perl5;
            my ($remainder, $optree, $stash) = $p5.compile-to-block-end(
                    '{' ~ substr(self.target, $pos)
                );

            for $stash.pairs {
                my $name = '&' ~ $_.key;
                my $gv = $_.value;
                my $sub := sub (|args) {
                    $p5.call-gv-args($gv.gv, args)
                };
                if $*W {
                    $*PACKAGE.WHO.BIND-KEY($name, $sub);
                    my @pads := $*W.context.blocks;
                    $ = $*W.install_lexical_symbol(@pads[*-2], $name, $sub);
                }
                else {
                    $*R.current-package.WHO.BIND-KEY($name, $sub);
                    $*R.outer-scope.merge-generated-lexical-declaration(
                        RakuAST::VarDeclaration::Implicit::Constant.new(:$name, :value($sub)),
                        :resolver($*R),
                    );
                }
            }

            $remainder++;
            $*P5CODE = $optree;
            self.'!cursor_pass'(self.target.chars - $remainder);
            self
        }
        # Each frontend calls only its own spelling of the proto.
        token statement_control {
            :my $*P5CODE;
            <.p5code>
        }
        token statement-control {
            :my $*P5CODE;
            <.p5code>
        }
    }

    my Mu $MAIN-grammar := $*LANG.slang_grammar('MAIN');
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
            # RakuAST::Constant puts the optree in the serialization context
            # itself. A statement control has to hand back a statement.
            method statement-control(Mu $/) {
                my $runops = RakuAST::ApplyPostfix.new(
                    operand => RakuAST::ApplyPostfix.new(
                        operand => RakuAST::Constant.new(Inline::Perl5),
                        postfix => RakuAST::Call::Method.new(
                            name => RakuAST::Name.from-identifier('default_perl5'),
                        ),
                    ),
                    postfix => RakuAST::Call::Method.new(
                        name => RakuAST::Name.from-identifier('runops'),
                        args => RakuAST::ArgList.new(RakuAST::Constant.new($*P5CODE)),
                    ),
                );
                self.attach: $/, RakuAST::Statement::Expression.new(:expression($runops));
            }
        });

    Map.new
}
