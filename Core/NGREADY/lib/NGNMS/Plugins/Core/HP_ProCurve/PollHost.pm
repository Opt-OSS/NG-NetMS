package NGNMS::Plugins::Core::HP_ProCurve::PollHost;

use strict;
use warnings FATAL => 'all';
use Moo;
use Emsgd qw(diag);
use File::Basename;
use Net::Netmask;
with "NGNMS::App::PollHostPluginInterface";
with "NGNMS::App::Helpers";
with "NGNMS::Log4Role";

sub checkCanPollHost() {
    return 1;
}

sub prepare_connection {
    my $self    = shift;
    my $params  = shift;
    my $dirname = dirname(__FILE__);
    $params->{personality}         = 'hp';
    $params->{add_library}         = $dirname . '/phrasebook/';
    $params->{requires_privileged} = 1;
    $params->{privileged_paging}   = 1;
    $params->{wake_up}             = 1;
    return $params;
}

sub beforeProcessing {
    my $self = shift;
    $self->session->macro('set_terminal_width');
    return 1;
}

sub getConfig {
    my $self = shift;
    return $self->session->macro('getConfig');
}

sub checkSNMPsysObjectID {

    # '1.3.6.1.4.1.11.2.3.7.11' - Procurve line
    my $self = shift;
    my $mib  = shift;
    return $mib =~ /1\.3\.6\.1\.4\.1\.11\.2\.3\.7\.11\..*/;
}

sub checkDeviceSupported {
    my $self      = shift;
    my $host_type = shift;
    return $host_type =~ m/^HP-Procurve$/i;
}

sub getIpLayer {
    return 2;
}

sub getVendor {
    return 'HP-ProCurve';
}

sub getLocation {
    return '';
}

sub getHostName {
    my $self  = shift;
    my $lines = $self->session->macro('getConfig');
    return unless $lines;
    my ($hostname) = $lines =~ /hostname \"(.*?)\"/m;
    return $hostname;
}

sub getModel {
    my $self  = shift;
    my $table = $self->get_hardware;
    return unless $table;
    ( my $model ) = $table =~ /^entPhysicalDescr.1 = .*?\s(\S+)$/m;
    return $model;
}

sub getHardware {
    my $self  = shift;
    my $table = $self->get_hardware;
    return unless $table;
    my @t = split( /[\r\n]+/, $table );
    my ( %hw, %hw_info_pre );
    for my $n (@t) {
        ( my ( $key, $ind, $val ) ) = $n =~ /^(.*?)\.(\d+)\s+\=\s+(.*?)$/;
        $hw{$ind}{$key} = $val;
    }
    for my $ind ( keys(%hw) ) {
        my $key = $hw{$ind}{entPhysicalDescr};
        if ( !defined $hw_info_pre{$key} ) {
            $hw_info_pre{$key} = {

                #Hardware type, such as Memory, processor
                hw_item => $hw{$ind}{entPhysicalDescr},

                #Hardware short description? such as RAM,NVRAM, CPU x86
                hw_name => $hw{$ind}{entPhysicalModelName},

                #Some ident string, such as Serial number , revision
                hw_ver => $hw{$ind}{entPhysicalSerialNum},

                #meaningful value of hardware (number of CPU, memory amount etc)
                hw_amount => 1,
            };
            next;
        }

        if (   $hw_info_pre{$key}{hw_name} eq $hw{$ind}{entPhysicalModelName}
            && $hw_info_pre{$key}{hw_ver} eq $hw{$ind}{entPhysicalSerialNum} )
        {
            $hw_info_pre{$key}{hw_amount} += 1;
        }
        else {
            $hw_info_pre{ $key . '.' . $ind } = {
                hw_item   => $hw{$ind}{entPhysicalDescr} . '.' . $ind,
                hw_name   => $hw{$ind}{entPhysicalModelName},
                hw_ver    => $hw{$ind}{entPhysicalSerialNum},
                hw_amount => 1,
            };
        }

    }
    my @ret = values(%hw_info_pre);

    #    @ret = sort { $b->{hw_item} cmp $a->{hw_item} } @ret;
    #    diag(\@ret);
    return \@ret;
}

sub getSoftware {
    my $self = shift;
    my $text = $self->session->macro('getSoftware');
    $text = $self->clean_output($text);
    my $sw_info = [];
    if ( $text =~ m/Software revision\s+:\s+(.*?)\s+/ ) {
        push @$sw_info, {
            sw_item => 'Software',    #Hardware type, such as Memory, processor
            sw_name => 'Software revision'
            ,    #Hardware short description? such as RAM,NVRAM, CPU x86
            sw_ver => $1,   #Some ident string, such as Serial number , revision
        };
    }
    if ( $text =~ m/ROM Version\s+:\s+(.*?)\s+/ ) {
        push @$sw_info, {
            sw_item => 'Firmware',     #Hardware type, such as Memory, processor
            sw_name => 'Rom version'
            ,    #Hardware short description? such as RAM,NVRAM, CPU x86
            sw_ver => $1,   #Some ident string, such as Serial number , revision
        };
    }
    return $sw_info;
}



