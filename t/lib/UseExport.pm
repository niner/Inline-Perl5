unit module UseExport;

use Test;
use Encode:from<Perl5> <encode>;

is encode('utf8', 'foo'), 'foo';
