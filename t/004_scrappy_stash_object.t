use strict;
use warnings;
use Test::More tests => 8;
use Scrappy qw/:syntax/;

init;

ok(!var->{foo}, 'no stash object exists yet');#1
ok(var(foo => 123456789), 'stash var foo set');#2
ok(var->{foo}, 'stash var foo retreived');#3

var numbers => [(1..9)];
ok(ref(var->{numbers}) eq "ARRAY", 'arrayref stored in stash');#4
ok(var->{numbers}->[8] eq 9, 'numbers arrayref retreived properly');#5

var numbers => (1..9);
ok(ref(var->{numbers}) eq "ARRAY", 'numbers arrayref overwritten');#6

var 'poo/bar' => 'abc';
ok(var->{poo}->{bar} eq 'abc', 'variable nesting working');#7

var '//zoo//zaz\\' => 'def';
ok(var->{zoo}->{'zaz\\'} eq 'def', 'bad variable nesting fixed');#8