sub getInterfaces {
    my $self               = shift;
    my $ph_interfaces_text = $self->session->macro('getPhysicalInterfaces');
    $ph_interfaces_text = $self->clean_output($ph_interfaces_text);
    my $log_interfaces_text = $self->session->macro('getConfig');
    $log_interfaces_text = $self->clean_output($log_interfaces_text);
    my $ph_if = $self->parse_pysical_interfaces($ph_interfaces_text);
    my $log_if =
      $self->parse_logical_interfaces( $ph_if, $log_interfaces_text );
    return ( $ph_if, $log_if );
}

sub parse_pysical_interfaces {
    my $self = shift;
    my $text = shift;
    my (%ph_if);
    my @ports = $text =~ /(\d+.*?)$/mg;
    for my $t (@ports) {
        chomp $t;
        next if !$t;
        my ( $if_fullname, $state, $condition, $speed ) =
          $t =~ m/(\d+)\s+.*?\s+.*?\w+\s+(\w+)\s+(\w+)\s+(\w+)/
          && ( "Port " . $1, ( $2 eq 'Yes' ? 'enabled' : 'disabled' ), lc $3,
            $4 );
        $self->logger->error("Bad Physical interface: $t") and next unless $if_fullname;
        $ph_if{$if_fullname} = {    #name of physical interface,
            state => $state || "Unknown",    #admin status 'enabled'|'disabled'
            condition => $condition
              || "Unknown",    #physical link state 'up'|'down'|'unknown',
            description => "",        #description|mac(Linux)
            speed => $speed || "",    # 10000Mb/s| 1000  .....
            mtu => 'Unapplicable',
          }

    }

    #    diag( \%ph_if );
    return \%ph_if;

}

sub parse_logical_interfaces {
    my $self  = shift;
    my $ph_if = shift;
    my $text  = shift;
    my (%ifc);
    my @vlans = $text =~ m/^vlan.*?\n(?:[\s]+.*?\n)*/mg;
    for my $vlan (@vlans) {
        my ( $vid, $name, $ip, $mask ) =
          $vlan =~ /vlan\s+(\d+).*?name\s+"(.*?)".*?address\s+(\S+)\s+(\S+)/s;
        $self->logger->error( "Bad Logical interface: " . ( split /\n/, $vlan )[0] )
          and next
          unless $vid
          and $name;
        my $logic_name = $name . "." . $vid;

        #extend physical with vlanname.tag
        my $phif_name = $name . "." . $vid;
        $ph_if->{$phif_name} = {    #name of physical interface,
            state     => 'enabled',  #admin status 'enabled'|'disabled'
            condition => 'up',       #physical link state 'up'|'down'|'unknown',
            description =>
              "Vlan.$vid virtual interface",    #description|mac(Linux)
            speed => '',                        # 10000Mb/s| 1000  .....
        } unless $ph_if->{$phif_name};

        $ifc{$logic_name} = {                   #name of logical interface
            physical_interface_name => $phif_name
            ,    #name of the physical interface this interface is attahed to
            ip   => $ip,      #ip daress
            mask => $mask,    #network mask in  255.255.255.255 form
            description => "Vlan ID $vid",    #description|Admin state for linux
        };
    }

    #    diag ($ph_if);
    #    diag( \%ifc );
    return \%ifc;

}

#------------- hepers
# TODO make clean by reference, so no copy parameter will be used
sub clean_output {
    my $self = shift;
    my $text = shift;
    $text =~ s/^(\s*|\r|\n|\n\r)$//mg;
    $text =~ s/\n+/\n/mg;
    return $text;
}

sub get_hardware {
    my $self = shift;

    #TODO Write to Wiki aboput timeout
    my $lines =
      $self->session->macro( 'getHardware', { timeout => 30, cache => 1 } );
    $lines = $self->clean_output($lines);
    return $lines;
}

sub get_software {
    my $self = shift;

    #TODO Write to Wiki aboput timeout
    my $lines = $self->session->macro('getSoftware');
    return $self->clean_output($lines);
}


sub ping {
    my $self = shift;
    diag $self;
}

sub getModuleName {
    return __PACKAGE__;
}
1;
# ABSTRACT: This file is part of open source NG-NetMS tool.

