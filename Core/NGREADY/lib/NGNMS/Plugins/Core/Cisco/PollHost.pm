package NGNMS::Plugins::Core::Cisco::PollHost;

use strict;
use warnings FATAL => 'all';
use Moo;
use Emsgd qw(diag);
use File::Basename;
use Net::Netmask;
use NGNMS::Net::SNMPSession;
with "NGNMS::App::PollHostPluginInterface" ;
with  "NGNMS::App::Helpers";
with  "NGNMS::Log4Role";
my $version_lines = undef;
my $running_config_lines = undef;

sub BUILD {
    $version_lines = undef;
    $running_config_lines = undef;
}

sub checkCanPollHost() {
    return 1;
}

sub beforeProcessing{
    return 1;
}
sub checkSNMPsysObjectID {
    my $self = shift;
    my $mib = shift;
    return $mib =~ /1\.3\.6\.1\.4\.1\.9\..*/;
}
sub checkDeviceSupported {
    my $self = shift;
    my $host_type = shift;
    return $host_type =~ m/^[Cc]isco$/;
}
sub prepare_connection{
    my $self = shift;
    my $params = shift;
    my $dirname = dirname(__FILE__);
    $params->{personality} = 'ios';
    $params->{add_library} =  $dirname.'/phrasebook/';
    $params->{requires_privileged} = 1;
    $params->{privileged_paging} = 0;
    $params->{wake_up} = 0;
    return $params;
}
#sub getPersonality {
#    return 'ios'; #Linux-based for Net::CLI::Interact::Phrasebook.
#}
#Could not be plaiced to Role cause uses relative to __FILE__ path
#sub getPhraseBook {
#    #extend default phrasebook
#    my $dirname = dirname(__FILE__);
#    return $dirname.'/phrasebook/';
#}
#sub getRequiresPrivileged {
#    return 1;
#}

sub getHostName {
    my $self = shift;
    my $text = $self->getConfig;
    my ($hostname) = $text =~ m/^hostname\s+(\S+)$/sm;
    return $hostname;
}

sub getIpLayer {
    return 3;
}
sub getVendor {
    return 'Cisco';
}
sub getLocation {
    return '';
}
sub getModel {
    #todo check device supports show hardware, if not, fallback to SNMP
    my $self = shift;
    return 'Unknown' unless my $r = $self->_getSNMPsysObjectID0_asString();
    #RFC1213-MIB::sysObjectID.0 = OID: CISCO-PRODUCTS-MIB::ciscoMC3810
    chomp( $r);
    my @t_arr = split( /:/, $r );
    return  $t_arr[-1];

}



