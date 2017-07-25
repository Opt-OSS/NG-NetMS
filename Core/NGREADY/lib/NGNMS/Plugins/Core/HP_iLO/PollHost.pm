package NGNMS::Plugins::Core::HP_iLO::PollHost;
use strict;
use warnings FATAL => 'all';
use Moo;
use Emsgd qw(diag);
use File::Basename;
use Net::Netmask;


with "NGNMS::App::PollHostPluginInterface";
with "NGNMS::App::Helpers";

sub checkCanPollHost() {
    return 1;
}

sub prepare_connection {
    my $self    = shift;
    my $params  = shift;
    my $dirname = dirname(__FILE__);
    $params->{personality}         = 'hp';
    $params->{add_library}         = $dirname . '/phrasebook/';
    $params->{requires_privileged} = 0;
    $params->{privileged_paging}   = 0;
    $params->{wake_up}             = 0;
    return $params;
}

sub beforeProcessing {
    return 1;
}

sub getConfig {
    my $self      = shift;
   my $map_settings =  $self->session->macro('getSettings');
   my $map_conig =  $self->session->macro('getConfig');

    return $map_settings."\n---\n".$map_conig;
}

sub checkSNMPsysObjectID {
    #iLO does not respond to SNMP queries
    # return 1 on unreal mib for testing
    my $self = shift;
    my $mib  = shift;
    return $mib =~ /100\.100\.999\.999*/;
}

sub checkDeviceSupported {
    my $self      = shift;
    my $host_type = shift;
    return $host_type =~ m/^HP[-_]iLO$/i;
}

sub getIpLayer {
    return 2;
}

sub getVendor {
    return 'HP-iLO';
}

sub getLocation {
    return '';
}

sub getHostName {
    my $self  = shift;
    my $lines = $self->session->macro('getEnetport');
    return unless $lines;
    my ($hostname) = $lines =~ /SystemName=(.*?)$/m;
    return $hostname;
}

sub getModel {
    my $self  = shift;
    my $lines = $self->session->macro('getSystem');
    return unless $lines;
    my ($model) = $lines =~ /\s+name=(.*?)$/m;
    return $model;
}

