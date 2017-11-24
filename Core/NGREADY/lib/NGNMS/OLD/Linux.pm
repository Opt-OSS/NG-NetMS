#
# NextGen NMS
#
# NGNMS::OLD::NGNMS_Linux.pm: interfacing with Linux servers
#
# Copyright (C) 2002,2003 OptOSS LLC
# Copyright (C) 2014 Opt/Net BV
#
# Author: T.Matselyukh, A. Jaropud
#

package NGNMS::OLD::Linux;

use strict;
use warnings;

no warnings qw(redefine);  # !!! SUPPRESS Subroutine new redefined at warniongs

use Net::Telnet;
use Net::OpenSSH;
use Data::Dumper;
use NGNMS::OLD::DB;
use NGNMS::Log4;
use NGNMS::OLD::Util;
use JSON::Parse 'json_file_to_perl';
#@depricated
use Net::IPv4Addr; #TODO get read of
use Net::Netmask;
use Emsgd qw(diag);

my $module_version = '3.4.1';
#print "using NGNMS::OLD::NGNMS_Linux.pm, version $module_version\n";

require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $data);

@ISA = qw(Exporter AutoLoader);

## set the version for version checking; uncomment to use
$VERSION = 3.41;

use constant NR_DEFAULT_ROUTE4 => '0.0.0.0/0';
use constant NR_DEFAULT_ROUTE6 => '::/0';
use constant NR_LOCAL_ROUTE4 => '0.0.0.0';
use constant NR_LOCAL_ROUTE6 => '::';

our %EXPORT_TAGS = (
    constants => [ qw(
        NR_DEFAULT_ROUTE4
        NR_DEFAULT_ROUTE6
        NR_LOCAL_ROUTE4
        NR_LOCAL_ROUTE6
        ) ],
);

@EXPORT = qw(
    &linux_parse_version
    &linux_parse_config
    &linux_get_interfaces
    &linux_get_topologies
    &linux_get_configs
    );

# your exported package globals go here,
# as well as any optionally exported functions
@EXPORT_OK = qw($data @{$EXPORT_TAGS{constants}});

my $Log = NGNMS::Log4->new();
my $logger = $Log->get_new_category_logger(__PACKAGE__);

$data = "my data";

# Preloaded methods

my $session;
my $Error;
my $username;
my $password;
my $timeout = 10;                                        # network operations and command timeout
my $cmd2 = 'ls /tmp/mc-ngnms';
my $debug = 0;
my $src_folder_name = '/tmp/mc-ngnms';
my $dst_folder_name = '/var/www/ngnms_perl/test';



sub host {
    if ($_[0]->_access eq 'Telnet')
    {
        $_[0]->opened ? $_[0]->_socket->host : undef
    }
    else
    {
        $_[0]->_socket->host
    }
}
sub logged_in {
    $_[0]->{'logged_in'}
}
sub _access {
    $_[0]->{'t_access'}
}
sub _socket {
    $_[0]->{'socket'}
}

sub opened {
    if ($_[0]->_access eq 'Telnet')
    {
        $_[0]->_socket && $_[0]->_socket->opened
    }
    else {
        1
    }
}
sub errmsg {
    $_[0]->{'error'}
}

sub new {
    my $type = shift;
    my $host = shift;
    my $username = shift;
    my $password = shift;
    my $enpassword = shift;
    my $access = shift;
    my $path_to_key = shift;
    my $passphrase = shift;
    my $model;

    $Error = '';
    if ($access eq 'Telnet')
    {
        $model = new Net::Telnet( errmode => 'return', host => $host, Timeout => 10 );
        ##		$model->login($username, $passwds[0]) or return warn "$host: ",$model->errmsg,"\n";
    }
    else
    {

        $model = Net::OpenSSH->new( $host,
            user        => $username,
            password    => $password,
            timeout     => $timeout,
            master_opts => [ -o => "StrictHostKeyChecking=no" ] );

        $model->error and $logger->error( "Unable to connect to remote Linux host:\n".$host.": ".$model->error);

    }

    my $self = {
        'socket'       => $model,
        'logged_in'    => 0,
        'prompt'       => '',
        'error'        => '',
        'last_command' => '',
        't_access'     => $access
    };
    bless $self, $type;

    return $self;

}

