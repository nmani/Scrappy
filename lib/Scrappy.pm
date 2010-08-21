# ABSTRACT: Simple Stupid Spider base on Web::Scraper inspired by Dancer

use strict;
use warnings;

package Scrappy;
use WWW::Mechanize::Pluggable;
use File::ShareDir ':ALL';
use File::Slurp;

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
        get
        post
        grab
        loaded
        status
        reload
        back
        page
        response
        content_type
        domain
        ishtml
        title
        text
        html
        data
        www
        store
        download
        list
        fst
        lst
    );
    %EXPORT_TAGS = ( syntax => [ @EXPORT_OK ] );
}

=head1 SYNOPSIS

    #!/usr/bin/perl
    use Scrappy qw/:syntax/;
    
    init;
    user_agent random_ua;
    get 'http://google.com';
    
    form fields => {
        q => "what is perl"
    };
    
    var 'results' =>
        grab '#search li h3 a', { name => 'TEXT', link => '@href' };
    

=head1 DESCRIPTION

Scrappy is an easy (and hopefully fun) way of scraping, spidering, and/or
harvesting information from web pages. Internally Scrappy uses the awesome
Web::Scraper and WWW::Mechanize modules so as such Scrappy imports its
awesomeness. Scrappy is inspired by the fun and easy-to-use Dancer API. Beyond
being a pretty API for WWW::Mechanize::Plugin::Web::Scraper, Scrappy also has
the persistant cookie handling, session handling, and more.

Scrappy == 'Scraper Happy' or 'Happy Scraper'; If you like you may call it
Scrapy although Python has a web scraping framework by that name and we don't
plagiarize Python code here.

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
                $var->{$keys[$i]} = $value
                    if ($i+1) == @keys;
                $var->{$keys[$i]} = {}
                    if ($i+1) != @keys && ! defined $var->{$keys[$i]};
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
second argument which is optional should be the name of the desired operating
system, supported operating systems are windows, macintosh, linux. 

    init;
    user_agent random_ua;
    # same as random_ua 'any';
    
e.g. for a Linux-specific user-agent use the following...
    
    init;
    user_agent random_ua 'chrome', 'linux';

=cut

sub random_ua {
    my ($browser, $os) = @_;
       $browser = lc $browser;
       $browser = 'any' unless $browser;
       $browser = 'explorer'
            if lc($browser) eq 'internet explorer' ||
               lc($browser) eq 'explorer' ||
               lc($browser) eq 'ie';
    my @browsers = (
        'explorer',
        'chrome',
        'firefox',
        'opera',
        'safari'
    );
    my @oss = (
        'Windows',
        'Linux',
        'Macintosh'
    );
    if ($browser ne 'any') {
        die "Can't load user-agents from unrecognized browser `$browser`" unless
            grep /^$browser$/, @browsers;
    }
        
    if ($os) {
        $os = ucfirst(lc($os));
        die "Can't filter user-agents with an unrecognized Os `$os`" unless
            grep /^$os$/, @oss;
    }
    
    my @selection = ();
    
    if ($browser eq 'any') {
        if (var->{'user-agents'}->{any}) {
            @selection = @{var->{'user-agents'}->{any}};
        }
        else {
            foreach my $file (@browsers) {
                my $u = dist_dir('Scrappy') . "/support/$file.txt";
                   $u = "share/support/$file.txt" unless -e $u;
                push @selection, read_file($u);
            }
            var "user-agents/any" => @selection;
        }
    }
    else {
        if (var->{'user-agents'}->{$browser}) {
            @selection = @{var->{'user-agents'}->{$browser}};
        }
        else {
            my $u = dist_dir('Scrappy') . "/support/$browser.txt";
               $u = "share/support/$browser.txt" unless -e $u;
            push @selection, read_file($u);
            var "user-agents/$browser" => @selection;
        }
    }
    
    @selection = grep /$os/, @selection if $os;
    
    return $selection[rand(@selection)];
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
    return self->submit_form(@_);
}

=method get

The get method is a shortcut to the WWW:Mechanize get method. This
method takes a URL or URI and returns an HTTP::Response object.

=cut

sub get {
    return self->get(@_);
}

=method post

The post method is a shortcut to the WWW:Mechanize post method. This
method takes a URL or URI and a hashref of key/value pairs then returns an
HTTP::Response object. Alternatively the post object can be used traditionally
(ugly), and passed additional arguments;

    # our pretty way
    post $requested_url, {
        query => 'some such stuff'
    };
    
    # traditionally
    post $requested_url,
        'Content-Type' => 'multipart/form-data',
        'Content'      => {
            user                => $facebook->{user},
            profile_id          => $prospect->{i},
            message             => '',
            source              => '',
            src                 => 'top_bar',
            submit              => 1,
            post_form_id        => $post_formid,
            fb_dtsg             => 'u9MeI',
            post_form_id_source => 'AsyncRequest'
        };

Note! Our prettier version of the post method use a content-type of
application/x-www-form-urlencoded by default, to use multipart/form-data,
please use the traditional style, sorry.

=cut

