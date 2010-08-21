use strict;
use warnings;
use Test::More tests => 12;
use Scrappy qw/:syntax/;

init;
ok random_ua; #1
ok random_ua 'chrome'; #2
ok random_ua 'firefox';#3
ok random_ua 'ie';#4
ok random_ua 'explorer';#5

eval { random_ua 'internet'; };
ok $@;#6

ok random_ua 'any', 'windows';#7

eval { random_ua 'chrome', 'win'; }; 
ok $@;#8

eval { random_ua 'firefox', 'bsd'; }; 
ok $@;#9

eval { random_ua 'FireFox', 'LINUX'; }; 
ok !$@;#10

eval { random_ua 'chromwewre', 'win'; };
ok $@;#11

eval { random_ua 'IE', 'LIN'; };
ok $@;#12