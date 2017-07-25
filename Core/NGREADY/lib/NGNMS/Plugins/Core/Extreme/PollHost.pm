package NGNMS::Plugins::Core::Extreme::PollHost;
use strict;
use warnings FATAL => 'all';
use Moo;
use Emsgd qw(diag);
use File::Basename;
use Net::Netmask;
with "NGNMS::App::PollHostPluginInterface";
with  "NGNMS::App::Helpers";
with  "NGNMS::Log4Role";

my $software_lines = undef;
my $hardware_lines = undef;
sub BUILD {
    $software_lines = undef;
    $hardware_lines = undef;
}

sub checkCanPollHost() {
    return 1;
}

sub beforeProcessing {
    return 1;
}
sub getConfig {
    my $self = shift;
    return $self->session->macro( 'getConfig' );
}

sub checkSNMPsysObjectID {
    my $self = shift;
    my $mib = shift;
    return $mib =~ /1\.3\.6\.1\.4\.1\.1916\..*/;
}

sub checkDeviceSupported {
    my $self = shift;
    my $host_type = shift;
    return $host_type =~ m/^[Ee]xtreme$/;
}

sub prepare_connection{
    my $self = shift;
    my $params = shift;
    my $dirname = dirname(__FILE__);
    $params->{personality} = 'extremexos';
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
    return 'Extreme';
}
sub getLocation {
    my $self = shift;
    my $lines = $self->get_software();
    my ($hostname) = $lines =~ /^SysLocation:\s+(.*?)$/m;
    return $hostname;
}

sub getHostName {
    my $self = shift;
    my $lines = $self->get_software();
    my ($hostname) = $lines =~ /^SysName:\s+(.*?)$/m;
    return $hostname;
}

sub getModel {
    my $self = shift;
    my $lines = $self->get_software();
    my ($hostname) = $lines =~ /^System\s+Type:\s+(.*?)$/m;
    #    diag ($switch_lines);
    return $hostname;
}
sub getHardware {
    my $self = shift;
    my $text = $self->get_hardware();
    my @lines = split('\n', $text);
    my $hw_info = [ ];
    foreach my $line (@lines) {
        chomp ($line);
        my ($item, $name) = $line =~ /^(Slot\S+|Switch|PSU\S+)\s+:\s+(.*?)$/;
        push @$hw_info,
            {
                hw_item   => $item, #Hardware type, such as Memory, processor
                hw_name   => $name, #Hardware short description? such as RAM,NVRAM, CPU x86
                hw_ver    => '', #Some ident string, such as Serial number , revision
                hw_amount => '', #meaningful value of hardware (number of CPU, memory amount etc)
            } if $item && $name;
    }
    #        diag($hw_info);
    return $hw_info;
}
sub getSoftware {
    my $self = shift;
    my $sw_info = [ ];
    my ($text, @lines);
    $text = $self->get_hardware();
    @lines = split('\n', $text);
    foreach my $line (@lines) {
        chomp ($line);
        my ($name, $ver) = $line =~ /^(BootROM|Diagnostics)\s+:\s+(.*?)$/;
        push @$sw_info, {
                sw_item => 'Firmware', #type of software (Operating system, Firmware, Software)
                sw_name => $name,
                sw_ver  => $ver,
            } if $name && $ver
    }
    $text = $self->get_software();
    @lines = split('\n', $text);
    foreach my $line (@lines) {
        chomp ($line);
        my ($name, $ver);
        ($name, $ver) = $line =~ /^((?:Image|Config|.+\sver).*?)\s*:\s+(.*?)$/;
        ($name, $ver) = $line =~ /^(.+\.cfg)\s+(.*?)$/ if !$name || !$ver;
        push @$sw_info, {
                sw_item => 'ExtremeXOS', #type of software (Operating system, Firmware, Software)
                sw_name => $name,
                sw_ver  => $ver,
            } if $name && $ver;

    }
    #            diag($sw_info);
    return $sw_info;
}
#==================== Hlpers
sub get_software {
    my $self = shift;
    return $software_lines ||= $self->session->macro( 'getSoftware' );

}

sub get_hardware {
    my $self = shift;
    return $hardware_lines ||= $self->session->macro( 'getHardware' );
}

