use strict;
use warnings;
use Test::More tests => 6;
use Scrappy qw/:syntax/;

init;

ok(!user_agent, 'no user-agent set');

my $browser = 'Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US; rv:1.9.2.8) Gecko/20100722 Firefox/3.6.8';
my $ua = user_agent $browser;
   
ok($ua, 'user-agent returned');
ok($ua eq $browser, 'user-agent valid');
ok($ua =~ /^Mozilla.*Gecko.*Firefox.*$/, 'user-agent matches regex');
ok(self->{Mech}->{headers}->{'User-Agent'} eq $browser, 'user-agent header set');
ok(user_agent eq $browser, 'user_agent function returns string');