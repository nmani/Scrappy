# example script using Scrappy on http://ipswift.com/
use strict;
use warnings;

BEGIN {
    use FindBin;
    use lib $FindBin::Bin . "/../lib";
    use Scrappy qw/:syntax/;
}

init;
user_agent random_ua 'firefox';

get   'http://ipswift.com/';

if (loaded) {
    var before_ipaddr => grab 'body h2';
}

proxy 'http', 'http://93.62.4.207:9000';
get   'http://www.whatsmyip.org/';

if (loaded) {
    var after_ipaddr => grab '#ip';
}

print "ip before proxy ", var->{before_ipaddr}, "\n";
print "==========================================\n";
print "ip after proxy ",  var->{after_ipaddr},  "\n";
print "==========================================\n";
print "using ", user_agent;