# example script using Scrappy on search.cpan.org
use strict;
use warnings;
use lib "../lib";
use Scrappy qw/:syntax/;

# author pages
user_agent random_ua 'firefox';
push our @authors, map { "http://search.cpan.org/author/?$_" } ('A'..'Z');

crawl @authors, {
    'table a' => sub {
        my $link = shift;
        queue $link->href if
        $link->href =~ /search\.cpan\.org\/~/;
    }
};