sub getHardware {
    my $self = shift;
    my $text_system = $self->session->macro('getSystem');
    my $text_map = $self->session->macro('getMap');
    my $hw_info = [ ];
    if ($text_system =~ m/ number=(.*?)$/m) {
        push @$hw_info,
            {
                hw_item   => 'Chassis', #Hardware type, such as Memory, processor
                hw_name   => 'Chassis', #Hardware short description? such as RAM,NVRAM, CPU x86
                hw_ver    => $1, #Some ident string, such as Serial number , revision
                hw_amount => '', #meaningful value of hardware (number of CPU, memory amount etc)
            };
    }
    if ($text_system =~ m/ processor_number=(.*?)$/m) {
        push @$hw_info,
            {
                hw_item   => 'Chassis', #Hardware type, such as Memory, processor
                hw_name   => 'CPU core number', #Hardware short description? such as RAM,NVRAM, CPU x86
                hw_ver    =>'', #Some ident string, such as Serial number , revision
                hw_amount =>  $1, #meaningful value of hardware (number of CPU, memory amount etc)
            };
    }
    for my $el_index ($text_system =~ m/ cpu(\d+)$/mg){
        my $lines = $self->session->macro('getCpu',{'cache'=>1, 'params'=>[$el_index]});
        next unless $lines;
#        my @cores = $lines =~ m/ (logical_processor)/mg;
        if ($lines =~ m/ speed=(\S+)/m) {
            push @$hw_info,
                {
                    hw_item   => 'Chassis', #Hardware type, such as Memory, processor
                    hw_name   => 'CPU '.$el_index, #Hardware short description? such as RAM,NVRAM, CPU x86
                    hw_ver    =>$1, #Some ident string, such as Serial number , revision
                    hw_amount =>  '', #meaningful value of hardware (number of CPU, memory amount etc)
                };
        }

    }
    for my $el_index ($text_system =~ m/ memory(\d+)$/mg){
        my $lines = $self->session->macro('getMemory',{'cache'=>1, 'params'=>[$el_index]});
        next unless $lines;
        if ($lines =~ m/size=(\S+).*?speed=(\S+).*?location=(.*?)\s*$/ms) {
            push @$hw_info,
                {
                    hw_item   => 'Memory', #Hardware type, such as Memory, processor
                    hw_name   => $3, #Hardware short description? such as RAM,NVRAM, CPU x86
                    hw_ver    => $2, #Some ident string, such as Serial number , revision
                    hw_amount =>  $1, #meaningful value of hardware (number of CPU, memory amount etc)
                };
        }

    }
    for my $el_index ($text_system =~ m/ fan(\d+)$/mg){
        my $lines = $self->session->macro('getFan',{'cache'=>1, 'params'=>[$el_index]});
        next unless $lines;
        if ($lines =~ m/DeviceID=(.*?)\n.*?ElementName=(.*?)\n/s) {
            push @$hw_info,
                {
                    hw_item   => 'Fan', #Hardware type, such as Memory, processor
                    hw_name   => $1, #Hardware short description? such as RAM,NVRAM, CPU x86
                    hw_ver    => '', #Some ident string, such as Serial number , revision
                    hw_amount =>  $2, #meaningful value of hardware (number of CPU, memory amount etc)
                };
        }

    }
    for my $el_index ($text_system =~ m/ slot(\d+)$/mg){
        my $lines = $self->session->macro('getSlot',{'cache'=>1, 'params'=>[$el_index]});
        next unless $lines;
        if ($lines =~ m/type=(.*?)\n.*?width=(.*?)\n/s) {
            push @$hw_info,
                {
                    hw_item   => 'Slot', #Hardware type, such as Memory, processor
                    hw_name   => $1. ' slot '.$el_index , #Hardware short description? such as RAM,NVRAM, CPU x86
                    hw_ver    => '', #Some ident string, such as Serial number , revision
                    hw_amount =>  'width '.$2, #meaningful value of hardware (number of CPU, memory amount etc)
                };
        }

    }
    for my $el_index ($text_system =~ m/ sensor(\d+)$/mg){
        my $lines = $self->session->macro('getSensor',{'cache'=>1, 'params'=>[$el_index]});
        next unless $lines;
        if ($lines =~ m/DeviceID=(.*?)\n.*?ElementName=(.*?)\n.*?SensorType=(.*?)\n/s) {
            push @$hw_info,
                {
                    hw_item   => 'Sensor', #Hardware type, such as Memory, processor
                    hw_name   => $1 , #Hardware short description? such as RAM,NVRAM, CPU x86
                    hw_ver    => $2, #Some ident string, such as Serial number , revision
                    hw_amount =>  $3, #meaningful value of hardware (number of CPU, memory amount etc)
                };
        }

    }
    for my $el_index ($text_system =~ m/ powersupply(\d+)$/mg){
        my $lines = $self->session->macro('getPowersupply',{'cache'=>1, 'params'=>[$el_index]});
        next unless $lines;
        if ($lines =~ m/ElementName=(.*?)\n/s) {
            push @$hw_info,
                {
                    hw_item   => 'Power', #Hardware type, such as Memory, processor
                    hw_name   => $1 , #Hardware short description? such as RAM,NVRAM, CPU x86
                    hw_ver    => '', #Some ident string, such as Serial number , revision
                    hw_amount =>  '', #meaningful value of hardware (number of CPU, memory amount etc)
                };
        }

    }
    # ---- map1
    if ($text_map =~ m/\sname=(.*?)\n/s) {
        push @$hw_info,
            {
                hw_item   => 'iLO board', #Hardware type, such as Memory, processor
                hw_name   => $1 , #Hardware short description? such as RAM,NVRAM, CPU x86
                hw_ver    => '', #Some ident string, such as Serial number , revision
                hw_amount =>  '', #meaningful value of hardware (number of CPU, memory amount etc)
            };
    }
#    diag $hw_info;
    return $hw_info;
}

