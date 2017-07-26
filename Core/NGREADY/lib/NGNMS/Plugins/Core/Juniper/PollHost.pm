package NGNMS::Plugins::Core::Juniper::PollHost;

use strict;
use warnings FATAL => 'all';
use Moo;
use Emsgd qw(diag);
use File::Basename;
use Net::Netmask;

with "NGNMS::App::PollHostPluginInterface";
with  "NGNMS::App::Helpers";
with  "NGNMS::Log4Role";

my $version_lines = undef;
sub BUILD {
    $version_lines = undef;
}

sub checkCanPollHost() {
    return 1;
}

sub beforeProcessing {
    my $self = shift;
    my $connection = $self->session->connection;
    if ($connection->get_username() eq 'root'){
        $self->logger->error("Used root account for ".$connection->host);
        $connection->cmd('cli');
        $connection->disable_paging() if $connection->do_paging;
    }
    return 1;
}

sub checkSNMPsysObjectID {
    my $self = shift;
    my $mib = shift;
    return $mib =~ /1\.3\.6\.1\.4\.1\.2636\..*/;
}
sub checkDeviceSupported {
    my $self = shift;
    my $host_type = shift;
    return $host_type =~ m/^[Jj]uniper$/;
}

sub prepare_connection{
    my $self = shift;
    my $params = shift;
    my $dirname = dirname(__FILE__);
    $params->{personality} = 'junos';
    $params->{add_library} = $dirname.'/phrasebook/';
    $params->{requires_privileged} = 0;
    $params->{privileged_paging} = 0;
    $params->{wake_up} = 0;
    return $params;
}

sub getIpLayer {
    return 3;
}
sub getVendor {
    return 'Juniper';
}
sub getLocation {
    return '';
}

sub getHostName {
    my $self = shift;
    $version_lines ||= $self->get_version();
    my ($hostname) = $version_lines =~ m/^Hostname:\s+(.*?)$/sm;
    return $hostname;
}

sub getModel {
    my $self = shift;
    $version_lines ||= $self->get_version();
    my ($model) = $version_lines =~ m/^Model:\s+(\S+)$/sm;
    return $model;
}

sub getHardware {
    my $self = shift;
    my $text = $self->session->macro( 'getHardware' );
    my @lines = split('\n', $text);
    my $hw_info = [ ];
    foreach my $line (@lines) {
        chomp ($line);
        #        $line = $self->trim($line);
        next if !$line || $line =~ qr(Hardware inventory:|Item|show chassis hardware|{master:0});
        #        next unless my @inventory = split ( m'\s{2,}', $line);
        #        diag(\@inventory);
        my @inventory;
        #        next if !defined $inventory[0];
        #Item[0]     Version[1]  Part number[2]  Serial number[3]     Description[4]
        $inventory[0] = $self->trim(substr $line, 0, 17) if length($line) > 0;
        next if !defined $inventory[0];
        $inventory[1] = $self->trim(substr $line, 0 + 17, 9) if length($line) > 0 + 17;
        $inventory[2] = $self->trim(substr $line, 0 + 17 + 9, 13) if length($line) > 0 + 17 + 9;
        $inventory[3] = $self->trim(substr $line, 0 + 17 + 9 + 13, 18) if length($line) > 0 + 17 + 9 + 13;
        $inventory[4] = $self->trim(substr $line, 0 + 17 + 9 + 13 + 18) if length($line) > 0 + 17 + 9 + 13 + 18;
        #        diag(\@inventory);
        $inventory[4] = $inventory[4]."(".$inventory[1].")" if $inventory[1] && $inventory[4];
        $inventory[2] = "P/N ".$inventory[2] if $inventory[2];
        $inventory[3] = "S/N ".$inventory[3] if $inventory[3];
        push @$hw_info,
            {
                hw_item   => $inventory[0], #Hardware type, such as Memory, processor
                hw_name   => $inventory[4], #Hardware short description? such as RAM,NVRAM, CPU x86
                hw_ver    => $inventory[3], #Some ident string, such as Serial number , revision
                hw_amount => $inventory[2], #meaningful value of hardware (number of CPU, memory amount etc)
            };
    }
    #    diag($hw_info);
    return $hw_info;
}
sub getSoftware {
    my $self = shift;
    my $sw_info = [ ];
    $version_lines ||= $self->get_version();
    for my $n ($version_lines =~ /^(JUNOS\s+.*?)$/mg) {
        #        diag $n;
        my ($name, $ver) = $n =~ /JUNOS\s+(.*)\s+\[(.*?)\]/;
        push @$sw_info, {
                sw_item => 'JUNOS', #type of software (Operating system, Firmware, Software)
                sw_name => $name,
                sw_ver  => $ver,
            } if $name && $ver

    }
    #    diag $sw_info;
    return $sw_info;
}

sub getInterfaces() {
    my $self = shift;
    my $ph_interfaces_text = $self->session->macro( 'getPhysicalInterfaces' );
    return $self->parse_pysical_interfaces( $ph_interfaces_text );
}

