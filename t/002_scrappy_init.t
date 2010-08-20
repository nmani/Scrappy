use strict;
use warnings;
use Test::More tests => 6;
use Scrappy qw/:syntax/;

my $class = init;
ok($class, 'class returned');
ok(ref($class) eq "WWW::Mechanize::Pluggable", 'class validated');

my $self = self;
ok($self, 'self returned');
ok(ref($self) eq "WWW::Mechanize::Pluggable", 'self validated');

ok($class_Instance, 'special class variable exists');
ok(ref($class_Instance) eq "WWW::Mechanize::Pluggable", 'special class variable validated');