sub open()
{
    my $self = shift;
    my $host = shift;
    my $username = shift;
    my @passwords = @_;
    $self->close if $self->logged_in;

    $debug = 0 if !defined( $debug );

    $logger->info(  "connecting to Linux host $host") if $debug > 0;
    if ($self->_access eq 'Telnet')
    {
        $self->_socket->open( $host );
        $self->_socket->login( $username, $passwords[0] ) or return $self->_set_error( $self->_socket->errmsg );
        $self->{'logged_in'} = 1;
    }
    else
    {
        $self->{'logged_in'} = 1;
        return $self;
    }
    return undef; # NOT REACHED
}

sub _set_error {
    my $self = shift;
    $Error = pop;
    $self->{'error'} = $Error;
}


sub close {
    my $self = shift;
    $Error = '';
    if (defined( $self->_socket ))
    {
        if ($self->_access eq 'Telnet')
        {
            if ($self->opened) {
                $self->_socket->cmd( String => 'quit', Timeout => 2 ) if $self->logged_in;
                $self->_socket->close;
                $$self{'logged_in'} = 0;
                ##				$self->prompt('');
            }
        }
        else
        {
            $self->_socket->system( "exit" );
            $$self{'logged_in'} = 0;
        }
    }

    return $self;
}
sub linux_create_session {
    my ($host, $username) = @_[0 .. 1];
    $Log->put_debug_key('host',$host);
    my $password = $_[2];
    my $enpassword = $_[3];
    my $access = $_[4];

    $Error = undef;
    if ($access eq "Telnet")
    {
        $session = new Net::Telnet ( Errmode => 'return', Host => $host );
        ##      $session->errmode('return');
        if (defined( $session )) {
            $session->login( $username, $password );
        }
    }
    else
    {
        $session = Net::OpenSSH->new( $host,
            user        => $username,
            password    => $password,
            timeout     => $timeout,
            master_opts => [ -o => "StrictHostKeyChecking=no" ] );
        ##	$session->error and die "Unable to connect to remote host: " . $session->error;
    }
    return $session;
}

