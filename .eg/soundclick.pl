#!/usr/bin/perl

use strict;
use warnings;
use lib 'C:\Git Files\alnewkirk.com\public\code.scrappy\lib';

use Scrappy;
our $spidy = Scrappy->new;
our @pages = (
    'http://www.soundclick.com/bands/default.cfm?bandID=1052190&content=music&songcount=39&offset=0&currentPage=1',
    'http://www.soundclick.com/bands/default.cfm?bandID=1052190&content=music&songcount=39&offset=0&currentPage=2',
    );

    $spidy->crawl(@pages, {
        '/bands/default.cfm' => {
            '.songsBox div div a.songtitle', sub {
                print shift->text, "\n";
            },
        }
    });