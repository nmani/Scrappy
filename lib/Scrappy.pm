# ABSTRACT: Simple Stupid Spider base on Web::Scraper inspired by Dancer

use strict;
use warnings;

package Scrappy;
use WWW::Mechanize::Pluggable;

our $class_Instance = undef;

BEGIN {
    use Exporter();
    use vars qw( @ISA %EXPORT_TAGS @EXPORT_OK );
    @ISA    = qw( Exporter );
    @EXPORT_OK = qw(
        $class_Instance
        init
        self
        user_agent
        var
        random_ua
        form
        grab
    );
    %EXPORT_TAGS = ( syntax => [ @EXPORT_OK ] );
}

=head2 SYNOPSIS

    #!/usr/bin/perl
    use Scrappy qw/:syntax/;
    
    init;
    user_agent random_ua;
    get 'http://google.com', {
        q => ''
    };
    

=head3 DESCRIPTION

Scrappy is an easy (and hopefully fun) way of scraping, spidering, and/or
harvesting information from web pages. Internally Scrappy uses the awesome
Web::Scraper and WWW::Mechanize modules so as such Scrappy imports its
awesomeness. Scrappy is inspired by the fun and easy-to-use Dancer api. Beyond
being a pretty api for WWW::Mechanize::Plugin::Web::Scraper, Scrappy also has
the following features: automatic cookie session storage with resume.

=cut

=method init

Builds the scraper application instance.
This function should be called before issuing any other commands as this function
creates the application instance all other funciton will use. This function
returns the current scraper application instance.

    my $scraper = init;

=cut

sub init {
    $class_Instance = WWW::Mechanize::Pluggable->new();
    die 'Could not create a scraper application instance, please make sure you ' .
        'have install Scrappy and its prerequesites properly.'
        unless defined $class_Instance;
    $class_Instance->{Scrappy} = { stash => {} };
    return $class_Instance;
}

=method self

This method returns the current scraper application instance which can also be
found in the global class variable $class_Instance.

    init;
    get $requested_url;
    my $scraper = self;

=cut

sub self {
    die 'No scraper application instance found, please use the `init` method' .
        'before calling any other functions from your package or script.'
        unless defined $class_Instance;
    return $class_Instance;
}

=method user_agent

This method sets the user-agent for the current scraper application instance.

    init;
    user_agent 'Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US; rv:1.9.2.8) Gecko/20100722 Firefox/3.6.8';

=cut

sub user_agent {
    my ($requested_user_agent) = shift;
    self->add_header("User-Agent" => $requested_user_agent)
        if defined $requested_user_agent;
    return $requested_user_agent ?
        $requested_user_agent : self->{Mech}->{headers}->{'User-Agent'};
}

=method var

This method sets a stash (shared) variable or returns the entire stash object.

    var age => 31;
    print var->{age};
    # 30
    
    my @array = (1..20);
    var integers => @array;
    
    # stash variable nesting
    var 'user/profile/name' => 'Mr. Foobar';
    print var->{user}->{profile}->{name};
    # Mr. Foobar

=cut

sub var {
    my ($key, $value) = @_;
    if (@_ == 2) {
        if ($key =~ /\//) {
            $key =~ s/\/+/\//g;
            $key =~ s/(^\/)|(\/$)//g;
            my @keys = split /\//, $key;
            my $var  = self->{Scrappy}->{stash};
            for (my $i = 0; $i < @keys; $i++) {
                $var->{$keys[$i]} = (($i+1) == @keys) ? $value : {};
                $var = $var->{$keys[$i]};
            }
            return $value;
        }
        else {
            self->{Scrappy}->{stash}->{$key} = $value if (@_ == 2);
            return self->{Scrappy}->{stash}->{$key};
        }
    }
    return self->{Scrappy}->{stash};
}

=method random_ua

This returns a random user-agent string for use with the user_agent method. The
user-agent header in your request is how inquiring application determine your
browser and environment. The first argument should be the name of the web browser,
supported web browsers are any, chrome, ie or explorer, opera, safari, and firfox.
Obviously using the keyword `any` will select from any available browser. The
second argument should be the name of the desired operating system, supported
operating systems are any, windows, macintosh, linux. If arguments are specified,
the `any` keywords will be used. 

    init;
    user_agent random_ua;
    # same as random_ua 'any', 'any';
    
e.g. for a Linux-specific user-agent use the following...
    
    init;
    user_agent random_ua 'chrome', 'linux';

=cut

sub random_ua {
    my ($requested_user_agent) = shift;
    return ;
}

=method form

The form method is a shortcut to the WWW::Mechanize submit_form method. It take
the exact same arguments, yada, yada.

    init;
    get $requested_login_url;
    form fields => {
        username => 'mrmagoo',
        password => 'foobarbaz'
    };

=cut

sub form {
    self->submit_form(@_);
}

=method grab

The grab method is a shortcut to the Web::Scraper process method. It take
the exact same arguments with a little bit of our own added magic.

    init;
    get $requested_url;
    grab '#profile li a', 'text';
    # meaning you can do cool stuff like...
    # var user_name => grab '#profile li a', 'text';

=cut

sub grab {
    my ($selector, $mapping) = @_;
    my $temp = self->scrape( $selector, "data[]", $mapping );
    return $temp->{data}[1] ? $temp->{data} : $temp->{data}[0];
}

1;