sub linux_get_topologies{
    my ($host, $username, $password, $enablepw, $access) = @_[0 .. 4];
    my @nets;

    my $sess = linux_create_session( $host, $username, $password, $enablepw, $access );

    if (!defined( $sess )) {
        return "NGNMS_Linux - get_topologies - unable to connect: $host";
    }

    if ($access eq 'Telnet') {
        if ($sess->errmsg) {
            #			print "NGNMS::OLD::NGNMS_Linux - get_topologies - unable to connect via Telnet: $host",$sess->errmsg;
            return "NGNMS_Linux - get_topologies - unable to connect via Telnet: $host --", $sess->errmsg;
        }
    } else {
        if ($sess->error) {
            return "NGNMS_Linux - get_topologies - unable to connect via SSH: $host --".$sess->error;
        }
    }

    #    return $sess;

    if ($access eq 'Telnet') {
        @nets = $sess->cmd( "netstat -rn" );
        if ($sess->errmsg) {
            return  "NGNMS_Linux - get_topologies - remote netstat command execution failed: ", $sess->errmsg;
        }
    } else {
        @nets = $sess->capture( "netstat -rn" );
        if ($sess->error) {
            return "NGNMS_Linux - get_topologies - remote netstat command output capture failed: ".$sess->error;
        }
    }
    #    Emsgd::diag(\@nets);

    if ($access eq 'Telnet') {
        $sess->cmd( "exit" );
    } else {
        $sess->system( "exit" );
    }
    my @routes = ();
    my %cache = ();
    my %host_ips;
    my %links;
    my $state = '';
    my $DR = '';
    for my $line (@nets) {
        my @toks = split( /\s+/, $line );
        my $route = $toks[0];
        my $gateway = $toks[1];
        my $netmask = $toks[2];
        my $flags = $toks[3];
        my $mss = $toks[4];
        my $window = $toks[5];
        my $irtt = $toks[6];
        my $interface = $toks[7];

        if (defined( $route ) && defined( $gateway ) && defined( $interface )
            && defined( $netmask )) {
            # A first sanity check to help Net::IPv4Addr
            if ($route !~ /^[0-9\.]+$/ || $gateway !~ /^[0-9\.]+$/
                || $netmask !~ /^[0-9\.]+$/) {
                next;
            }

            eval {
                my ($ip1, $cidr1) = Net::IPv4Addr::ipv4_parse( $route );
                my ($ip2, $cidr2) = Net::IPv4Addr::ipv4_parse( $gateway );
                my ($ip3, $cidr3) = Net::IPv4Addr::ipv4_parse( $netmask );
            };
            if ($@ && $debug > 0) {
                chomp( $@ );
                $logger->debug( "*** DEBUG - Not valid line [$@]");
                next;                                                                   # Not a valid line for us.
            }

            # Ok, proceed.
            my %route = (
                route     => $route,
                gateway   => $gateway,
                interface => $interface,
            );

            # Default route
            if ($route eq '0.0.0.0' && $netmask eq '0.0.0.0') {
                $route{default} = 1;
                $route{route} = NR_DEFAULT_ROUTE4();
            }
            else {
                my ($ip, $cidr) = Net::IPv4Addr::ipv4_parse( "$route / $netmask" );
                $route{route} = "$ip/$cidr";
            }

            # Local subnet
            if ($gateway eq '0.0.0.0') {
                $route{local} = 1;
                $route{gateway} = NR_LOCAL_ROUTE4();
            }

            my $id = _to_psv( \%route );
            if (!exists( $cache{$id} )) {
                push @routes, \%route;
                $cache{$id}++;
            }
        }
    }
    #    Emsgd::diag(\@routes);
    NGNMS::OLD::DB::DB_addHostNoWrite( \%host_ips, $host );
    NGNMS::OLD::DB::DB_addHostIP( \%host_ips, $host, $host );
    for my $route(@routes) {
        if ($route->{default} || $route->{gateway} && $route->{gateway} ne '0.0.0.0') {
            my $ip = $route->{gateway};
            $DR = $ip;
            NGNMS::OLD::DB::DB_addHostNoWrite( \%host_ips, $DR );
            NGNMS::OLD::DB::DB_addHostIP( \%host_ips, $DR, $ip );
            NGNMS::OLD::DB::DB_addLinkNoWrite( \%links, $host, $DR, "B" );
        }
    }
    #    Emsgd::diag(\%links);
    #    Emsgd::diag(\%host_ips);
    NGNMS::OLD::DB::DB_writeTopology( \%host_ips, \%links );
    NGNMS::OLD::DB::DB_setHostVendorByIP( $host, 'Linux' );

    return "ok";

}

sub _to_psv {
    my ($route) = @_;

    my $psv = $route->{route}.'|'.$route->{gateway}.'|'.$route->{interface}.'|'.
        (exists( $route->{default} ) ? '1' : '0').'|'.(exists( $route->{local} ) ? '1' : '0');

    return $psv;
}
sub linux_get_configs()
{
    return 'ok';
}
sub linux_parse_config
{

    return "ok";
}


