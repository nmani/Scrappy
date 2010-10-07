# ABSTRACT: All Powerful Web Harvester, Spider, Scraper fully automated

use strict;
use warnings;

package Scrappy;

use FindBin;
use WWW::Mechanize;
use Web::Scraper;
use File::ShareDir ':ALL';
use File::Slurp;
use YAML::Syck;
use Array::Unique;
use Try::Tiny;
use URI;

our $class_History              = [];
our $class_Instance             = {};
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
        crawl
        queue
        cursor
        denied
        history
        reinit
    );
    %EXPORT_TAGS = ( syntax => [ @EXPORT_OK ] );
}

=head1 SYNOPSIS

Scrappy does it all, any way you like. Object-Oriented or DSL (Domain-Specific).
Lets look at a simple scraper in OO context.

    #!/usr/bin/perl
    use Scrappy;

    my $spidy = Scrappy->new;
    
    $spidy->crawl('http://search.cpan.org/recent', {
        '#cpansearch li a' => sub {
            print shift->text, "\n";
        }
    });

Now lets run the same operation again in DSL context.

    #!/usr/bin/perl
    use Scrappy qw/:syntax/;
    
    crawl 'http://search.cpan.org/recent', {
        '#cpansearch li a' => sub {
            print shift->text, "\n";
        }
    };

=head1 DESCRIPTION

Scrappy is an easy (and hopefully fun) way of scraping, spidering, and/or
harvesting information from web pages, web services, and more. Scrappy is a
feature rich, flexible, intelligent web automation tool.

Scrappy (pronounced Scrap+Pee) == 'Scraper Happy' or 'Happy Scraper'; If you
like you may call it Scrapy (pronounced Scrape+Pee) although Python has a web
scraping framework by that name and this module is not a port of that one.

Scrappy is approaching version 1.0, taking on critical mass :}

=cut

=method init

Builds the scraper application instance. This function is called automatically
in DSL context and is otherwise irrelevent. This function creates the application
instance all other functions will use in DSL context. This function returns the
current scraper application instance.

    my $scraper = init;

=cut

sub init {
    bless $class_Instance, 'Scrappy';
    
    $class_Instance->{Prop}          = { stash => {} };
    $class_Instance->{Mech}          = WWW::Mechanize->new(@_);
    $class_Instance->{Mech}->{pause} = 0;
    
    return $class_Instance;
}

=method reinit

The reinit method is an alias to the init method. This function should be called
in DSL context when a new scraper application instance in desired. This function
will returns the new scraper application instance. Obviously in OO context, one
would simply use Scrappy->new to create a new instance.

    my $new = reinit;

=cut

sub reinit {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    $class_Instance = {};
    return init(@_);
}

=method self

This method returns the current scraper application instance which can also be
found in the package class variable $class_Instance. This method has no pratical
purpose in OO context and is made available to return the current scraper application
instance in DSL context only.

    my $self = self;

=cut

sub self {
    # if init() has never been called, try if once
    init() unless keys %{$class_Instance};
    die 'Could not create a scraper application instance, please make sure you ' .
        'have installed Scrappy and its prerequesites properly.'
        unless keys %{$class_Instance};
    return $class_Instance;
}

=method user_agent

This method gets/sets the user-agent for the current scraper application instance.

    user_agent 'Mozilla/5.0 (Windows; U; Windows NT ...';

=cut

sub user_agent {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    my ($requested_user_agent) = shift;
    self->{Mech}->add_header("User-Agent" => $requested_user_agent)
        if defined $requested_user_agent;
    return $requested_user_agent ?
        $requested_user_agent : self->{Mech}->{headers}->{'User-Agent'};
}

=method var

This method sets a stash (shared) variable or returns a reference to the entire
stash object.

    var age => 31;
    print var->{age};
    
    my @array = (1..20);
    var integers => @array;
    
=cut

sub var {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    my ($key, $value) = @_;
    if (@_ == 2) {
        # stash variable nesting
        # ** depreciated **
        # ** not recommended **
        # var 'user/profile/name' => 'Mr. Foobar';
        if ($key =~ /\//) {
            $key =~ s/\/+/\//g;
            $key =~ s/(^\/)|(\/$)//g;
            my @keys = split /\//, $key;
            my $var  = self->{Prop}->{Stash};
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
            self->{Prop}->{Stash}->{$key} = $value if (@_ == 2);
            return self->{Prop}->{Stash}->{$key};
        }
    }
    elsif (@_ == 1) {
        return self->{Prop}->{Stash}->{$_[0]};
    }
    return self->{Prop}->{Stash};
}

