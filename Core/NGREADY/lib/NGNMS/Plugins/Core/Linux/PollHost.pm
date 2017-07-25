package NGNMS::Plugins::Core::Linux::PollHost;
use strict;
use warnings FATAL => 'all';
use Moo;
use Emsgd qw(diag);
use File::Basename;
use Net::Netmask;
with "NGNMS::App::PollHostPluginInterface";
with  "NGNMS::App::Helpers";

sub checkCanPollHost() {
    return 1;
}

sub beforeProcessing {
    return 1;
}
sub getConfig {
    return "Configuration not collected for Linux\n";
}

sub checkSNMPsysObjectID {
    my $self = shift;
    my $mib = shift;
    return $mib =~ /1\.3\.6\.1\.4\.1\.8072\..*/;
}
sub checkDeviceSupported {
    my $self = shift;
    my $host_type = shift;
    return $host_type =~ m/^[Ll]inux$/;
}

sub prepare_connection{
    my $self = shift;
    my $params = shift;
    my $dirname = dirname(__FILE__);
    $params->{personality} = 'bash';
    $params->{add_library} = $dirname.'/phrasebook/';
    $params->{requires_privileged} = 0;
    $params->{privileged_paging} = 0;
    $params->{wake_up} = 0;
    return $params;
}

sub getIpLayer {
    return 5;
}

sub getVendor {
    return 'Linux';
}