sub run_proccessing_alone
{
    my $self = shift;
    my $new_rid;
    my $linux_compname = $self->linux_parse_name();
    $new_rid = DB_getRouterId( $linux_compname );
    if (!defined( $new_rid )) {
        $new_rid = DB_addRouter( $linux_compname, $self->_socket->{_host}, 'unknown' );
        DB_setHostVendor( $new_rid, 'Linux' );
    }
    return $new_rid;

}
sub saveCommonInfo($) {
    my $self = shift;
    my $new_rid = shift;

    my %sw_info = (    "sw_item" => undef,
        "sw_name"                => undef,
        "sw_ver"                 => undef );

    my %hw_info = (    "hw_item" => undef,
        "hw_name"                => undef,
        "hw_ver"                 => undef,
        "hw_amount"              => undef );
    my $linux_layer = 5;
    my $linux_vendor = $self->linux_parse_vendor();
    my $linux_model = $self->linux_parse_model();
    my $linux_hardwr = $self->linux_parse_hardwr();
    my $linux_softwr = $self->linux_parse_version();

    if (!defined $linux_vendor || $linux_vendor eq '' || $linux_vendor !~ /ubuntu/i)
    {
        $linux_vendor = 'Linux';
    }
    NGNMS::OLD::DB::DB_setHostVendor( $new_rid, $linux_vendor );
    NGNMS::OLD::DB::DB_writeHostModel( $new_rid, $linux_model );

    NGNMS::OLD::DB::DB_setHostLayer( $new_rid, $linux_layer );
    %hw_info = (    "hw_item" => "processor",
        "hw_name"             => "$linux_hardwr",
        "hw_ver"              => "",
        "hw_amount"           => "" );
    NGNMS::OLD::DB::DB_startHwInfo( $new_rid );
    NGNMS::OLD::DB::DB_writeHwInfo( $new_rid, \%hw_info );

    %sw_info = (    "sw_item" => 'Operating system',
        "sw_name"             => $linux_vendor,
        "sw_ver"              => $linux_softwr);
    NGNMS::OLD::DB::DB_startSwInfo( $new_rid );
    NGNMS::OLD::DB::DB_writeSwInfo( $new_rid, \%sw_info );
};
#=for
#    get router Id by host_name, if fails, by IP
#    if fails, then reate new
#=cut
sub getThisRouterId($) {
    my $self = shift;
    my $cur_ip = shift;
    my $control_ip;
    #use hostname or IP
    my $linux_compname = $self->linux_parse_name() || $cur_ip;

    my $new_rid = NGNMS::OLD::DB::DB_getRouterId( $linux_compname );

    if (!defined( $new_rid ))
    {
        $new_rid = NGNMS::OLD::DB::DB_getRouterId( $cur_ip );
    }
    else
    {
        $control_ip = NGNMS::OLD::DB::DB_getRouterIpAddr( $new_rid );
        if ($control_ip ne $cur_ip)
        {
            $new_rid = NGNMS::OLD::DB::DB_getRouterId( $cur_ip );
        }
    }

    if (!defined( $new_rid )) {
        $new_rid = NGNMS::OLD::DB::DB_addRouter( $linux_compname, $cur_ip, 'up' );
    }
    else
    {
        NGNMS::OLD::DB::DB_replaceRouterName( $new_rid, $linux_compname );
        NGNMS::OLD::DB::DB_setHostState( $new_rid, 'up' );
        if ($cur_ip eq '0.0.0.0' && $linux_compname =~ /\d+\.\d+\.\d+\.\d+/)
        {
            NGNMS::OLD::DB::DB_updateRouterId( $new_rid, $linux_compname );
        }
    }
    return $new_rid;
}


