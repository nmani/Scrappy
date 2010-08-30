# ABSTRACT: Simple Stupid Spider base on Web::Scraper inspired by Dancer

use strict;
use warnings;

package Scrappy;
use FindBin;
use WWW::Mechanize::Pluggable;
use File::ShareDir ':ALL';
use File::Slurp;
use YAML::Syck;

our $class_Instance             = undef;
    $YAML::Syck::ImplicitTyping = 1;

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
        session
        cookies
        config
        zoom
        proxy
        pause
    );
    %EXPORT_TAGS = ( syntax => [ @EXPORT_OK ] );
}

=head1 SYNOPSIS

    #!/usr/bin/perl
    use Scrappy qw/:syntax/;
        
    init;
    user_agent random_ua;
    
    get 'http://search.cpan.org/recent';
    
    if (loaded) {
        var date    => grab '.datecell b';
        var modules => grab '#cpansearch li a', { name => 'TEXT', link => '@href' };
    }
    
    print $_->{name}, "\n" for list var->{modules};
  
=head1 DESCRIPTION

Scrappy is an easy (and hopefully fun) way of scraping, spidering, and/or
harvesting information from web pages. Internally Scrappy uses the awesome
Web::Scraper and WWW::Mechanize modules so as such Scrappy imports its
awesomeness. Scrappy is inspired by the fun and easy-to-use Dancer API. Beyond
being a pretty API for WWW::Mechanize::Plugin::Web::Scraper, Scrappy also has its
own featuer-set which makes web scraping easier and more enjoyable.

Scrappy (pronounced Scrap+Pee) == 'Scraper Happy' or 'Happy Scraper'; If you
like you may call it Scrapy (pronounced Scrape+Pee) although Python has a web
scraping framework by that name and this module is not a port of that one.

=cut

=method init

Builds the scraper application instance. This function should be called before
issuing any other commands as this function creates the application instance all
other functions will use. This function returns the current scraper application
instance.

    my $scraper = init;

=cut

sub init {
    $class_Instance = WWW::Mechanize::Pluggable->new(@_);
    die 'Could not create a scraper application instance, please make sure you ' .
        'have install Scrappy and its prerequesites properly.'
        unless defined $class_Instance;
    
    $class_Instance->{Scrappy}       = { stash => {} };
    $class_Instance->{Mech}->{pause} = 0;
    return $class_Instance;
}

=method self

This method returns the current scraper application instance which can also be
found in the package class variable $class_Instance.

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

This method gets/sets the user-agent for the current scraper application instance.

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

This method sets a stash (shared) variable or returns a reference to the entire
stash object.

    var age => 31;
    print var->{age};
    # 31
    
    my @array = (1..20);
    var integers => @array;
    
    var->{foo}->{bar} = 'baz';
    
    # stash variable nesting ** depreciated ** not recommended **
    var 'user/profile/name' => 'Mr. Foobar';
    print var->{user}->{profile}->{name};

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
user-agent header in your request is how an inquiring application might determine
the browser and environment making the request. The first argument should be the
name of the web browser, supported web browsers are any, chrome, ie or explorer,
opera, safari, and firfox. Obviously using the keyword `any` will select from
any available browser. The second argument which is optional should be the name
of the desired operating system, supported operating systems are windows,
macintosh, and linux. 

    init;
    user_agent random_ua;
    # same as random_ua 'any';
    
e.g. for a Linux-specific Google Chrome user-agent use the following...
    
    init;
    user_agent random_ua 'chrome', 'linux';

=cut