sub post {
    my ($url, $params) = @_;
    if ($url && ref($params) eq "HASH") {
        self->post(
            $url,
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Content'      => $params
        );
    }
    else {
        return self->post(@_);
    }
}

=method grab

The grab method is a shortcut to the Web::Scraper process method. It take
the exact same arguments with a little bit of our own added magic.

    init;
    get $requested_url;
    grab '#profile li a';
    
    # meaning you can do cool stuff like...
    var user_name => grab '#profile li a';
    
    # the traditional use is to provide a selector and mappings ..., e.g.
    grab '#profile li', { name => 'TEXT', link => '@href' };

=cut

sub grab {
    my ($selector, $mapping) = @_;
    if ($mapping) {
        my $temp = self->scrape( $selector, "data[]", $mapping );
        return $temp->{data};
    }
    else {
        my $temp = self->scrape( $selector, "data[]", { everything => 'TEXT' } );
        return $temp->{data}[0]->{everything};
    }
}

=method loaded

The loaded method is a shortcut to the WWW:Mechanize success method. This
method returns true/false based on whether the last request was successful.

    init;
    get $requested_url;
    if (loaded) {
        grab ...
    }

=cut

sub loaded {
    return self->success;
}

=method status

The status method is a shortcut to the WWW:Mechanize status method. This
method returns the 3-digit HTTP status code of the response.

    init;
    get $requested_url;
    if (status == 200) {
        grab ...
    }

=cut

sub status {
    return self->status;
}

=method reload

The reload method is a shortcut to the WWW:Mechanize reload method. This
method acts like the reload button in a browser, repeats the current request.

=cut

sub reload {
    return self->reload;
}

=method back

The back method is a shortcut to the WWW:Mechanize back method. This
method is equivalent of hitting the "back" button in a browser, it returns
the previous response (page), it will not backtrack beyond the first request.

=cut

sub back {
    return self->back;
}

=method page

The page method is a shortcut to the WWW:Mechanize uri method. This
method returns the URI of the current page.

=cut

sub page {
    return self->uri;
}

=method response

The response method is a shortcut to the WWW:Mechanize response method. This
method returns the HTTP::Repsonse object of the current page.

=cut

sub response {
    return self->response;
}

=method content_type

The content_type method is a shortcut to the WWW:Mechanize content_type method.
This method returns the content_type of the current page.

=cut

sub content_type {
    return self->content_type;
}

=method domain

The domain method is a shortcut to the WWW:Mechanize base method.
This method returns URI of the current page.

=cut

sub domain {
    return self->base;
}

=method ishtml

The ishtml method is a shortcut to the WWW:Mechanize is_html method.
This method returns true/false on whether our content is HTML, according to the
HTTP headers.

=cut

sub ishtml {
    return self->is_html;
}

=method title

The title method is a shortcut to the WWW:Mechanize title method.
This method returns the content of the title tag if the current page is HTML,
otherwise returns undef.

=cut

sub title {
    return self->title;
}

=method text

The text method is a shortcut to the WWW:Mechanize content method using
the format argument and returns a text representation of the last page having
all HTML markup stripped.

=cut

sub text {
    return data( format => 'text');
}

=method html

The html method is a shortcut to the WWW:Mechanize content method. This method
returns the content of the current page.

=cut

sub html {
    return data(@_);
}

=method data

The data method is a shortcut to the WWW:Mechanize content method. This method
returns the content of the current page. Additionally this method when passed
a single argument, updates the content of the current page with that data and
returns the modified content.

=cut

sub data {
    unless ($_[1]) {
        self->update_html($_[0]);
    }
    return self->content(@_);
}

=method www

The www method is an alias to the self method. This method
returns the current scraper application instance.

=cut

sub www {
    return self(@_);
}

=method store

The store method is a shortcut to the WWW:Mechanize save_content method.
This method returns dumps the contents of the current page into the specified
file. If the content-type does not begin with 'text', the content is saved as
binary data. If the store method is passed a URI and a File Path, then it will
follow the link, store the contents in the file and return to the previous page.

=cut

sub store {
    if (@_==2) {
        get $_[0];
        store $_[1];
        back;
    }
    else {
        return self->save_content(@_);
    }
}

=method download

The download method is an alias to the store method.

=cut

sub download {
    return store(@_);
}

=method list

The list method is an aesthetically pleasing method of dereferencing an
arrayref. This method dies if the argument is not an arrayref.

    foreach my $item (list var->{items}) {
        ...
    }

=cut

sub list {
    die 'The argument passed to the list method must be an arrayref'
        if ref($_[0]) ne "ARRAY";
    return @{$_[0]};
}

=method fst

The fst (first) method shifts the passed in arrayref returning the first element
in the array shortening it by one.

    var foo => fst grab '.class', { name => 'TEXT' };

=cut

sub fst {
    my @array = list @_;
    return shift @array;
}

=method lst

The lst (last) method pops the passed in arrayref returning the last element
in the array shortening it by one.

    var foo => lst grab '.class', { name => 'TEXT' };

=cut

sub lst {
    my @array = list @_;
    return pop @array;
}

1;