sub parse_pysical_interfaces {
    my $self = shift;
    my $text = shift;
    my (%ph_if, %ifc );
    chomp $text;
    #1. Split text by interfaces
    my @if_texts = split /^(?=\S.+)/m, $text;
    foreach my $if_text (@if_texts) {
        chomp $if_text;
        next if !$if_text;
        next if $if_text eq '{master:0}';
        #                diag ($t);
        my ($if_fullname, $state, $condition) = $if_text =~ /^Physical interface:\s+([^,]+),\s+([^,]+),\sPhysical link is\s(\S+)/m;
        $self->logger->error( "Bad Physical interface: ".(split /\n/, $if_text)[0]) and next unless $if_fullname;
        next if $if_fullname eq '.local.'; #skip strange if
        $state = 'enabled' if $state =~ /Enabled/;
        $state = 'disabled' if $state =~ /Disabled/;
        $state = 'adm down' if $state =~ /Administratively down/;
        $condition = 'up' if $condition =~ /Up/;
        $condition = 'down' if $condition =~ /Down/;
        my ($description) = $if_text =~ /^  Description:\s+(.*?)$/m;
        my ($speed) = $if_text =~ /^.*?Speed:\s+(.*?)[,\n]/m;
        my ($mtu) = $if_text =~ /^.*?MTU:\s+(.*?)[,\n]/m;

        #        my $speed = "";
        #        if ($t =~ /^.*?Speed:\s+(.*?)[,\n]/m) {
        #            $speed = $1;
        #            $speed = $1."000000" if ($speed =~ /^(\d+)m$/);
        #            $speed = $1."000000" if ($speed =~ /^(\d+)mbps$/);
        #            $speed = "155000000" if ($speed =~ /^OC3$/);
        #            $speed = "622000000" if ($speed =~ /^OC12$/);
        #            $speed = "2488000000" if ($speed =~ /^OC48$/);
        #            $speed = "9952000000" if ($speed =~ /^OC192$/);
        #        }

        #        diag "($if_fullname, $state, $condition)".($description || "ND");
        if (!defined $ph_if{$if_fullname}) {
            $ph_if{$if_fullname} = { #name of physical interface,
                state       => $state || "Unknown", #admin status 'enabled'|'disabled'
                condition   => $condition || "Unknown", #physical link state 'up'|'down'|'unknown',
                description => $self->trim($description || ""), #description|mac(Linux)
                speed       => $self->trim($speed || ""), # 10000Mb/s| 1000  .....
                mtu         => $self->trim($mtu || undef), # Interface MTU bytes
            };
            $self->parse_logical_interfaces( $if_fullname, $if_text, \%ifc );
        }
    }
    #        diag(\%ifc );
    return  (\%ph_if, \%ifc);
}
sub parse_logical_interfaces {
    my $self = shift;
    my $phif_name = shift;
    my $phif_text = shift;
    my $ifc = shift;
    my @if_texts = split /(?=Logical interface.+)/m, $phif_text;

    foreach my $if_text (@if_texts) {
        #skip first part "Physical interface:
        next if $if_text =~ /^Physical interface/m;
        my ($if_fullname) = $if_text =~ /^Logical interface\s+(\S+)\s/m;
        $self->logger->error( "Bad Physical interface: ".(split /\n/, $if_text)[0]) and next unless $if_fullname;
        my ($description) = $if_text =~ /Description:\s+(.*?)$/m;
        my @ip_mask;

        my @if_potocols = split /(?=Protocol.+)/m, $if_text;
        shift @if_potocols; #skip Logical interface part

        for my $proto_text (@if_potocols) {
            my ($proto) = $proto_text =~ /^Protocol\s(\S+),/;
            #TODO add support for iso and inetv6
            if ($proto eq 'iso' or $proto eq 'inet6' or $proto eq 'mpls'){
                $self->logger->warning("Protocol '$proto' is not supported, interfase: $if_fullname ")
            }
            next if $proto ne 'inet';
            for my $n ($proto_text =~ /^(.*?Local:\s+\d+\.\d+\.\d+\.\d+.*?)$/mg) {
                #            diag $n;
                my ($ip) = $n =~ /Local:\s+(\d+\.\d+\.\d+\.\d+)/;
                $self->logger->error( "Can not get IP for interface $phif_name : ".$n) and next unless $ip;
                my ($mask) = $n =~ /Destination:\s+[\d\.]+\/(\d+)/;
                $mask = Net::Netmask->new( $ip.'/'.($mask || '32') )->mask; #Junos /32 not shown as /mask
                #            diag $ip.'/'.$mask;

                push @ip_mask, { ip => $ip, mask => $mask };
            }
            my $ip_count = scalar ( @ip_mask );
            $self->logger->debug( "No primary address found for $if_fullname") and next unless $ip_count;

            #        diag \@ip_mask, $if_fullname;
            my $if_alias = 0;
            for my $ip (@ip_mask) {
                my $logic_name = $ip_count > 1 ? $if_fullname.':'.$if_alias++ : $if_fullname;
                $ifc->{$logic_name } = { #name of logical interface
                    physical_interface_name => $phif_name, #name of the physical interface this interface is attahed to
                    ip                      => $ip->{ip}, #ip daress
                    mask                    => $ip->{mask}, #network mask in  255.255.255.255 form
                    description             => $self->trim($description || ''),, #description|Admin state for linux
                };
            }
        }
    }

}
sub getConfig {
    my $self = shift;
    return $self->session->macro( 'getConfig' );
}
#===================== Plugin required
sub ping {
    my $self = shift;
    diag $self;
}
sub getModuleName {
    return __PACKAGE__;
}
#==================== Hlpers
sub get_version {
    my $self = shift;
    return $self->session->macro( 'getVersion' );
}

1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
