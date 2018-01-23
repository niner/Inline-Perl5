use Wx:from<Perl5>;
use Wx::App:from<Perl5>;
class YTDL::App is Wx::App {
    method OnInit {
        say "***";
        return 1;
    }
}