sub getModel {
    my $self = shift;

    my $lines = $self->session->macro( 'getModel' );
    my @ret = split( /\n/, $lines );
    my @model = grep {/release/} @ret;
    return substr( $model[0], 0, 49 ) || 'Unknown' if @model;
    @model = grep {/PRETTY/} @ret;
    if (@model) {
        return $1 if $model[0] =~ m/PRETTY_NAME="(.*?)"/;
    }
    return 'Unknown';
}
sub getHostName {
    my $self = shift;
    return $self->get_first_line($self->session->macro( 'getHostName' ));
}
sub getLocation {
    return '';
}
sub getHardware {
    #now returns processor by lscpu
    my $self = shift;
    my $hw_info = [ ];
    my $lines = $self->session->execute_chained_macro( qw( getHardware getMemory) );
    return undef unless scalar $lines;
    my ($hw_ver, $hw_amount, $hw_name);
    if (($hw_ver, $hw_amount, $hw_name) =
        $lines =~ m/Architecture:\s+(.*?)\n.*?CPU\(s\):\s+(.*?)\n.*?Vendor ID:\s+(.*?)\n/sg) {
        push @$hw_info,
            {
                hw_item   => 'processor', #Hardware type, such as Memory, processor
                hw_name   => $hw_name, #Hardware short description? such as RAM,NVRAM, CPU x86
                hw_ver    => $hw_ver, #Some ident string, such as Serial number , revision
                hw_amount => $hw_amount, #meaningful value of hardware (number of CPU, memory amount etc)
            }
        ;
    }
    if (
        ($hw_ver, $hw_amount) =
            $lines =~ m/Stepping:\s+(.*?)\n.*?CPU MHz:\s+(.*?)\n/
    ) {

        push @$hw_info, {
                hw_item   => 'processor', #Hardware type, such as Memory, processor
                hw_name   => 'CPU MHz', #Hardware short description? such as RAM,NVRAM, CPU x86
                hw_ver    => 'Stepping '.$hw_ver, #Some ident string, such as Serial number , revision
                hw_amount => $hw_amount, #meaningful value of hardware (number of CPU, memory amount etc)
            };
    };
    if (
        ($hw_ver, $hw_amount) =
            $lines =~ m/Hypervisor vendor:\s+(.*?)\n.*?Virtualization type:\s+(.*?)\n/
    ) {

        push @$hw_info, {
                hw_item   => 'Hypervisor', #Hardware type, such as Memory, processor
                hw_name   => 'vendor', #Hardware short description? such as RAM,NVRAM, CPU x86
                hw_ver    => $hw_ver, #Some ident string, such as Serial number , revision
                hw_amount => $hw_amount, #meaningful value of hardware (number of CPU, memory amount etc)
            };
    }
    if (($hw_amount) =
        $lines =~ m/MemTotal:\s+(.*?)\n/) {
        push @$hw_info, {
                hw_item   => 'Memory', #Hardware type, such as Memory, processor
                hw_name   => 'MemTotal', #Hardware short description? such as RAM,NVRAM, CPU x86
                hw_ver    => 'NA', #Some ident string, such as Serial number , revision
                hw_amount => $hw_amount, #meaningful value of hardware (number of CPU, memory amount etc)
            };
    }
    return $hw_info;

}
sub getSoftware {
    my $self = shift;
    my $lines = $self->session->macro( 'getSoftware' );
    my $core = $self->get_first_line( $lines );
    return undef unless $core;
    return [
        {
            sw_item => 'Operating system', #type of software (Operating system, Firmware, Software)
            sw_name => 'Kernel',
            sw_ver  => $core,
        }
    ];

}
sub getInterfaces {
    my $self = shift;
    my $interfaces_text = $self->session->macro( 'getInterfaces' );
    return $self->parse_interfaces( $interfaces_text );
}
sub parse_interfaces {
    my $self = shift;
    my $text = shift;

    my (%ifc, %ph_if);
    #########################  split by interface
    for  my $n (split /^[^\s]:/m, $text) {
        chomp $n;
        #        diag $n;
        next if !$n;
        my ($if_fullname, $full_state, $mtu, $condition, $link_type, $mac) =
            $n =~ m/^\s*(.*?):.*?(<.*?>).*?mtu\s(\d+).*?\sstate\s(\w+).*?\n\s+link\/(.*?)\s(.*?)\s/mg;
        #        diag("$if_fullname, $full_state, $condition, $link_type, $mac");
        next unless $if_fullname;
        my $if_names = $self->split_inteface_name( $if_fullname );
        $condition = $condition eq 'UP' ? 'enabled'
                                        : ($condition eq 'DOWN' ? 'disabled' : $condition);
        ################ phisical iface #############################
        $ph_if{$if_names->{physical_name}} = {
            state       => $self->get_interfa_state( $full_state ),
            condition   => $condition,
            description => $mac,
            speed       => $self->linux_parse_speed_interface( $if_names->{physical_name} ),
            mtu         => $mtu
        } unless defined $ph_if{$if_names->{physical_name}};
        ################ Logical interaces ##########################
        my @ip_mask = $n =~ m/^\s+inet\s(.*?\/\d+).+$/mg;
        my $ip_count = scalar ( @ip_mask );
        my $if_alias = 0;
        #process logical
        foreach  my $ipm (@ip_mask) {
            my ($ip, $mask) = split /\//, $ipm;
            my $logic_name = $if_names->{logical_name};
            $logic_name .= ':'.$if_alias++ if $ip_count > 1;

            $ifc{$logic_name } = {
                physical_interface_name => $if_names->{physical_name},
                ip                      => $ip,
                mask                    => Net::Netmask->new( $ipm )->mask,
                description             => $condition
            };
        };
    };
    return  (\%ph_if, \%ifc );
}
#=============================== Helpers
sub get_first_line {
    my $self = shift;
    my $lines = shift;
    return undef unless $lines;
    my ($line) = split( /\n/, $lines ); #get first line
    chomp $line;
    return $line ? $self->trim($line) : undef;
}
sub get_interfa_state {
    my $self = shift;
    my $str = shift;
    return lc( $1 ) if $str =~ /\W(UP|DOWN)\W/;
    return 'unknown';
}
sub split_inteface_name {
    my $self = shift;
    my $ifname = shift;
    return { 'logical_name' => $1, 'physical_name' => $2 } if ($ifname =~ m/^(.+?)\@(.+?)$/);
    return { 'logical_name' => $ifname, 'physical_name' => $ifname };
}
sub linux_parse_speed_interface {
    my $self = shift;
    my $interface_name = shift;
    #in some cases we could get 'Cannot get wake-on-lan settings: Operation not permitted  ' into STDERROR, so 2>/dev/null
    #    my $cmd1 = "ethtool $interface_name 2>&1 | awk '/Speed/ {sub(/:/,\"\",\$2);print \$2}'";
    my $lines = $self->session->macro( 'getInterfaceSpeed', { 'cache' => 1, params => [ $interface_name ] } );
    my ($speede) =
        $lines =~ m/Speed:\s+(.*?)\n/;
    if (defined( $speede ))
    {
        $speede =~ s/\s+$//;
        if ($speede =~ m/^Cannot/) {
            $speede = 'Unspecified';
        }
    }
    else
    {
        $speede = 'Unspecified';
    }
    return $speede;;
}



sub ping {
    my $self = shift;
    diag $self;
}
sub getModuleName {
    return __PACKAGE__;
}


1;