=method random_ua

This returns a random user-agent string for use with the user_agent method. The
user-agent header in your request is how an inquiring application might determine
the browser and environment making the request. The first argument should be the
name of the web browser, supported web browsers are any, chrome, ie or explorer,
opera, safari, and firfox. Obviously using the keyword `any` will select from
any available browsers. The second argument which is optional should be the name
of the desired operating system, supported operating systems are windows,
macintosh, and linux. 

    user_agent random_ua;
    # same as random_ua 'any';
    
e.g. for a Linux-specific Google Chrome user-agent use the following...
    
    user_agent random_ua 'chrome', 'linux';

=cut

sub random_ua {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
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
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    my $response = self->{Mech}->submit_form(@_);
    sleep pause();
    return $response;
}

=method get

The get method is a shortcut to the WWW::Mechanize get method. This
method takes a URL or URI and returns an HTTP::Response object.

=cut

sub get {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    my $request = self->{Mech}->get(URI->new(@_));
    push @{$class_History}, @_;
    self->{Mech}->{cookie_jar}->scan(\&_cookies_to_session);
    sleep pause();
    #headers are in $request;
    return self;
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
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    my ($url, $params) = @_;
    if ($url && ref($params) eq "HASH") {
        my $request =
        self->{Mech}->post(
            $url,
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Content'      => $params
        );
        self->{Mech}->{cookie_jar}->scan(\&_cookies_to_session);
        sleep pause();
        return $request;
    }
    else {
        my $request = self->{Mech}->post(@_);
        self->{Mech}->{cookie_jar}->scan(\&_cookies_to_session);
        sleep pause();
        return $request;
    }
}

=method grab

The grab method takes XPATH or CSS3 selectors and returns corresponding elements,
it is a shortcut to the Web::Scraper process method. It take the exact same
arguments with a little bit of our own added magic, namely you can grab and
return a single element and specify whether to return TEXT, HTML or and @attribute.
By default the return value of a single-element is TEXT. Whenever you specify a
hashref mapping of attributes to grab, the results are returned as an arrayref,
this may change in the future.

    grab '#profile li a'; # return the inner text of the first encounter
    grab '#profile li a', '@href'; # specifically returning href attribute of the first encounter
    
    # the traditional use is to provide a selector and mappings/return values e.g.
    grab '#profile li a', { name => 'TEXT', link => '@href' };
    
    # feeling lazy, let Scrappy auto-discover the attributes for you
    grab '#profile li a', ':all'; # returns an arrayref if more than one element is found
    
    # Note! elements are returned as objects with accessors making it possible
    # to do the following....
    
    my $link = grab '#profile li a:first', ':all';
    print $link->href;
    
    grab 'a'; # returns inner text of the first match
    grab 'a', 'html'; # returns inner html of the first match
    grab 'a', '@href'; # returns the href attribute of the first match
    
    grab 'a', ':all'; # returns an arrayref with all attributes including text, and html
    grab 'a', { key => 'attr' }; # returns an arrayref with the specified attributes

Zoom in on specific chunks of html code or pass you own using the following method call:

    grab 'element', ':all', $html_content;

=cut

sub grab {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    my ($selector, $mapping, $html) = @_;
    
    die "The grab function needs html and a selector at least to function properly"
        unless @_ >= 2;
    
    $html ||= html();
    
    if ($mapping) {
        if ("HASH" eq ref $mapping) {
            
            my $scraper =
                scraper {
                    process
                        ($selector, "data[]", $mapping) };
            my $temp = $scraper->scrape( $html );
            return element($temp->{data});
        }
        else {
            
            if (":all" eq lc $mapping) {
                 my $scraper =
                    scraper {
                        process
                            ($selector, "data[]", tattr()) };
                my $temp = $scraper->scrape( $html );
                return element($temp->{data});
            }
            
            my $scraper =
                scraper {
                    process
                        ($selector, "data[]", { selected => $mapping }) };
            my $temp = $scraper->scrape( $html );
            return $temp->{data}[0]->{selected};
        }
    }
    else {
        my $scraper =
                scraper {
                    process
                        ($selector, "data[]", { everything => 'TEXT' }) };
        my $temp = $scraper->scrape( $html );
        return $temp->{data}[0]->{everything};
    }
}

=method loaded

