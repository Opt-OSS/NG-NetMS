package NGNMS::Net::Connect;


use strict;
use warnings FATAL => 'all';
no warnings qw(redefine);  # !!! SUPPRESS Subroutine new redefined at warniongs
use Emsgd qw(diag);
use NGNMS::Log4;
use Moo;
use Try::Tiny;
use Net::CLI::Interact::Role::FindMatch;
use NGNMS::EscapeANSI qw/escape_ansi/;
#use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $data);
#require Exporter;
#@ISA = qw(Exporter Net::Appliance::Session);

#    my Net::Appliance::Session $ssss;
extends "Net::Appliance::Session";
with "NGNMS::Log4Role";
#@returns Net::Appliance::Session
sub BUILDARGS {
    my ( $class, $param ) = @_;
#    diag \@_;
    #** Extend params **#

    $param->{ 'add_library' } = $param->{ 'add_library' } || $ENV{NGNMS_HOME}.'/lib/Phrasebook/';
    $param->{'privileged_paging'} = $param->{'privileged_paging'} || 0; # only if using ASA/PIX OS 7+ and there are other behaviour options, see below
    $param->{'username'} = $param->{'username'} || 'ngnms';
    $param->{'password'} = $param->{'password'} || 'optoss';
    $param->{'privileged_password'} = $param->{'privileged_password'} || 'cisco';
    $param->{connect_options}->{opts} = [ ] unless defined $param->{connect_options}->{opts};
    #    diag($param->{connect_options}->{opts});
    if ($param->{'transport'} eq 'SSHv1') {
        $param->{'transport'} = 'SSH';
        push @{$param->{connect_options}->{opts}}, '-1';
        #      parameters now in CmdOptions
    }
    if ($param->{'transport'} eq 'SSHv2') {
        $param->{'transport'} = 'SSH';
        push @{$param->{connect_options}->{opts}}, '-2';
    }
    $param->{'debug'} = $param->{'debug'} || 'notice';

    return $param;

}

# Patched connect to work with HP banners faster
sub connect {
    my $self = shift;
    my $options = Net::Appliance::Session::Transport::ConnectOptions->new( @_ );
    $self->put_debug_key($self->host);
    $self->logger->debug("Connecting  via ".$self->transport." (".$self->personality.")" );
    foreach my $slot (qw/ username password privileged_password /) {
        my $has = 'has_'.$slot;
        my $set = 'set_'.$slot;
        $self->$set( $options->$slot ) if $options->$has;
    }

    if ($self->nci->transport->is_win32 and $self->has_password) {
        $self->set_password( $self->get_password.$self->nci->transport->ors );
    }

    # SSH transport takes a username if we have one
    $self->nci->transport->connect_options->username( $self->get_username )
        if $self->has_username
            and $self->nci->transport->connect_options->can( 'username' );

    # poke remote device (whether logging in or not)
    $self->find_prompt( $self->wake_up );

    #Telnet transport:  banner shown BEFORE login for HP Procurve
    if ($self->nci->phrasebook->has_prompt( 'wake_up_on_banner' )
        and $self->prompt_looks_like( 'wake_up_on_banner' )) {
        $self->logger->debug("banner found, waking up" );
        $self->put( "\n" );
        $self->find_prompt();
    }

    # optionally, log in to the remote host
    if ($self->do_login and not $self->prompt_looks_like( 'generic' )) {

        if ($self->nci->phrasebook->has_prompt( 'user' )
            and $self->prompt_looks_like( 'user' )) {
            die 'a set username is required to connect to this host'
                if not $self->has_username;

            $self->cmd( $self->get_username, { match => 'pass' } );
        }

        die 'a set password is required to connect to this host'
            if not $self->has_password;

        # support for serial console servers where, after loggin in to the
        # server, the console is asleep and needs waking up to show its prompt
        $self->say( $self->get_password );
        $self->find_prompt( $self->wake_up );
    }
    #SSH transport:  banner shown AFTER login for HP Procurve
    if ($self->nci->phrasebook->has_prompt( 'wake_up_on_banner' )
        and $self->prompt_looks_like( 'wake_up_on_banner' )) {
        $self->logger->debug("banner found after login, waknig up" );
        $self->put( "\n" );
        $self->find_prompt();
    }
    $self->prompt_looks_like( 'generic' )
        or $self->logger->log_and_die(level=>'warning',message=>'login failed to remote host - prompt does not match');

    $self->close_called( 0 );
    $self->logged_in( 1 );
    $self->logger->debug("Logged in" );

    $self->in_privileged_mode( $self->do_privileged_mode ? 0 : 1 );
    $self->in_configure_mode( $self->do_configure_mode ? 0 : 1 );

    # disable paging... this is undone in our close() method
    $self->disable_paging if $self->do_paging;

    return $self;
}
##@deprecated
#sub get {
#    # TODO remove function - used on NGNMS::HOst::Cisco only
#    my ($self, @args) = @_;
#    #starnge bug, just clear term
#    #        $self->SUPER::cmd(' ');
#    ## exec actual
#    return $self->SUPER::cmd( @args );
#}


#    sub connect {
#        my ($self, @args) = @_;
#        my $conn;
#        $conn = $self->SUPER::connect();
#        diag $conn;
#        NGNMS::Log::error( "Connection failed" )  unless $conn;
#                return $conn;
#
#    }

1;
# ABSTRACT: This file is part of open source NG-NetMS tool.