sub getSoftware {
    my $self = shift;
    my $sw_info = [ ];
    my $text_system = $self->session->macro('getSystem');
    my $text_map = $self->session->macro('getMap');
    for my $el_index ($text_system =~ m/ firmware(\d+)$/mg) {
        my $lines = $self->session->macro('getSystemFirmware',{'cache'=>1, 'params'=>[$el_index]});
        if ($lines =~ m/version=(.*?)\n.*?date=(.*?)\n/s) {
            push @$sw_info, {
                    sw_item => 'System', #type of software (Operating system, Firmware, Software)
                    sw_name => 'firmware '.$el_index,
                    sw_ver  => "$1 ($2)",
                }
        }
    }
    for my $el_index ($text_map =~ m/ firmware(\d+)$/mg) {
        my $lines = $self->session->macro('getMapFirmware',{'cache'=>1, 'params'=>[$el_index]});
        if ($lines =~ m/version=(.*?)\n.*?date=(.*?)\n/s) {
            push @$sw_info, {
                    sw_item => 'iLO', #type of software (Operating system, Firmware, Software)
                    sw_name => 'firmware '.$el_index,
                    sw_ver  => "$1 ($2)",
                }
        }
    }
#    diag($sw_info);
    return $sw_info;
}

sub getInterfaces {
    my $self = shift;
    my $ph_interfaces_text = $self->session->macro( 'getEnetport' );
    my $log_interfaces_text = $self->session->macro( 'getEnetport' );
    my $ph_if = $self->parse_pysical_interfaces( $ph_interfaces_text );
    my $log_if = $self->parse_logical_interfaces( $ph_if, $log_interfaces_text );
    return ($ph_if, $log_if);
}

sub parse_pysical_interfaces{
    my $self = shift;
    my $text = shift;
    my (%ph_if );
    # we could have multiple /mapX/enetportX !! NOT IMPLEMENTED, need examples!!
    #in case we will have multiple lanendptX split it

    my ($full_name) = $text =~ m /\/map\d+\/(enetport\d+)/;
    $self->logger->error( "Bad Physical interface enetport") and  return unless $full_name;
    my ($speed) = $text =~ m/Speed=(.*?)\n/ && ($1 || 'Unknown');
    my ($duplex) = $text =~ m/FullDuplex=(.*?)\n/ && ($1 eq 'yes' ? 'FullDuplex' : '');
    my ($mac) = $text =~ m/PermanentAddress=(.*?)\n/ && ($1 || '');

    $ph_if{$full_name} = { #name of physical interface,
        state       => "enabled", #admin status 'enabled'|'disabled'
        condition   => "up", #physical link state 'up'|'down'|'unknown',
        description => $mac ." ".$duplex, #description|mac(Linux)
        speed       => $speed, # 10000Mb/s| 1000  .....
        mtu => 'Unapplicable',
    };
#    my @if_texts = $text =~ /(lan.*?Verbs.*?)Verbs/gs;
#    diag(\@if_texts);
#    for my $if_text (@if_texts){
#
#    }
#    diag \%ph_if;
    return \%ph_if ;
}
sub parse_logical_interfaces{
    my $self = shift;
    my $ph_if = shift;
    my $text = shift;
    my %ifc;
    $self->logger->error( "No Physical interfaces given, skip logical ") and return undef unless $ph_if;
    my ($ph_full_name) = $text =~ m /\/map\d+\/(enetport\d+)/;
    $self->logger->error( "Bad Physical interface enetport for LOgical interfaces") and  return unless $ph_full_name;
    my @if_texts = $text =~ m /(ipendpt.*?)Ver/gs;
    foreach my $t (@if_texts) {
        chomp $t;
        next if !$t;
        my ($if_fullname,$ip,$mask) = $t =~ m/(ipendpt\d+).*?IPv4Address=(\d+\.\d+\.\d+\.\d+).*?SubnetMask=(\d+\.\d+\.\d+\.\d+)/gs;
        $self->logger->error( "Bad Logical interface: ".(split /\n/, $t)[0]) and next unless $if_fullname;
        $ifc{$if_fullname } = { #name of logical interface
            physical_interface_name => $ph_full_name , #name of the physical interface this interface is attahed to
            ip                      => $ip, #ip daress
            mask                    => $mask, #network mask in  255.255.255.255 form
            description             => '', #description|Admin state for linux
        };
    }
#        diag \%ifc;
    return \%ifc;
}

sub ping {
    my $self = shift;
    diag $self;
}

sub getModuleName {
    return __PACKAGE__;
}


1;
