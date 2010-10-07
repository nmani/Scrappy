use Test::More
    tests => 10;
    
BEGIN {
#1
    use_ok( 'Scrappy' );
}

my $self = undef;
eval { $self = Scrappy->new };
#2
    ok !$@, 'new Scrappy instance create';
#3
    ok $Scrappy::class_Instance, 'scrappy app instance set';
#4
    ok "Scrappy" eq ref $Scrappy::class_Instance, 'scrappy class variable good';
#5
    $Scrappy::class_Instance->{holdthis} = '1234567890';
    Scrappy::init;
    ok $Scrappy::class_Instance->{holdthis} == '1234567890', 'dsl doesn\'t overwrite or break';
#6
    Scrappy::reinit;
    ok !$Scrappy::class_Instance->{holdthis}, 'dsl and oop working in tandum';
#7
    $self->var(123 => 'Sesame Street');
    ok $self->var(123) eq 'Sesame Street', 'var stash set normally';
#8
    $self->var->{123} = { 456 => 'Sesame Street' };
    ok $self->var->{123}->{456} eq 'Sesame Street', 'multi-level var stash set normally';
#9
    ok !$self->user_agent, 'no user-agent set by default';
#10
    $self->user_agent($self->random_ua);
    ok $self->user_agent, 'user-agent was set properly';