package Net::CLI::Interact::Transport::JumpHost;
use strict;
use warnings FATAL => 'all';
use Moo::Role;
use MooX::Types::MooseLike::Base qw( InstanceOf);
requires qw/wrapped/;
#@returns Net::Appliance::Session
has 'wrapper_session' => ( #used to build wrapper command over required connection
        is  => 'rw',
        predicate=>1,
        isa=>InstanceOf('Net::Appliance::Session'),
    );

sub  runtime_options {
    my ($self) = (shift);
    my @rw = $self->wrapper_session->nci->transport->runtime_options;
    #    diag \@rw;
    return (@rw,'-tt',$self->wrapped);
};

1;