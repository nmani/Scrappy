use Test::More tests => 2;
BEGIN { use_ok( 'Scrappy', ':syntax' ); }
eval { self };
ok($@, 'init required');