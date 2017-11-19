package NGNMS::App;

use strict;
use warnings FATAL => 'all';
use POSIX '!new'; # !!! SUPPRESS Subroutine new redefined at warniongs
use Cwd;
use Moo;

use MooX::Options;
use NGNMS::Net::Session;
use NGNMS::Net::SNMPSession;
use NGNMS::Net::Emulator::Session;
use Module::Load qw(autoload);
use Types::Standard qw(Enum Str);

use NGNMS::App::PluginManager;

use Emsgd qw(diag);
use vars qw( @ISA @EXPORT @EXPORT_OK);



with "MooX::Singleton";

#command line options:
with "NGNMS::App::CommandLineOptions";

with  "NGNMS::App::Database";

with "NGNMS::App::PollHostRole";
with "NGNMS::Log4Role";



=head1

 NAME
    NGNMS::App
=head1

 SYNOPSIS
 Main Application class
    provides command-line options and default values
    Used as ServiceLocator to get instances of objects
    Runs application sper-module (pollhost, scan, IP_route configs traversal)

=cut


has config_dir => (
        is      => 'rw',
        default => sub {$ENV{NGNMS_DATA} || './configs'}
    );
has home_dir => (
        is      => 'rw',
        default => sub {$ENV{NGNMS_HOME} || getcwd()}
    );
has supported_hosts => (
        is  => 'ro',
        isa => Enum( [ qw[ Cisco  Juniper  Linux HP Extreme Netscreen] ] ),
    );
#has logger => (
#        is      => 'ro',
#        handles => "NGNMS::Log::LogRole",
#        default => sub { NGNMS::Log->new;},
#    );
#@returns NGNMS::Net::Session
has SessionClass => (
        is      => 'rw',
        default => "NGNMS::Net::Session",
    );
#@returns NGNMS::Net::SNMPSession
has SNMPSessionClass => (
        is      => 'rw',
        default => "NGNMS::Net::SNMPSession",
    );



=head1
Workaround to imitate Moox::Sigleton and has new_with_options
=cut
#@returns NGNMS::App
sub instance {
    my $class = shift;

    no strict 'refs';
    my $instance = \${"$class\::_instance"};
    return defined $$instance ? $$instance
                              : ( $$instance = $class->new_with_options( @_ ) );
}



=item

    session_factory( \%params)
    Factory: creates , connect and returns new session
=cut
#@returns NGNMS::Net::Session
sub session_factory {
    my $self = shift;
    my (%param) = @_;
    #    autoload $self->SessionClass ;
    $param{play_dir} = $self->play if $self->play;
    $param{record} = $self->record;
    $param{record_dir} = $self->record_dir;
    return $self->SessionClass->new( %param );
}
#@returns NGNMS::Net::SNMPSession
sub snmp_session_factory {
    my $self = shift;
    my $param = shift;
    #    autoload $self->SessionClass ;
    return $self->SNMPSessionClass->new();
}


#@deprecated
sub runPluginRegistration{
    my $self=shift;
    my $manager = NGNMS::App::PluginManager->new();
    $manager->find_pollhost_plugins;
};

sub run {
    my $self = shift;
#    if (defined($self->verbose_level())){
#        $self->logger->set_verbose($self->verbose_level);
#
#    }
    if ($self->mode ne 'poll-host' && $self->mode ne 'audit' && $self->mode ne 'register-plugins') {
        $self->logger->error("Wrong run mode");
        return;
    };

    if ($self->play){
        $self->logger->error("--paly requires --host and --host-type") && return if (!$self->host_type  || !$self->host);
        $self->logger->debug("Using Emulator mode, macros served from '".$self->play."' dir");
        $self->SessionClass( 'NGNMS::Net::Emulator::Session' );
        $self->logger->info('Play mode '.$self->host_type.' for '.$self->host.' from "'.$self->play.'" ');
    }
    if ($self->inject) {
        #TODO move actual inject here
        $self->logger->error("--inject requires --host and --host-type and --play") && return if (!$self->host_type || !$self->play || !$self->host);
        $self->logger->error("--inject requires --host to be IP address") && return unless $self->host =~ /\d+\.\d+\.\d+\.\d+/;
        $self->SessionClass( 'NGNMS::Net::Emulator::Session' );
        $self->logger->info("Injecting router")

    }

    #Init DB
    $self->setup_database();
#        diag 'run '.$self->mode;
    if ($self->mode eq 'poll-host'){

        return $self->runPollHost();
    };
    if( $self->mode eq 'audit'){
        return $self->runAuditHost();
    };
     if( $self->mode eq 'register-plugins'){
         return $self->runPluginRegistration();
    };
    return  0;
}


1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