The loaded method is a shortcut to the WWW::Mechanize success method. This
method returns true/false based on whether the last request was successful.

    get $requested_url;
    if (loaded) {
        grab ...
    }

=cut

sub loaded {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    return self->{Mech}->success;
}

=method status

The status method is a shortcut to the WWW::Mechanize status method. This
method returns the 3-digit HTTP status code of the response.

    get $requested_url;
    if (status == 200) {
        grab ...
    }

=cut

sub status {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    return self->{Mech}->status;
}

=method reload

The reload method is a shortcut to the WWW::Mechanize reload method. This
method acts like the refresh button in a browser, repeats the current request.

=cut

sub reload {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    my $response = self->{Mech}->reload;
    sleep pause();
    return $response;
}

=method back

The back method is a shortcut to the WWW::Mechanize back method. This
method is the equivalent of hitting the "back" button in a browser, it returns
the previous page (response), it will not backtrack beyond the first request.

=cut

sub back {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    my $response = self->{Mech}->back;
    sleep pause();
    return $response;
}

=method page

The page method is a shortcut to the WWW::Mechanize uri method. This
method returns the URI of the current page as a URI object.

=cut

sub page {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    return self->{Mech}->uri;
}

=method response

The response method is a shortcut to the WWW::Mechanize response method. This
method returns the HTTP::Repsonse object of the current page.

=cut

sub response {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    return self->{Mech}->response;
}

=method content_type

The content_type method is a shortcut to the WWW::Mechanize content_type method.
This method returns the content_type of the current page.

=cut

sub content_type {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    return self->{Mech}->content_type;
}

=method domain

The domain method is a shortcut to the WWW::Mechanize base method.
This method returns URI host of the current page.

=cut

sub domain {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    return self->{Mech}->base;
}

=method ishtml

The ishtml method is a shortcut to the WWW::Mechanize is_html method.
This method returns true/false based on whether our content is HTML, according
to the HTTP headers.

=cut

sub ishtml {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    return self->{Mech}->is_html;
}

=method title

The title method is a shortcut to the WWW::Mechanize title method.
This method returns the content of the title tag if the current page is HTML,
otherwise returns undef.

=cut

sub title {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    return self->{Mech}->title;
}

=method text

The text method is a shortcut to the WWW::Mechanize content method using
the format argument and returns a text representation of the last page having
all HTML markup stripped.

=cut

sub text {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    return data( format => 'text');
}

=method html

The html method is a shortcut to the WWW::Mechanize content method. This method
returns the content of the current page.

=cut

sub html {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    return data(@_);
}

=method data

The data method is a shortcut to the WWW::Mechanize content method. This method
returns the content of the current page exactly the same as the html function does.
Additionally this method when passed data, updates the content of the current page
with that data and returns the modified content.

=cut

sub data {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    if ($_[0]) {
        unless ($_[1]) {
            self->{Mech}->update_html($_[0]);
        }
    }
    return self->{Mech}->content(@_);
}

=method www

The www method is an alias to the self method. This method
returns the current scraper application instance.

=cut

sub www {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
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
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    return self->{Mech}->save_content(@_);
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
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
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
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
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
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    my @array = list @_;
    return shift @array;
}

=method lst

The lst (last) method pops the passed in arrayref returning the last element
in the array shortening it by one.

    var foo => lst grab '.class', { name => 'TEXT' };

=cut

