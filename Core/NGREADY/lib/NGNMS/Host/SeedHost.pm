use strict;
use warnings FATAL => 'all';
package  NGNMS::Host::SeedHost;

use Emsgd;
use Moo;
use Types::Standard qw(Enum Str);
use Try::Tiny;
use NGNMS::Net::Connect;

with 'NGNMS::Parser::BGP' ;
with 'NGNMS::Parser::OSPF' ;
with 'NGNMS::Parser::ISIS' ;
with 'NGNMS::Log4Role' ;


has 'host_type' => (
        is      => 'ro',
        required => 1,
        isa     => Enum( [ qw[ Cisco  Juniper  Linux HP Extreme] ] ),
    );
has 'ip_addr' => (
        is => 'ro',
        required=>1,
        isa =>Str,
        trigger=>1,
    );
sub _trigger_ip_addr{
    my ($self,$val) = @_;
    $self->put_debug_key('host',$val)
}
has 'config_dir' => (
        is      => 'ro',
        default => $ENV{"NGNMS_DATA"}.'/topologies' || './',
    );

#sub BUILD{
#    Emsgd::diag(\@_);
#}

my NGNMS::Net::Connect $session;

sub supports_bgp {
    my $self = shift;
    return $self->host_type eq 'Cisco' || $self->host_type eq 'Juniper';
}
sub supports_ospf {
    my $self = shift;
    return $self->host_type eq 'Cisco' || $self->host_type eq 'Juniper';
}
sub supports_isis {
    my $self = shift;
    return $self->host_type eq 'Cisco' || $self->host_type eq 'Juniper';
}


sub get_topology_filename {
    my ($self, $topology) = @_;
    return $self->config_dir."/".$self->ip_addr."_".$topology.".txt";

}

sub create_session{
    my $self = shift;
    return $self->create_session_juniper if  $self->host_type eq 'Juniper';
    return $self->create_session_cisco if  $self->host_type eq 'Cisco';
}
sub get_session {
    return $session;
}
sub create_session_juniper {
    my $self = shift;
    my ($host, $username, $password, $enablepw, $access) = @_[0 .. 4];
#    $self->put_debug_key('host',$host);
    $session = NGNMS::Net::Connect->new({
            personality         => 'junos',
            transport           => $access || 'Telnet',
            host                => $host,
            username            => $username,
            password            => $password,
            privileged_password => $enablepw,
            'debug'             => 'warning',
        });
    return try{
            $session->connect();
            #        $session->begin_privileged();
            #
            #        my @output = $session->macro('check_privileged');
            #        $output[0] =~ s/\n//g;
            #        return 'ok' if $output[0] eq "Current privilege level is 15";
            #        #        $session->close();
            #        return "juniper: enable level failed";
            return 'ok';
        }catch{
                return "juniper: failed to connect and ena to host";
            };
}
sub create_session_cisco {
    my $self = shift;
    my ($host, $username, $password, $enablepw, $access) = @_[0 .. 4];
    #    Emsgd::diag(\@_);
    $session = NGNMS::Net::Connect->new( {
            personality         => 'ios',
            transport           => $access || 'Telnet',
            host                => $host,
            username            => $username,
            password            => $password,
            privileged_password => $enablepw,
            'debug'             => 'warning',
        } );
    return try{
            $session->connect();
            $session->begin_privileged();

            my @output = $session->macro( 'check_privileged' );
            $output[0] =~ s/\n//g;
            return 'ok' if $output[0] eq "Current privilege level is 15";
            #        $session->close();
            return "cisco: enable level failed!";
        }catch{
                return "cisco: failed to connect and ena to host";
            };

}


sub parse_bgp {
    my $self = shift;
    return undef unless $self->supports_bgp;
    my $file = $_[0] || $self->get_topology_filename('bgp');
    $self->logger->error('file not exists: '.$file) && return undef  unless  -e $file;
    #    Emsgd::diag $self->parse_bgp_cisco ( $bgp_file );
    $self->logger->info( "Parsing:: ".$self->host_type." topology file ".$file);
    return $self->parse_bgp_cisco ( $file ) if $self->host_type eq 'Cisco';
    return $self->parse_bgp_juniper ( $file ) if $self->host_type eq 'Juniper';
}

sub parse_ospf {
    my $self = shift;
    return undef unless $self->supports_ospf;
    my $file = $_[0] || $self->get_topology_filename('ospf');
    $self->logger->error('file not exist:s '. $file) && return undef  unless  -e $file;

    $self->logger->info("Parsing:: ".$self->host_type." topology file ".$file);
    #    Emsgd::diag $self->parse_bgp_cisco ( $bgp_file );
    return $self->parse_ospf_cisco ( $file ) if $self->host_type eq 'Cisco';
    return $self->parse_ospf_juniper ( $file ) if $self->host_type eq 'Juniper';
}

sub parse_isis {
    my $self = shift;
    return undef unless $self->supports_isis;
    my $file = $_[0] || $self->get_topology_filename('isis');
    $self->logger->error('file not exists: '.$file) && return undef  unless  -e $file;

    $self->logger->info( "Parsing ".$self->host_type." topology file ".$file);
    #    Emsgd::diag $self->parse_bgp_cisco ( $bgp_file );
    return $self->parse_isis_cisco ( $file ) if $self->host_type eq 'Cisco';
    return $self->parse_isis_juniper ( $file ) if $self->host_type eq 'Juniper';
}

1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
