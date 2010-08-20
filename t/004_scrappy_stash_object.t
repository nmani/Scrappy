use strict;
use warnings;
use Test::More tests => 8;
use Scrappy qw/:syntax/;

init;

ok(!var->{foo}, 'no stash object exists yet');
ok(var(foo => 123456789), 'stash var foo set');
ok(var->{foo}, 'stash var foo retreived');

var numbers => [(1..9)];
ok(ref(var->{numbers}) eq "ARRAY", 'arrayref stored in stash');
ok(var->{numbers}->[8] eq 9, 'numbers arrayref retreived properly');

var numbers => (1..9);
ok(ref(var->{numbers}) eq "ARRAY", 'numbers arrayref overwritten');

var 'foo/bar' => 'abc';
ok(var->{foo}->{bar} eq 'abc', 'variable nesting working');

var '//zoo//zaz\\' => 'def';
ok(var->{zoo}->{'zaz\\'} eq 'def', 'bad variable nesting fixed');