sub lst {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
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
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
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

The config method is an alias to the Scrappy session method for brevity.

=cut

sub config {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    return session @_;
}

=method cookies

The cookies method is a shortcut to the automatically generated WWW::Mechanize
cookie handler. This method returns an HTTP::Cookie object. Setting this as
undefined using the _undef keyword will prevent cookies from being stored and
subsequently read.

    get $requested_url;
    my $cookies = cookies;
    
    # prevent cookie storage
    cookies _undef;

=cut

sub cookies {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
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

    proxy 'http', 'http://proxy.example.com:8000/';
    get $requested_url;
    
    proxy 'http', 'ftp', 'http://proxy.example.com:8000/';
    get $requested_url;
    
    # best practice
    
    use Tiny::Try;
    
    proxy 'http', 'ftp', 'http://proxy.example.com:8000/';
    
    try {
        get $requested_url
    };
    
Note! When using a proxy to perform requests, be aware that if they fail your
program will die unless you wrap your code in an eval statement or use a try/catch
module. In the example above we use Tiny::Try to trap an errors that might occur
when using a proxy.

=cut

sub proxy {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    my $proxy    = pop @_;
    my @protocol = @_;
    return self->{Mech}->proxy([@protocol], $proxy);
}

=method pause

The pause method is an adaptation of the WWW::Mechanize::Sleep module. This method
sets breaks between your requests in an attempt to simulate human interaction.

    pause 20;
    
    get $request_1;
    get $request_2;
    get $request_3;
    
Given the above example, there will be a 20 sencond break between each request made,
get, post, request, etc., You can also specify a range to have the pause method
select from at random...

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
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
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

=method history

The history method returns a list of visted pages.

    get $url_a;
    get $url_b;
    get $url_c;

    print history;

=cut

sub history {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    return @{$class_History};
}

=method denied

The denied method is a simple shortcut to determine if the page you
requested got loaded or redirected. This method is very useful on systems
that require authentication and redirect if not authorized. This function
return boolean, 1 if the current page doesn't match the requested page.

    get $url_to_dashboard;
    
    if (denied) {
        # do login, again
    }
    else {
        # resume ...
    }

=cut

sub denied {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    my ($last) = reverse history;
    return 1 if (page ne $last);
}

=method new

The new method creates a new OO (object-oriented) Scrappy instance. It is worth mentioning that
Scrappy can be used in both OO (object-oriented) and DSL (domain-specific) fashion.
Both styles have advantages and drawbacks, we have both so that settles that.
Please note that a Scrappy instance is created automatically on-the-fly for those
using DSL syntax.

    my $spidy = Scrappy->new;

=cut

sub new {
    return init;
}

our @_queue = ();
tie @_queue, 'Array::Unique';
our $_cursor = 0;

=method cursor

The cursor method is used internally by the crawl method to determine what
pages in the queue should be fetched next after the completion of the current
fetch. This method returns the position of the cursor in the queue.

=cut

sub cursor {
    $_cursor = $_[0] if $_[0];
    return $_cursor;
}

=method queue

The queue method is used to add valid URIs to the page fetching queue used by
the crawl method internally, or to return the list of added URIs in the order
received/input.

    queue $new_url;
    my @urls = queue;

=cut

sub queue {
    return @_ ? push @_queue, @_ : @_queue;
}

=method crawl

The crawl method is designed to automatically and systematically crawl, spider,
or fetch webpages and perform actions on selected elements on each page. This
method will start by GETting the initial URL passed, it then iterates over each
selector executing the corresponding routine for each matched element.

    crawl $starting_url, {
        'a' => sub {
            # find all links and add them to the queue to be crawled
            queue shift->href;
        },
        '/*' => sub {
            # /* simply matches the root node, same as using 'body' in
            # html page context, maybe do soemthing with shift->text or shift->html
        },
        'img' => sub {
            # print all image URLs
            print shift->src, "\n"
        }
    };

=cut

sub crawl {
    my $self = 'Scrappy' eq ref $_[0] ? shift @_ : undef;
    
    my @array = @_;
    
    my $actions = pop @array;
    my $url     = shift @array;
    
    die 'crawler need a URL and actions to proceed' unless $url && $actions;
    
    queue $url, @array if @array;
    
    $_queue[cursor()] = $url;
    
    doPage:
    
    try {
        get $_queue[cursor()];
    }
    catch {
        warn "problem fetching " . $_queue[cursor()];
        goto nextPage;
    };
    
    try {
        loaded;
    }
    catch {
        warn "problem loading " . $_queue[cursor()];
        goto nextPage;
    };
    
    warn "fetching page " . $_queue[cursor()] if $ENV{Scrappy_Trace};
    
    # process actions
    if ("hash" eq lc ref $actions) {
        # while (my($selector, $function) = each(%{$actions}))
        foreach my $action (keys %{$actions}) {
            my ($selector, $function) = ($action, $actions->{$action});
            my $findings = grab $selector, ':all';
            if ("array" eq lc ref $findings) {
                foreach (@{$findings}) {
                    $function->($_);
                }
            }
            else {
                $function->($findings);
            }
        }
    }
    
    nextPage:
    goto doPage if $_queue[++$_cursor];
}

## UTILITIES (Not OO nor DSL, Internal Only)

sub element {
    my $object = shift;
       $object = [$object] unless "ARRAY" eq ref $object;
       
    foreach my $element (@{$object}) {
        foreach my $attr(keys %{$element}) {
            {
                no warnings 'redefine';
                no strict 'refs';
                *{"Scrappy::Element::$attr"} = sub {
                    return shift->{$attr};
                }
            }
        }
        bless $element, 'Scrappy::Element';
    }
    
    return @{$object} == 1 ? $object->[0] : $object;
}

sub tattr {
    return {
        'abbr'           => '@abbr',
        'accept-charset' => '@accept',
        'accept'         => '@accept',
        'accesskey'      => '@accesskey',
        'action'         => '@action',
        'align'          => '@align',
        'alink'          => '@alink',
        'alt'            => '@alt',
        'archive'        => '@archive',
        'axis'           => '@axis',
        'background'     => '@background',
        'bgcolor'        => '@bgcolor',
        'border'         => '@border',
        'cellpadding'    => '@cellpadding',
        'cellspacing'    => '@cellspacing',
        'char'           => '@char',
        'charoff'        => '@charoff',
        'charset'        => '@charset',
        'checked'        => '@checked',
        'cite'           => '@cite',
        'class'          => '@class',
        'classid'        => '@classid',
        'clear'          => '@clear',
        'code'           => '@code',
        'codebase'       => '@codebase',
        'codetype'       => '@codetype',
        'color'          => '@color',
        'cols'           => '@cols',
        'colspan'        => '@colspan',
        'compact'        => '@compact',
        'content'        => '@content',
        'coords'         => '@coords',
        'data'           => '@data',
        'datetime'       => '@datetime',
        'declare'        => '@declare',
        'defer'          => '@defer',
        'dir'            => '@dir',
        'disabled'       => '@disabled',
        'enctype'        => '@enctype',
        'face'           => '@face',
        'for'            => '@for',
        'frame'          => '@frame',
        'frameborder'    => '@frameborder',
        'headers'        => '@headers',
        'height'         => '@height',
        'href'           => '@href',
        'hreflang'       => '@hreflang',
        'hspace'         => '@hspace',
        'http'           => '@http-equiv',
        'id'             => '@id',
        'ismap'          => '@ismap',
        'label'          => '@label',
        'lang'           => '@lang',
        'language'       => '@language',
        'link'           => '@link',
        'longdesc'       => '@longdesc',
        'marginheight'   => '@marginheight',
        'marginwidth'    => '@marginwidth',
        'maxlength'      => '@maxlength',
        'media'          => '@media',
        'method'         => '@method',
        'multiple'       => '@multiple',
        'name'           => '@name',
        'nohref'         => '@nohref',
        'noresize'       => '@noresize',
        'noshade'        => '@noshade',
        'nowrap'         => '@nowrap',
        'object'         => '@object',
        'onblur'         => '@onblur',
        'onchange'       => '@onchange',
        'onclick'        => '@onclick',
        'ondblclick'     => '@ondblclick',
        'onfocus'        => '@onfocus',
        'onkeydown'      => '@onkeydown',
        'onkeypress'     => '@onkeypress',
        'onkeyup'        => '@onkeyup',
        'onload'         => '@onload',
        'onmousedown'    => '@onmousedown',
        'onmousemove'    => '@onmousemove',
        'onmouseout'     => '@onmouseout',
        'onmouseover'    => '@onmouseover',
        'onmouseup'      => '@onmouseup',
        'onreset'        => '@onreset',
        'onselect'       => '@onselect',
        'onsubmit'       => '@onsubmit',
        'onunload'       => '@onunload',
        'profile'        => '@profile',
        'prompt'         => '@prompt',
        'readonly'       => '@readonly',
        'rel'            => '@rel',
        'rev'            => '@rev',
        'rows'           => '@rows',
        'rowspan'        => '@rowspan',
        'rules'          => '@rules',
        'scheme'         => '@scheme',
        'scope'          => '@scope',
        'scrolling'      => '@scrolling',
        'selected'       => '@selected',
        'shape'          => '@shape',
        'size'           => '@size',
        'span'           => '@span',
        'src'            => '@src',
        'standby'        => '@standby',
        'start'          => '@start',
        'style'          => '@style',
        'summary'        => '@summary',
        'tabindex'       => '@tabindex',
        'target'         => '@target',
        'text'           => '@text',
        'title'          => '@title',
        'type'           => '@type',
        'usemap'         => '@usemap',
        'valign'         => '@valign',
        'value'          => '@value',
        'valuetype'      => '@valuetype',
        'version'        => '@version',
        'vlink'          => '@vlink',
        'vspace'         => '@vspace',
        'width'          => '@width',
        'text'           => 'TEXT',
        'html'           => 'HTML',
    };
    # need xml and json support maybe?
}

1;