# example script using Scrappy on search.cpan.org
use strict;
use warnings;

BEGIN {
    use FindBin;
    use lib $FindBin::Bin . "/../lib";
    use Scrappy qw/:syntax/;
}

init;
user_agent random_ua 'firefox';

get 'http://search.cpan.org/recent';

if (loaded) {
    var date    => grab '.datecell b';
    var modules => grab '#cpansearch li a', { name => 'TEXT', link => '@href' };
}

print $_->{name} , "\n" for @{ var->{modules} };
print "====================\n";
print "on ", var->{date}, "\n";
print "using ", user_agent;