sub parse_interfaces_ifconfig($) {
    my $self = shift;
    my $new_rid = shift;
    my $iface;
    my $line;
    my %phifc;
    my %ifc;
    my $speede;
    my %log2ph_int;
    my @linux_interfaces = $self->linux_get_interfaces_ifconfig();
    my $ph_iface;
    my $ph_int_id;
    my (%ip6, %ip, %scope6, %bcast, %mask, %hwaddr, %ipcount, %condition);
    my $iface_count = 0;
    foreach(@linux_interfaces)
    {
        $line = $_;
        #        Emsgd::diag( $line, 'line' );
        if ($line =~ m/^([a-zA-Z0-9\-\:\.]+)\s+/i) {
            # Linux interface
            #            Emsgd::diag( $line, 'line' );
            $iface = $1;
            my $secondary = $2;
            $ph_iface = [ $iface =~ m/^([a-z0-9A-Z\-]+)/i ]->[0]; # convert "eth0:0 | eth1.10" --> "eth0"
            #            Emsgd::diag($ph_iface,'ph_iface');
            $iface = [ $iface =~ m/^([a-zA-Z0-9\.\-]+)/i ]->[0]; # convert eth0:0 | eth0.100:3 --> "eth0"
            #            Emsgd::diag($iface,'iface');
            $log2ph_int{$iface} = $ph_iface;
            $ipcount{$iface}++;
            $condition{$ph_iface} = 'down';
            $iface_count++;
        }
        if (defined $iface) {
            if ($line =~ m/(?:ether|HWaddr)\s+([a-fA-F0-9:]+)/i) {
                $hwaddr{$ph_iface} = $1;
                #            Emsgd::diag($hwaddr{$ph_iface},"HW" );
            }
            if ($line =~ m/^.*?inet(?:\s+|addr:).*?(\d+\.\d+\.\d+\.\d+).*?(?:netmask\s|Mask:)(\d+\.\d+\.\d+\.\d+)/) {
                #RHEL Kernel 3.x and @.x, NO BCAST
                push @{$ip{$iface}}, $1;
                $mask{$iface} = $2;
            }

            #        if ($line =~ m/^.*?inet\saddr.*?$/) {
            # #Linux IP address
            #            Emsgd::diag( $line, 'INET4' );
            #            die unless defined $iface;
            #            my @fields = split(/[\s:]+/, $line);
            #            Emsgd::diag(\@fields,'Fields INET');
            #            push @{$ip{$iface}}, $fields[3];
            #            $bcast{$iface} = $fields[5] || ""; # invalid for loopback interface lo, but we don t need this
            #            $mask{$iface} = $fields[7] || $fields[5]; # for loopback interface lo
            #        }
            #        if ($line =~ m/^[ \t]+inet6.*?:/i) {
            #            # Linux IPv6 address
            #            die unless defined $iface;
            #            my @fields = split(/\s+/, $line);
            #            push @{$ip6{$iface}}, $fields[3];
            #            $scope6{$iface} = [ $fields[4] =~ m/Scope:(.*)$/i ]->[0];
            #        }
            if ($line =~ m/BROADCAST|LOOPBACK/i) {
                # Up/Down
                #                Emsgd::diag($ph_iface,$line);
                $condition{$ph_iface} = "up" if ($line =~ m/UP/i);
            }

        }

    }

    #    Emsgd::diag( \%hwaddr );
    #    Emsgd::diag( \%condition );
    #    Emsgd::diag( \%ip );
    if (exists( $ip{'lo'} )) {
        # add pseudo-mac to lo so it become true phisical iface
        $hwaddr{'lo'} = '00:00:00:00:00:00';
    }
    foreach my $k1(keys %hwaddr)
    {
        $speede = $self->linux_parse_speed_interface_ifconfig( $k1 );

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

        @phifc{("interface", "state", "condition", "speed", "description")} =
            ($k1, 'enabled', $condition{$k1}, $speede, $hwaddr{$k1});
        DB_writePhInterface( $new_rid, \%phifc );
    }
    #    Emsgd::diag(\%ip);
    #    Emsgd::diag(\%log2ph_int);
    foreach my $k (keys %ip) {
        {
            foreach my $lip (@{$ip{$k}}) {
                next if $lip eq '127.0.0.1';
                $ph_int_id = DB_getPhInterfaceId( $new_rid, $log2ph_int{$k} );
                @ifc{("interface", "ip address", "mask", "description")} =
                    ($k, $lip, $mask{$k}, '');
                DB_writeInterface( $new_rid, $ph_int_id, \%ifc );
                if ($k eq 'eth0')
                {
                    DB_updateRouterId( $new_rid, $ip{$k}->[0] );
                }
            }
        }
    }
}
#=for
#    split interface name into
#    {
#        'physical_name' => 'eth1',
#        'logical_name' => 'eth1'
#    };
#
#=cut
sub split_inteface_name($) {
    my $self = shift;
    my $ifname = shift;
    $ifname =~ m/^(.+?)\@(.+?)$/;
    return { 'logical_name' => $1, 'physical_name' => $2 } if ($ifname =~ m/^(.+?)\@(.+?)$/);
    return { 'logical_name' => $ifname, 'physical_name' => $ifname };
}
sub get_interfa_state($) {
    my $self = shift;
    my $str = shift;
    return lc( $1 ) if $str =~ /\W(UP|DOWN)\W/;
    return 'unknown';
}
sub parse_interfaces($) {
    my $self = shift;
    my $text = shift;

    my (%ifc, %ph_if);
    #########################  split by interface
    for  my $n (split /^[^\s]:/m, $text) {
        chomp $n;
#        diag $n;
        next if !$n;
        my ($if_fullname, $full_state, $condition, $link_type, $mac) =
            $n =~ m/^\s*(.*?):.*?(<.*?>).*?\sstate\s(\w+).*?\n\s+link\/(.*?)\s(.*?)\s/mg;
#        diag("$if_fullname, $full_state, $condition, $link_type, $mac");
        next unless $if_fullname;
        my $if_names = $self->split_inteface_name( $if_fullname );
        $condition = $condition eq 'UP' ? 'enabled'
                                        : ($condition eq 'DOWN' ? 'disabled' : $condition);
        ################ phisical iface #############################
        $ph_if{$if_names->{physical_name}} = {
            state     => $self->get_interfa_state( $full_state ),
            condition => $condition,
            description     => $mac
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
                description                   => $condition
            };
        };
    };
    return  (\%ph_if, \%ifc );
}