sub getInterfaces {
    my $self = shift;
    my $ph_interfaces_text = $self->session->macro( 'getPhysicalInterfaces' );
    my $log_interfaces_text = $self->session->macro( 'getLogicalInterfaces' );
    my $ph_if = $self->parse_pysical_interfaces( $ph_interfaces_text );
    my $log_if = $self->parse_logical_interfaces( $ph_if, $log_interfaces_text );
    return ($ph_if, $log_if);
}
sub parse_logical_interfaces {
    my $self = shift;
    my $ph_if = shift;
    my $text = shift;
    my %ifc;
    $self->logger->error( "No Physical interfaces given, skip logical ") and return undef unless $ph_if;
    chomp $text;
    #1. Split text by interfaces
    my @if_texts = split /^(?=\S.+)/m, $text;
    foreach my $t (@if_texts) {
        chomp $t;
        next if !$t;
        #        diag ($t);
        my ($if_fullname, $state, $condition) = $t =~ m/^(\S+)\s+is\s+([^,]+),\s+line protocol is\s+(.*)$/m;
        #        $self->logger->error "Bad interface: ".(split /\n/,$t)[0];
        $self->logger->error( "Bad Logical interface: ".(split /\n/, $t)[0]) and next unless $if_fullname;
#        $state = 'enabled' if $state =~ /up/;
#        $state = 'disabled' if $state =~ /down/;
#        $condition = 'up' if $condition =~ /up/;
#        $condition = 'down' if $condition =~ /down/;
        my $if_names = $self->_split_inteface_name( $if_fullname );
        $self->logger->error ("could not find physical interface for $if_fullname") and  next unless defined $ph_if->{$if_names->{physical_name}};
        ################ Logical interaces ##########################
        my @ip_mask = $t =~ m/(?:Internet|Secondary)\s+address\s+(?:is)*.*?([\d\.\/]+)/sg;
#        diag(\@ip_mask);
        #        diag(\@ip_mask);
        my $ip_count = scalar ( @ip_mask );
        $self->logger->debug( "No primary address found for $if_fullname")  and next unless $ip_count;

        my $if_alias = 0;
        #process logical
        foreach  my $ipm (@ip_mask) {
            my ($ip, $mask) = split /\//, $ipm;
            my $logic_name = $if_names->{logical_name};
            $logic_name .= ':'.$if_alias++ if $ip_count > 1;

            $ifc{$logic_name } = { #name of logical interface
                physical_interface_name => $if_names->{physical_name}, #name of the physical interface this interface is attahed to
                ip                      => $ip, #ip daress
                mask                    => Net::Netmask->new( $ipm )->mask, #network mask in  255.255.255.255 form
                description             => $if_names->{physical_name}.":: ".$ph_if->{$if_names->{physical_name}}->{description}, #description|Admin state for linux
            };
            #            diag  $ifc{$logic_name }, $logic_name;
        };
    }
#    diag $ph_if;
#    diag \%ifc;
    return \%ifc
}
sub parse_pysical_interfaces {
    my $self = shift;
    my $text = shift;
    my (%ph_if );

    chomp $text;
    #1. Split text by interfaces
    my @if_texts = split /^(?=\S.+)/m, $text;
    foreach my $t (@if_texts) {
        chomp $t;
        next if !$t;
        #        diag ($t);
        my ($if_fullname, $state, $condition) = $t =~ m/^(\S+)\s+is\s+([^,]+),\s+line protocol is\s+(.*)$/m;
        #        $self->logger->error "Bad interface: ".(split /\n/,$t)[0];
        $self->logger->error( "Bad Physical interface: ".(split /\n/, $t)[0]) and  next unless $if_fullname;
        $state = 'enabled' if $state =~ /up/;
        $state = 'disabled' if $state =~ /down/;
        $condition = 'up' if $condition =~ /up/;
        $condition = 'down' if $condition =~ /down/;

        #
        my $if_names = $self->_split_inteface_name( $if_fullname );
        ################ phisical iface #############################
        my ($speed ) = $t =~ /^  .*\s+BW\s+([^,]*)[,]*.*$/m;
        my ($description) = $t =~ /^  Description:\s+(.*)$/m;
        my ($mtu) = $t =~ /^  MTU\s+(.*)\s+bytes/m;
        $ph_if{$if_names->{physical_name}} = { #name of physical interface,
            state       => $state || "Unknown", #admin status 'enabled'|'disabled'
            condition   => $condition || "Unknown", #physical link state 'up'|'down'|'unknown',
            description => $description || "", #description|mac(Linux)
            speed       => $speed || "", # 10000Mb/s| 1000  .....
            mtu       => $mtu || "", # 10000Mb/s| 1000  .....
        } unless defined $ph_if{$if_names->{physical_name}};



        #        diag $ph_if{$if_names->{physical_name}}, $if_names->{physical_name};

    }
    #    diag(\%ifc );
    #    diag(\%ph_if );
    return  \%ph_if;

}