sub random_ua {
    my ($browser, $os) = @_;
       $browser = 'any' unless $browser;
       $browser = 'explorer' if
               lc($browser) eq 'internet explorer' ||
               lc($browser) eq 'explorer' ||
               lc($browser) eq 'ie';
       $browser = lc $browser;
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
    
    # or more specifically
    
    form form_number => 1, fields => {
        username => 'mrmagoo',
        password => 'foobarbaz'
    };

=cut

sub form {
    my $response = self->submit_form(@_);
    sleep pause();
    return $response;
}

=method get

The get method is a shortcut to the WWW::Mechanize get method. This
method takes a URL or URI and returns an HTTP::Response object.

=cut

sub get {
    my $request = self->get(@_);
    self->{Mech}->{cookie_jar}->scan(\&_cookies_to_session);
    sleep pause();
    return $request;
}

=method post

The post method is a shortcut to the WWW::Mechanize post method. This
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

Note! Our prettier version of the post method uses a content-type of
application/x-www-form-urlencoded by default, to use multipart/form-data,
please use the traditional style, sorry.

=cut

sub post {
    my ($url, $params) = @_;
    if ($url && ref($params) eq "HASH") {
        my $request =
        self->post(
            $url,
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Content'      => $params
        );
        self->{Mech}->{cookie_jar}->scan(\&_cookies_to_session);
        sleep pause();
        return $request;
    }
    else {
        my $request = self->post(@_);
        self->{Mech}->{cookie_jar}->scan(\&_cookies_to_session);
        sleep pause();
        return $request;
    }
}

=method grab

The grab method is a shortcut to the Web::Scraper process method. It take
the exact same arguments with a little bit of our own added magic, namely you
can grab and return single-selections and even specify the return values, by
default the return value of a single-selection is TEXT. Note! Use a hashref
mapping to return a list of results, this may change in the future.

    init;
    get $requested_url;
    grab '#profile li a'; # single-selection
    grab '#profile li a', '@href'; # specifically returning href attribute
    
    # meaning you can do cool stuff like...
    var user_name => grab '#profile li a';
    
    # the traditional use is to provide a selector and mappings/return values e.g.
    grab '#profile li a', { name => 'TEXT', link => '@href' };

=cut

sub grab {
    my ($selector, $mapping) = @_;
    if ($mapping) {
        if ("HASH" eq ref $mapping) {
            my $temp = self->scrape( $selector, "data[]", $mapping );
            return $temp->{data};
        }
        else {
            my $temp = self->scrape( $selector, "data[]", { selected => $mapping } );
            return $temp->{data}[0]->{selected};
        }
    }
    else {
        my $temp = self->scrape( $selector, "data[]", { everything => 'TEXT' } );
        return $temp->{data}[0]->{everything};
    }
}

=method zoom

The zoom method is almost exactly the same as the Scrappy grab method except
that you specify what data to scrape as opposed to the grab method that parses
the entire page. This is more of a drill-down utility. Note! Use a hashref
mapping to return a list of results, this may change in the future.

    init;
    get $requested_url;
    
    var items => grab '#find ul li', { id => '@id', content => 'HTML' };
    
    foreach my $el (list var->{items}) {
        var->{$el->{id}}->{title} => zoom $el->{content}, '.title';
    }
    
    # just a silly example but zoom has many very good uses
    # it is more of a drill-down utility

=cut

sub zoom {
    my ($html, $selector, $mapping) = @_;
    
    die "The zoom function needs html and a selector at least to function properly"
        unless @_ >= 2;
        
    if ($mapping) {
        if ("HASH" eq ref $mapping) {
            my $scraper =
                WWW::Mechanize::Plugin::Web::Scraper::scraper {
                    WWW::Mechanize::Plugin::Web::Scraper::process
                        ($selector, "data[]", $mapping) };
            my $temp = $scraper->scrape( $html );
            return $temp->{data};
        }
        else {
            my $scraper =
                WWW::Mechanize::Plugin::Web::Scraper::scraper {
                    WWW::Mechanize::Plugin::Web::Scraper::process
                        ($selector, "data[]", { selected => $mapping }) };
            my $temp = $scraper->scrape( $html );
            return $temp->{data}[0]->{selected};
        }
    }
    else {
        my $scraper =
                WWW::Mechanize::Plugin::Web::Scraper::scraper {
                    WWW::Mechanize::Plugin::Web::Scraper::process
                        ($selector, "data[]", { everything => 'TEXT' }) };
        my $temp = $scraper->scrape( $html );
        return $temp->{data}[0]->{everything};
    }
}

=method loaded

The loaded method is a shortcut to the WWW::Mechanize success method. This
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

The status method is a shortcut to the WWW::Mechanize status method. This
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

The reload method is a shortcut to the WWW::Mechanize reload method. This
method acts like the refresh button in a browser, repeats the current request.

=cut

sub reload {
    my $response = self->reload;
    sleep pause();
    return $response;
}

=method back

The back method is a shortcut to the WWW::Mechanize back method. This
method is the equivalent of hitting the "back" button in a browser, it returns
the previous page (response), it will not backtrack beyond the first request.

=cut

sub back {
    my $response = self->back;
    sleep pause();
    return $response;
}

=method page

The page method is a shortcut to the WWW::Mechanize uri method. This
method returns the URI of the current page as a URI object.

=cut

sub page {
    return self->uri;
}

=method response

The response method is a shortcut to the WWW::Mechanize response method. This
method returns the HTTP::Repsonse object of the current page.

=cut

sub response {
    return self->response;
}

=method content_type

The content_type method is a shortcut to the WWW::Mechanize content_type method.
This method returns the content_type of the current page.

=cut

sub content_type {
    return self->content_type;
}

=method domain

The domain method is a shortcut to the WWW::Mechanize base method.
This method returns URI host of the current page.

=cut

sub domain {
    return self->base;
}

=method ishtml

The ishtml method is a shortcut to the WWW::Mechanize is_html method.
This method returns true/false based on whether our content is HTML, according
to the HTTP headers.

=cut

sub ishtml {
    return self->is_html;
}

=method title

The title method is a shortcut to the WWW::Mechanize title method.
This method returns the content of the title tag if the current page is HTML,
otherwise returns undef.

=cut

sub title {
    return self->title;
}

=method text

The text method is a shortcut to the WWW::Mechanize content method using
the format argument and returns a text representation of the last page having
all HTML markup stripped.

=cut

sub text {
    return data( format => 'text');
}

=method html

The html method is a shortcut to the WWW::Mechanize content method. This method
returns the content of the current page.

=cut

sub html {
    return data(@_);
}

=method data

The data method is a shortcut to the WWW::Mechanize content method. This method
returns the content of the current page. Additionally this method when passed
data, updates the content of the current page with that data and
returns the modified content.

=cut

sub data {
    if ($_[0]) {
        unless ($_[1]) {
            self->update_html($_[0]);
        }
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

The store method is a shortcut to the WWW::Mechanize save_content method. This
method stores the contents of the current page into the specified file. If the
content-type does not begin with 'text', the content is saved as binary data.

    get $requested_url;
    store '/tmp/foo.html';

=cut

sub store {
    return self->save_content(@_);
}

=method download

The download method is passed a URI, a Download Directory Path and a optionally
a File Path, then it will follow the link and store the response contents into
the specified file without leaving the current page. Basically it downloads the
contents of the request (especially when the request pushes a file download). If
a File Path is not specified, Scrappy will attempt to name the file automatically
resorting to a random 6-charater string only if all else fails.

    download $requested_url, '/tmp';
    
    # supply your own file name
    download $requested_url, '/tmp', 'somefile.txt';

=cut

sub download {
    my ($uri, $dir, $file) = @_;
    $dir =~ s/[\\\/]+$//;
     if (@_ == 3) {
        get $uri;
        Scrappy::store($dir . '/' . $file);
        back;
    }
    elsif(@_ == 2) {
        get $uri;
        my @chars = ('a'..'z', 'A'..'Z', 0..9);
        my $filename = self->{Mech}->response->filename;
           $filename = $chars[rand(@chars)] . $chars[rand(@chars)] .
                       $chars[rand(@chars)] . $chars[rand(@chars)] .
                       $chars[rand(@chars)] . $chars[rand(@chars)]
                       unless $filename;
        Scrappy::store($dir . '/' . $filename);
        back;
    }
    else {
        die "To download data from a URI you must supply at least a valid URI " .
            "and download directory path";
    }
}

=method list

The list method is an aesthetically pleasing method of dereferencing an
arrayref. This is useful when iterating over a scraped resultset. This method
no longer dies if the argument is not an arrayref and instead returns an empty list.

    foreach my $item (list var->{items}) {
        ...
    }

=cut

sub list {
    #die 'The argument passed to the list method must be an arrayref'
    #    if ref($_[0]) ne "ARRAY";
    return ref($_[0]) ne "ARRAY" ? () : @{$_[0]};
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

=method session

The session method provides a means for storing important data across executions.
There is one special session variable `_file` whose value is used to define the
file where session data will be stored. Please make sure the session file exists
and is writable. As I am sure you've deduced from the example, the session file
will be stored as YAML code. Cookies are automatically stored in and retrieved
from your session file automatically.

    init;
    session _file => '/tmp/foo_session.yml';
    session foo => 'bar';
    my $var = session->{foo};
    # $var == 'bar'
    
Please make sure to create a valid session file, use the following as an example
and note that there is a newline on the alst line of the file:

    # scrappy session file
    ---
    

=cut

sub session {
    if (@_ == 2) {
        my ($key, $value) = @_;
        if ($key eq "_file" && defined $value) {
            # load session file
            die "Session file `$value` does not exist or is not read/writable"
                unless -e $value && -w $value && -r $value;
            var 'session' => LoadFile($value);
            # attempt to reload cookies from previous session
            if (var->{'session'}) {
                if (keys %{var->{'session'}->{'cookies'}}) {
                    if (ref(self->{Mech}->{cookie_jar}) eq "HTTP::Cookies") {
                        foreach my $domain (keys %{var->{'session'}->{'cookies'}}) {
                            foreach my $key (keys %{var->{'session'}->{'cookies'}->{$domain}}) {
                                self->{Mech}->{cookie_jar}->set_cookie(
                                    var->{'session'}->{'cookies'}->{$domain}->{$key}->{version},
                                    var->{'session'}->{'cookies'}->{$domain}->{$key}->{key},
                                    var->{'session'}->{'cookies'}->{$domain}->{$key}->{val},
                                    var->{'session'}->{'cookies'}->{$domain}->{$key}->{path},
                                    var->{'session'}->{'cookies'}->{$domain}->{$key}->{domain},
                                    var->{'session'}->{'cookies'}->{$domain}->{$key}->{port},
                                    var->{'session'}->{'cookies'}->{$domain}->{$key}->{path_spec},
                                    var->{'session'}->{'cookies'}->{$domain}->{$key}->{secure},
                                    var->{'session'}->{'cookies'}->{$domain}->{$key}->{maxage},
                                    var->{'session'}->{'cookies'}->{$domain}->{$key}->{discard},
                                    var->{'session'}->{'cookies'}->{$domain}->{$key}->{hash}
                                );
                            }
                        }
                    }
                    
                }
            }
            else {
                var 'session' => {};
            }
            var 'config'  => $value;
        }
        if ($key && $value) {
            die "Please define your session file using keyword _file before creating " .
                "session variables" unless defined var->{config};
            var->{'session'}->{$key} = $value unless $key eq '_file';
            DumpFile(var->{config}, var->{'session'}) unless $key eq '_file';
        }
        return var->{'session'};
    }
    else {
        return var->{'session'};
    }
}

=method config

The config method is an alias to the Scrappy session method for readability.

=cut

sub config {
    return session @_;
}

=method cookies

The cookies method is a shortcut to the automatically generated WWW::Mechanize
cookie handler. This method returns an HTTP::Cookie object. Setting this as
undefined using the _undef keyword will prevent cookies from being stored and
subsequently read.

    init;
    get $requested_url;
    my $cookies = cookies;
    
    # prevent cookie storage
    init;
    cookies _undef;

=cut

sub cookies {
    self->{Mech}->{cookie_jar} = undef if $_[0] eq '_undef';
    return self->{Mech}->{cookie_jar};
}

# This method is called automatically whenever cookies are saved.
sub _cookies_to_session {
    my (
        $version,
        $key,
        $val,
        $path,
        $domain,
        $port,
        $path_spec,
        $secure,
        $expires,
        $discard,
        $hash
        ) = @_;
    if (var->{config}) {
        session 'cookies' => {}
            unless defined session->{'cookies'};
        session->{'cookies'}->{$domain}->{$key} = {
            version     => $version,
            key         => $key,
            val         => $val,
            path        => $path,
            domain      => $domain,
            port        => $port,
            path_spec   => $path_spec,
            secure      => $secure,
            expires     => $expires,
            discard     => $discard,
            hash        => $hash
        };
        DumpFile(var->{config}, var->{'session'});
    }
}

=method proxy

The proxy method is a shortcut to the WWW::Mechanize proxy function. This method
set the proxy for the next request to be tunneled through. Setting this as
undefined using the _undef keyword will reset the scraper application instance
so that all subsequent requests will not use a proxy.

    init;
    proxy 'http', 'http://proxy.example.com:8000/';
    get $requested_url;
    
    init;
    proxy 'http', 'ftp', 'http://proxy.example.com:8000/';
    get $requested_url;
    
    # best practice
    
    use Tiny::Try;
    
    init;
    proxy 'http', 'ftp', 'http://proxy.example.com:8000/';
    
    try {
        get $requested_url
    };
    
Note! When using a proxy to perform requests, be aware that if they fail your
program will die unless you wrap yoru code in an eval statement or use a try/catch
module. In the example above we use Tiny::Try to trap an errors that might occur
when using a proxy.

=cut

sub proxy {
    my $proxy    = pop @_;
    my @protocol = @_;
    return self->proxy([@protocol], $proxy);
}

=method pause

The pause method is an adaptation of the WWW::Mechanize::Sleep module. This method
sets breaks between your requests in an attempt to simulate human interaction.

    init;
    pause 20;
    
    get $request_1;
    get $request_2;
    get $request_3;
    
The will be a break between each request made, get, post, request, etc., You can
also specify a range to have the pause method select from at random...

    init;
    pause 5,20;
    
    get $request_1;
    get $request_2;
    
    # reset/turn it off
    pause 0;
    
    print "I slept for ", (pause), " seconds";
    
Note! The download method is exempt from any automatic pausing, to pause after a
download one could obviously...

    download $requested_url, '/tmp';
    sleep pause();

=cut

sub pause {
    if ($_[0]) {
        if ($_[1]) {
            my @range = (($_[0] < $_[1] ? $_[0] : 0)..$_[1]);
            self->{Mech}->{pause_range} = [$_[0], $_[1]];
            self->{Mech}->{pause} = $range[rand(@range)];
        }
        else {
            self->{Mech}->{pause} = $_[0];
        }
    }
    else {
        my $interval = self->{Mech}->{pause};
        
        # select the next random pause value from the range
        if (defined self->{Mech}->{pause_range}) {
            my @range = list self->{Mech}->{pause_range};
            pause(@range) if @range == 2;
        }
        
        return $interval;
    }
}

1;