sub process_interfaces($$){
    my $self = shift;
    my $rt_id = shift;
    my $text = shift;


    NGNMS::OLD::DB::DB_markPhInterfacesToBePolled($rt_id);
    my ($ph_if, $ifc ) = $self->parse_interfaces($text);
    ######## Pysical #################
    while (my ($phys_in_name, $data) = each %$ph_if){
            $data->{speed} = $self->linux_parse_speed_interface($phys_in_name);
            $data->{interface} = $phys_in_name;
            $data->{phys_id} =NGNMS::OLD::DB::DB_writePhInterface($rt_id,$data);
            $logger->error( "error adding physical interface $phys_in_name to $rt_id") unless $data->{phys_id};
#            diag $data;
    }
    NGNMS::OLD::DB::DB_deletePhInterfacesPolledButNotFound($rt_id);

    NGNMS::OLD::DB::DB_markInterfacesToBePolled($rt_id);
    ######## Logical #################
    while (my ($logic_name,$data) = each %$ifc){
        my $ph_int_id =$ph_if->{$data->{physical_interface_name}}->{phys_id};
        if(!$ph_int_id ){
            $logger->error( "error adding logical $logic_name interface to $rt_id");
            next;
        }
        my $struct ={
            'interface'=> $logic_name,
            'ip address'=>$data->{ip},
            'mask'=>$data->{mask},
            'description'=> $data->{description},
        };
        NGNMS::OLD::DB::DB_writeInterface($rt_id,$ph_int_id,$struct);
        #            diag $data;
    }
    NGNMS::OLD::DB::DB_deleteInterfacesPolledButNotFound($rt_id);
}
#=for
#    main processing procedure
#
#=cut

sub run_proccessing
{
    my $self = shift;
    my $cur_ip = shift;
    my $new_rid = $self->getThisRouterId( $cur_ip );
    $self->saveCommonInfo( $new_rid );
    my $interfaces_text = $self->linux_get_interfaces();
    $self->process_interfaces( $new_rid, $interfaces_text );
}

sub linux_parse_vendor {

    my $self = shift;
    my @lines = $self->linux_cmd( 'uname -s' );
    #    diag(\@lines);
    return parse_res( $lines[0], 0 );
}
sub linux_parse_model {
    #http://linuxmafia.com/faq/Admin/release-files.html
    my $self = shift;
    my $lines = $self->linux_cmd( "cat   /etc/*-rel* /etc/*_ver*" );
    #    my $lines = $self->linux_cmd( "rpm -qa | grep release" );
    my @ret = split( /\n/, $lines );
    my @model = grep {/release/} @ret;
    return substr( $model[0], 0, 49 ) || 'Unknown' if @model;
    @model = grep {/PRETTY/} @ret;
    if (@model) {
        return $1 if $model[0] =~ m/PRETTY_NAME="(.*?)"/;
    }
    return 'Unknown';
}

