use Test::More tests => 3;

BEGIN {
    use_ok( 'Scrappy' );
}

my $self = Scrappy->new;
ok $self, "oo self good";
ok ref $self eq 'WWW::Mechanize::Pluggable', "oo self class good";
ok $self->get('http://search.cpan.org'), "oo get works";
