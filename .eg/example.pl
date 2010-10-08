#!/usr/bin/perl

use strict;
use warnings;

use Scrappy;
our $spidy = Scrappy->new;
    
    $spidy->crawl('http://search.cpan.org/recent', {
        'a' => sub {
            my $link = shift;
            $spidy->queue($link->href) if
            $spidy->match('/~:author/:dist/', $link->href);
        },
        '/~:author/:dist/' => {
            'body', sub {
                print "Howdy, I'm looking at " . $spidy->param('author') . "\n";
            },
        }
    });