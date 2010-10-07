use Test::More
    tests => 9;
    
BEGIN {
#1
    use_ok( 'Scrappy', ':syntax' );
}

eval { self };
#2
    ok !$@, 'initialized without init()';
#3
    ok $Scrappy::class_Instance, 'scrappy app instance set';
#4
    ok "Scrappy" eq ref $Scrappy::class_Instance, 'scrappy class variable good';
#5
    $Scrappy::class_Instance->{holdthis} = '1234567890';
    self;
    ok $Scrappy::class_Instance->{holdthis} == '1234567890', 'self() doesn\'t overwrite';
#6
    reinit;
    ok !$Scrappy::class_Instance->{holdthis}, 'reinit() creates new instance';
#7
    var 123 => 'Sesame Street';
    ok var->{123} eq 'Sesame Street', 'var() setting stash';
#8
    ok !user_agent, 'no user-agent set by default';
#9
    my $new_ua = random_ua;
    user_agent $new_ua;
    ok user_agent, 'user-agent was set properly';