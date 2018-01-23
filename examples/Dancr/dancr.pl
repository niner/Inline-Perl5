use v6.c;

use Dancer2:from<Perl5>;
use DBI:from<Perl5>;
use Template:from<Perl5>;
 
set 'database'     => $*TMPDIR.child('dancr.db');
set 'session'      => 'Simple';
set 'template'     => 'template_toolkit';
set 'logger'       => 'console';
set 'log'          => 'debug';
set 'show_errors'  => 1;
set 'startup_info' => 1;
set 'warnings'     => 1;
set 'username'     => 'admin';
set 'password'     => 'password';
set 'layout'       => 'main';
 
my $flash;
 
sub set_flash($message) {
    $flash = $message;
}
 
sub get_flash() {
 
    my $msg = $flash;
    $flash = "";
 
    return $msg;
}
 
sub connect_db() {
    my $dbh = DBI.connect("dbi:SQLite:dbname={setting('database')}", Any, Any, ${sqlite_unicode => 1}) or
        die %*PERL5<$DBI::errstr>;
 
    return $dbh;
}
 
sub init_db() {
    my $db = connect_db();
    my $schema = slurp 'schema.sql';
    $db.do($schema) or die $db.errstr;
}
 
#hook before_template_render => sub (%tokens) {
#    %tokens<css_url> = request.base ~ 'css/style.css';
#    %tokens<login_url> = uri_for('/login');
#    %tokens<logout_url> = uri_for('/logout');
#};
use MONKEY-SEE-NO-EVAL;
my &hash-filler = EVAL q:to/PERL5/, :lang<Perl5>;
    sub {
        my ($source) = @_;
        return sub {
            my ($target) = @_;
            my $data = $source->();
            $target->{$_} = $data->{$_} foreach keys (%$data);
        }
    }
    PERL5
hook before_template_render => hash-filler({ ${
        css_url => request.base ~ 'css/style.css',
        login_url => uri_for('/login'),
        logout_url => uri_for('/logout'),
    } });
 
get '/' => {
    my $db = connect_db();
    my $sql = 'select id, title, text from entries order by id desc';
    my $sth = $db.prepare($sql) or die $db.errstr;
    $sth.execute or die $sth.errstr;
    template 'show_entries.tt', ${
        'msg' => get_flash(),
        'add_entry_url' => uri_for('/add'),
        'entries' => $sth.fetchall_hashref('id'),
    };
};
 
post '/add' => {
    unless session('logged_in') {
        send_error("Not logged in", 401);
    }
 
    my $db = connect_db();
    my $sql = 'insert into entries (title, text) values (?, ?)';
    my $sth = $db.prepare($sql) or die $db.errstr;
    $sth.execute(body_parameters.get('title'), body_parameters.get('text'))
        or die $sth.errstr;
 
    set_flash('New entry posted!');
    redirect '/';
};
 
any $['get', 'post'], '/login', sub (*@a) {
    my $err;
 
    if ( request.method eq "POST" ) {
        # process form input
        if body_parameters.get('username') ne setting('username') {
            $err = "Invalid username";
        }
        elsif body_parameters.get('password') ne setting('password') {
            $err = "Invalid password";
        }
        else {
            session 'logged_in' => true;
            set_flash('You are logged in.');
            return redirect '/';
        }
   }
 
   # display login form
   template 'login.tt', ${
       'err' => $err,
   };
 
};
 
get '/logout' => {
   app.destroy_session;
   set_flash('You are logged out.');
   redirect '/';
};
 
init_db();
start;

# vim: ft=perl6
