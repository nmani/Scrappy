#!/usr/bin/perl

use strict;
use warnings;

use Scrappy;
our $spidy = Scrappy->new;

    $spidy->crawl('http://search.cpan.org/recent', {
        '#cpansearch li a' => sub {
            print shift->text, "\n";
        }
    });