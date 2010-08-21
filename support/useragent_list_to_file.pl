use strict;
use WWW::Mechanize::Pluggable;

# Usage: perl utility_useragent_list_to_file.pl [browser]

my $browser = $ARGV[0];

my $mech = WWW::Mechanize::Pluggable->new();
   $mech->get("http://www.useragentstring.com/pages/$browser/");

my @ua_strings = ();
my $results = $mech->scrape( "#liste li a", "results[]",
    { title => "TEXT", url => '@href' } );

foreach my $results (@{$results->{results}}) {
    push @ua_strings, $results->{title};
}

open out, ">$browser.txt" || die $!;
print out join "\n", @ua_strings;
close out;