sub linux_parse_version {

    my $self = shift;
    my @lines = $self->linux_cmd( 'uname -r' );
    return parse_res( $lines[0], 0 );
}

sub linux_parse_name
{
    my $self = shift;
    my @lines = $self->linux_cmd( 'uname -n' );

    return parse_res( $lines[0], 0 );
}

sub linux_parse_hardwr {

    my $self = shift;
    my @lines = $self->linux_cmd( 'uname -m' );

    return parse_res( $lines[0], 0 );
}

sub linux_parse_speed_interface {
    my $self = shift;
    my $interface_name = shift;
    my $ret_val;
    #in some cases we could get 'Cannot get wake-on-lan settings: Operation not permitted  ' into STDERROR, so 2>/dev/null
    #    my $cmd1 = "ethtool $interface_name 2>&1 | awk '/Speed/ {sub(/:/,\"\",\$2);print \$2}'";
    my $cmd1 = "PATH=\$PATH:/usr/sbin  ethtool $interface_name 2>/dev/null| grep Speed |awk '{print \$2}'";
    my @lines = $self->linux_cmd( $cmd1 );
    my $speede = $lines[0];
    #    Emsgd::diag(\@lines, $cmd1);
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
sub linux_parse_speed_interface_ifconfig {
    my $self = shift;
    my $interface_name = shift;
    my $ret_val;
    #in some cases we could get 'Cannot get wake-on-lan settings: Operation not permitted  ' into STDERROR, so 2>/dev/null
    #    my $cmd1 = "ethtool $interface_name 2>&1 | awk '/Speed/ {sub(/:/,\"\",\$2);print \$2}'";
    my $cmd1 = "PATH=\$PATH:/usr/sbin  ethtool $interface_name 2>/dev/null| grep Speed |awk '{print \$2}'";
    my @lines = $self->linux_cmd( $cmd1 );

    #    Emsgd::diag(\@lines, $cmd1);
    return $lines[0];
}

sub parse_res()
{
    my $val = shift;
    my $first_s = shift;
    my $retval;
    if (defined $val && $val ne '')
    {
        $val =~ s/^\s+//;            # no leading white
        $val =~ s/\s+$//;            # no trailing white
        my @arr_val = split( / /, $val );
        $retval = substr $arr_val[0], $first_s;
    }
    else
    {
        $retval = '';
    }

    return $retval;
}
sub linux_get_interfaces()
{
    my $self = shift;

    #  my @lines  = $self->linux_cmd('/sbin/ifconfig -a | sed -n '."'".'s/^\([^ ]\+\)'.'.'.'*/"\1"/p'."'".' | paste -sd ","'."'") ;
    my $text = $self->linux_cmd( 'ip address show' );
    return $text;
}
sub linux_get_interfaces_ifconfig()
{
    my $self = shift;

    #  my @lines  = $self->linux_cmd('/sbin/ifconfig -a | sed -n '."'".'s/^\([^ ]\+\)'.'.'.'*/"\1"/p'."'".' | paste -sd ","'."'") ;
    my @lines = $self->linux_cmd( '/sbin/ifconfig -a' );
    return @lines;
}
#
# parse 'show running config' output
#
# Params:
#  router_id
#  run config file



#
# Params:
#  router_id
#  interfaces file

#sub linux_parse_interfaces {
#
#    return "ok";
#}

sub linux_cmd()
{
    $session = shift;
    my $cmd = shift;

    if ($session->_access eq 'Telnet')
    {
        return $session->_socket->cmd( $cmd );
    }
    else
    {
        return eval {
            $session->_socket->capture( $cmd )
        };
    }
}

# END { print "deleting NGNMS::OLD::NGNMS_Linux\n" };



1;
# ABSTRACT: This file is part of open source NG-NetMS tool.

__END__