sub getHardware {
    my $self = shift;
    my $text = $self->_getSoftHard_cached();
    my $hw_info = [ ];
    if ($text =~ m/(cisco .*?)\s+processor\s+(.*?)\s+with\s+(.*?)\s+of\s+memory/) {
        push @$hw_info,
            {
                hw_item   => 'Processor', #Hardware type, such as Memory, processor
                hw_name   => $1, #Hardware short description? such as RAM,NVRAM, CPU x86
                hw_ver    => $2, #Some ident string, such as Serial number , revision
                hw_amount => '', #meaningful value of hardware (number of CPU, memory amount etc)
            };
        push @$hw_info,
            {
                hw_item   => 'Memory', #Hardware type, such as Memory, processor
                hw_name   => 'RAM', #Hardware short description? such as RAM,NVRAM, CPU x86
                hw_ver    => '', #Some ident string, such as Serial number , revision
                hw_amount => $3, #meaningful value of hardware (number of CPU, memory amount etc)
            };
    }
    if ($text =~ m/(\w* bytes)\s+of non-volatile configuration memory/) {
        push @$hw_info,
            {
                hw_item   => 'Memory', #Hardware type, such as Memory, processor
                hw_name   => 'NVRAM', #Hardware short description? such as RAM,NVRAM, CPU x86
                hw_ver    => '', #Some ident string, such as Serial number , revision
                hw_amount => $1, #meaningful value of hardware (number of CPU, memory amount etc)
            };
    }
    if ($text =~ m/(\w* bytes).*?Flash.PCMCIA.*?at.(slot \d?)/) {
        push @$hw_info,
            {
                hw_item   => 'Memory', #Hardware type, such as Memory, processor
                hw_name   => 'Flash PCMCIA', #Hardware short description? such as RAM,NVRAM, CPU x86
                hw_ver    => $2, #Some ident string, such as Serial number , revision
                hw_amount => $1, #meaningful value of hardware (number of CPU, memory amount etc)
            };
    }
    if ($text =~ m/(\w* bytes).*?ATA.PCMCIA.*?at.(slot \d?)/) {
        push @$hw_info,
            {
                hw_item   => 'Memory', #Hardware type, such as Memory, processor
                hw_name   => 'ATA PCMCIA', #Hardware short description? such as RAM,NVRAM, CPU x86
                hw_ver    => $2, #Some ident string, such as Serial number , revision
                hw_amount => $1, #meaningful value of hardware (number of CPU, memory amount etc)
            };
    }
    if ($text =~ m/(\w* bytes).*?System flash\s\((.*?)\)/) {
        push @$hw_info,
            {
                hw_item   => 'Memory', #Hardware type, such as Memory, processor
                hw_name   => 'System Flash', #Hardware short description? such as RAM,NVRAM, CPU x86
                hw_ver    => $2, #Some ident string, such as Serial number , revision
                hw_amount => $1, #meaningful value of hardware (number of CPU, memory amount etc)
            };
    }
    if ($text =~ m/(\w* bytes).*Flash.internal.*(SIMM)/) {
        push @$hw_info,
            {
                hw_item   => 'Memory', #Hardware type, such as Memory, processor
                hw_name   => 'internal Flash', #Hardware short description? such as RAM,NVRAM, CPU x86
                hw_ver    => $2, #Some ident string, such as Serial number , revision
                hw_amount => $1, #meaningful value of hardware (number of CPU, memory amount etc)
            };
    }

    if ($text =~ m/Processor board (ID\s+.*?)[,\s]/) {
        push @$hw_info,
            {
                hw_item   => 'Hardware', #Hardware type, such as Memory, processor
                hw_name   => 'Processor board', #Hardware short description? such as RAM,NVRAM, CPU x86
                hw_ver    => $1, #Some ident string, such as Serial number , revision
                hw_amount => '', #meaningful value of hardware (number of CPU, memory amount etc)
            };
    }
    return $hw_info;

}
sub getSoftware {
    my $self = shift;
    my $text = $self->_getSoftHard_cached();
    my $sw_info = [ ];

    if ($text =~ m/(IOS\s+.*?\s+Software.*?),.*?Version\s+(.*?),/) {
        push @$sw_info, {
                sw_item => 'Operating system', #type of software (Operating system, Firmware, Software)
                sw_name => $1,
                sw_ver  => $2,
            }
    }
    if ($text =~ m/(ROM:\s+.*?),\s+Version\s+(.*?),/) {
        push @$sw_info, {
                sw_item => 'Firmware', #type of software (Operating system, Firmware, Software)
                sw_name => $1,
                sw_ver  => $2,
            };
    }
    if ($text =~ m /(BOOT.*?:.*?),\s+Version\s+(.*?),/) {
        push @$sw_info, {
                sw_item => 'Firmware', #type of software (Operating system, Firmware, Software)
                sw_name => $1,
                sw_ver  => $2,
            };
    }
    if ($text =~ m /System image.*?"(.*?)"/) {
        push @$sw_info, {
                sw_item => 'Firmware', #type of software (Operating system, Firmware, Software)
                sw_name => 'System image',
                sw_ver  => $1,
            };
    }
    return $sw_info;

}

sub getConfig {
    my $self = shift;
    $running_config_lines ||= $self->_get_running_conf;
    return      $running_config_lines;
}
#===================== Plugin reuired
sub ping {
    my $self = shift;
    diag $self;
}
sub getModuleName {
    return __PACKAGE__;
}
#==================== Hlpers
sub _run_system {
    my $self = shift;
    my $cmd = shift;
    return `$cmd`;
}
sub _getSoftHard_cached{
    my $self = shift;
    $version_lines ||= $self->session->macro( 'getHardware' );
    return $version_lines;
}
sub _split_inteface_name {
    my $self = shift;
    my $ifname = shift;
    return { 'logical_name' => $1, 'physical_name' => $2 } if ($ifname =~ m/^(.+?)\.(.+?)$/);
    return { 'logical_name' => $ifname, 'physical_name' => $ifname };
}
sub _get_running_conf {
    my $self = shift;
    return $self->session->macro( 'getConfig' );
}
sub _getSNMPsysObjectID0_asString{
    my $self = shift;
   return $self->snmp_session->queryAny( {
           oid => 'sysObjectID.0'
       } );
}
1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
