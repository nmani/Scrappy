use strict;
use warnings;
use Test::More tests => 4;
use Scrappy qw/:syntax/;

init;

var 001 =>
    zoom '<a href="/test" class="link">this is a test</a>', '.link', '@href';
ok
    var->{001} eq '/test', 'link found';
    
var 002 =>
    zoom '<a href="/test" id="123" class="link">this is a test</a>', '.link';
ok
    var->{002} eq 'this is a test', 'text found';
    
var 003 =>
    zoom '<a href="/test" id="123" class="link">this is a test</a>', 'a';
ok
    var->{003} eq 'this is a test', 'basic text results found';
    
var 004 =>
    zoom '<a href="/test_a" id="123a" class="link">this is a test</a><br>' .
         '<a href="/test_b" id="123b" class="link">this is b test</a>',
         '.link', { link => '@href', id => '@id' };
ok
    "ARRAY" eq ref var->{004}, 'zoom and return list';