sub getInterfaces {
    my $self = shift;
    my ($ph_if, $ifc, $t);
    my $ph_interfaces_text = $self->session->macro( 'getPhysicalInterfaces' );
    $ph_if = $self->parse_pysical_interfaces( $ph_interfaces_text );
    my $vlans_text = $self->session->macro( 'getLogicalInterfaces' );
    ($t, $ifc) = $self->parse_logical_interfaces( $vlans_text, $ph_if );

    return ($ph_if, $ifc);
}
sub parse_logical_interfaces {
    my $self = shift;
    my $text = shift;
    my $ph_if = shift;
    my (%ifc);
    return undef unless $text;
    chomp $text;
    #check if we have sub-vlans and exclude? /Sub-VLANs:\s+(.*?)\n\S+/
    #        diag($ph_if);
    my @if_texts = split /^(?=VLAN Interface.+)/m, $text;
    foreach my $if_text (@if_texts) {
        chomp $if_text;
        next if !$if_text;
        #        diag($if_text);
        my ($if_fullname) = $if_text =~ /^VLAN Interface with name\s+(\S+)?/;
        $self->logger->error( "Bad Physical interface: ".(split /\n/, $if_text)[0]) and next unless $if_fullname;
        my ($admin_state, $tag) = $if_text =~ /Admin State:\s+(\S+).*?Tag\s+(\d+)/;
        $admin_state = $admin_state eq 'Enabled' ? 'enabled' : 'disabled';
        my $description = $if_text =~ /Description:\s+(.*?)\s+?$/m && ($1 || '');

        #TODO Get Virtual routers info
        #inject Virtual Router as Physical
        #        my ($vr) = $if_text =~ /Virtual router:\s+(\S+)/;

        #extend physical with vlanname.tag
        my $phif_name = $if_fullname.'.'.$tag;
        $ph_if->{$phif_name} = { #name of physical interface,
            state       => 'enabled', #admin status 'enabled'|'disabled'
            condition   => 'up', #physical link state 'up'|'down'|'unknown',
            description => $description, #description|mac(Linux)
            speed       => 'Uncpecified', # 10000Mb/s| 1000  .....
            mtu => 'Unapplicable',
        } unless $ph_if->{$phif_name};

        my @ip_mask;
        if ($if_text =~ /Primary IP:\s+(\d+\.\d+\.\d+\.\d+\/\d+)/) {
            push @ip_mask, ($1);
            push @ip_mask, ($1 =~ /(\d+\.\d+\.\d+\.\d+\/\d+)/g) if ($if_text =~ /Secondary IPs:\s+(.*?)^\s*$/ms);
        }
        #        diag(\@ip_mask);

        my $ip_count = scalar(@ip_mask);
        my $if_alias = 0;
        for my $ipm (@ip_mask) {
            my ($ip) = $ipm =~ /(\d+\.\d+\.\d+\.\d+)/;
            my $mask = Net::Netmask->new( $ipm )->mask;
            my $logic_name = $ip_count > 1 ? $phif_name.':'.$if_alias++ : $phif_name;
            $ifc{$logic_name } = { #name of logical interface
                physical_interface_name => $phif_name, #name of the physical interface this interface is attahed to
                ip                      => $ip, #ip daress
                mask                    => $mask, #network mask in  255.255.255.255 form
                description             => $description, #description|Admin state for linux

            };
        }

    }
    #    diag (\%ifc);
    return ($ph_if, \%ifc);
}
sub parse_pysical_interfaces {
    my $self = shift;
    my $text = shift;
    my (%ph_if);
    return undef unless $text;
    chomp $text;
    my @if_texts = split /^(?=Port.+)/m, $text;
    foreach my $if_text (@if_texts) {
        chomp $if_text;
        next if !$if_text;
        my ($if_fullname, $dispaly_string) = $if_text =~ /^Port:\s+([\w\:]+)(?:(\(.*?\)):)?/m && ('Port '.$1, $2 || '');
        $self->logger->error( "Bad Physical interface: ".(split /\n/, $if_text)[0]) and next unless $if_fullname;
        my ($admin_state, $admin_spped) = $if_text =~ /Admin state:\s+(\w+)(?:\s+with\s+(\w+))?/m && (
                $1 eq 'Enabled' ? 'enabled' : 'disabled', $2  );
        my ($link_state, $link_speed) = $if_text =~ /Link State:\s+(\w+)(?:,\s+(\w+))?/m && (
                $1 eq 'Active' ? 'up' : 'down', $2 || $admin_spped || 'Unspecified');
        my ($description) = $if_text =~ /Description String:\s+\"(.*?)\"/m && ($1 || '');
        $dispaly_string = $dispaly_string.': ' if $dispaly_string && $description;
        $ph_if{$if_fullname} = { #name of physical interface,
            state       => $admin_state, #admin status 'enabled'|'disabled'
            condition   => $link_state, #physical link state 'up'|'down'|'unknown',
            description => $dispaly_string.$description, #description|mac(Linux)
            speed       => $link_speed, # 10000Mb/s| 1000  .....
            mtu => 'Unapplicable',
        };

    }
    #        diag \%ph_if;
    return \%ph_if;
}
# -----------------------------------
sub ping {
    my $self = shift;
    diag $self;
}
sub getModuleName {
    return __PACKAGE__;
}


1;