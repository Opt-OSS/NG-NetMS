#
# NextGen NMS
#
# NGNMS_Juniper.pm: interfacing with Juniper routers
#
# Copyright (C) 2002,2003 OptOSS LLC
#
# Author: M.Golov
#

package NGNMS::Host::Juniper;

use strict;
use warnings;

# use Data::Dumper;
use NGNMS::OLD::DB;
use NGNMS::OLD::Util;
use NGNMS::Log4;
use Data::Dumper;
use File::Path qw( make_path );

use NGNMS::Net::Connect;
use Net::Appliance::Session;
use Try::Tiny;
use Emsgd qw(diag);




# $Net::Juniper::debug=1;

if (defined( $ENV{"NGNMS_TIMEOUT"} )) {
    $Net::JuniperJav::TIMEOUT = $ENV{"NGNMS_TIMEOUT"};
} else {
    $Net::JuniperJav::TIMEOUT = 60;
}

require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $data);

@ISA = qw(Exporter AutoLoader);

## set the version for version checking; uncomment to use
$VERSION = 0.01;

@EXPORT = qw(&parse_isis
    &parse_ospf
    &juniper_parse_version
    &juniper_parse_config
    &juniper_parse_interfaces
    &get_topologies
    &juniper_get_configs);

# your exported package globals go here,
# as well as any optionally exported functions
@EXPORT_OK = qw($data);

# print "loading NGNMS_Juniper\n";

# data

$data = "my data";

# Preloaded methods
my $Log = NGNMS::Log4->new();
my $logger = $Log->get_new_category_logger(__PACKAGE__);
my NGNMS::Net::Connect $session;
my $Error;
my $verbose = $ENV{"NGNMS_DEBUG"} || 0;

sub juniper_create_session {
    my $connect_params = shift;
    $connect_params->{personality}='junos';
    $connect_params->{wake_up} = 0;
    $connect_params->{connect_options} = { opts => $connect_params->{connect_options} } ;
    if (exists $connect_params->{jumphost}) {
        $connect_params->{jumphost} = Net::Appliance::Session->new(
        transport       => 'SSH',
            personality     => 'bash',
            host            => $connect_params->{jumphost}{host},
            username        => $connect_params->{jumphost}{username},
            password        => $connect_params->{jumphost}{password},
            connect_options => { opts => $connect_params->{jumphost}{connect_options} },

        );
    }
#        diag $connect_params;
    $Log->put_debug_key('host',$connect_params->{host});

    try {
            $session->close();
        }catch{};
    undef $session;
    $session = NGNMS::Net::Connect->new( $connect_params );

    return try{
            $session->connect();
            return 'ok';
        }catch{
                $Error = $_;
                $logger->error( $Error);
                #last resonce could throw exception if port was not opened :connection refused etc
                try {$Error = $session->last_response();}catch{};
        $Error =  $connect_params->{host}.": ".$Error;
                $logger->error( $Error);
                return $Error;
            };
    return $Error;
}

=pod
sub _juniper_create_session {
    my ($host, $username) = @_[0 .. 1];
    my @passwds = @_[2 .. 3];
    my $access = @_[6 .. 6];
    my $path_to_key = $_[7];

    $Error = undef;
    if (!defined($access))
    {
        $access = "Telnet";
    }
    #  print "access:".$access.";host:".$host."username=".$username.";passwd0=".$passwds[0].";passwd1=".$passwds[1]."\n";
    $session = Net::JuniperJav->new($access, $host, $username, @passwds, $path_to_key);

    if (defined($session->_socket))
    {
        $session->open($access, $host, $username, @passwds);
    }
    else
    {
        $session->_set_error("Conection with $host via $access was not established")
    }

    if ($session->{'error'} || !$session->{'logged_in'}) {
        $Error = $session->errmsg;
    }
    else {
        my $MB = 1024*1024;
        #$session->max_buffer_length(10 * $MB);
    }
}
=cut

sub juniper_get_file($$) {
    my ($cmd, $fname) = @_[0 .. 1];
    $Error = undef;

    my @data = $session->cmd( $cmd );

    if (!@data) {
#        $session->close;
        $Error = "juniper: session error";#.$session->errmsg();
        $logger->error( $Error);
        return undef;
    }
    #    print @data;
    if (!open( F_DATA, ">$fname" )) {
#        $session->close;
        $Error = "Cannot open file $fname for writing: $!";
        $logger->error( $Error);
        return undef;
    }
    print F_DATA @data;
    close ( F_DATA );
    1;
}

sub juniper_get_configs {
    #    my ($host, $username) = @_[0 .. 1];
    #    my @passwds = @_[2 .. 3];
    #    my $configPath = $_[4];
    #    my $acc = $_[6];
    #    print "Getting configs from $host\n";
    #    my @params = ($_[0], $_[1], $_[2], $_[3], '', '', $_[6]);
    #    ##  juniper_create_session(@_);
    #    Emsgd::diag (\@params);
    #    juniper_create_session(@params);

    my ($host, $username, $password, $enablepw) = @_[0 .. 3];
    my $configPath = $_[4];
    #$community = $_[5]; #this should be global, WTF
    my $access = $_[6];
    $Error = undef;
    print "Getting configs from $host\n";
    juniper_create_session( $host, $username, $password, $enablepw, $access );
    return $Error if $Error;



    # version
    #
    juniper_get_file( 'show version', $configPath."_version.txt" ) or
        return $Error;

    # hardware inventory
    #
    juniper_get_file( 'show chass hardw', $configPath."_hardware.txt" ) or
        return $Error;

    # Running config
    #
    juniper_get_file( 'show config', $configPath."_config.txt" ) or
        return $Error;

    # Interfaces
    #
    juniper_get_file( 'show interface extensive', $configPath."_interfaces.txt" ) or
        return $Error;

    $session->close;

    return "ok";
}

sub get_topologies  {
    my ($connect_params) = shift;
    #    my ($host, $username) = @_[0 .. 1];
    #    my @passwds = @_[2 .. 3];
    #    my $access = @_[4 .. 4];
    #    my @params = ($_[0], $_[1], $_[2], $_[3], '', '', $_[4]);
    my $filename1 = $connect_params->{host}."_isis.txt";
    my $filename2 = $connect_params->{host}."_ospf.txt";
    my $filename3 = $connect_params->{host}."_bgp.txt";

    juniper_create_session( $connect_params );
    return $Error if $Error;

    # specific timeout for the topology collection
    #    $session->timeout(10);

    if (defined( $ENV{"NGNMS_DATA"} )) {
        my $path = $ENV{"NGNMS_DATA"}."/topologies/";
        make_path $path ;
        $logger->logdie ("Cannot create directory $path : $!\n") unless -d $path;

        $filename1 = $path.$filename1;
        $filename2 = $path.$filename2;
        $filename3 = $path.$filename3;
    }

    $logger->info ("Getting ISIS topology");
    juniper_get_file( 'show isis database extensive', $filename1 ) or
        return $Error;

    $logger->info( "Getting OSPF topology");
    juniper_get_file( 'show ospf database extensive', $filename2 ) or
        return $Error;

    $logger->info( "Getting BGP topology");
    juniper_get_file( 'show bgp neighbor', $filename3 ) or
        return $Error;
    $session->close;
    $logger->info( "Done with topology collection");
    return "ok";
}

my %sw_info = (    "sw_item" => undef,
    "sw_name"                => undef,
    "sw_ver"                 => undef );

my %hw_info = (    "hw_item" => undef,
    "hw_name"                => undef,
    "hw_ver"                 => undef,
    "hw_amount"              => undef );

my %ifc;


#
# parse 'show version' output
#
# Params:
#  router_id
#  vers file

sub juniper_parse_version {

    my ($rt_id, $host, $version_file) = @_[0 .. 2];

    open( F_VERSF, "<$version_file" ) or
        return "error - version file $version_file: $!\n";

    DB_startSwInfo( $rt_id );

    while (<F_VERSF>) {
        chomp;            # no newline
        s/^\s+//;            # no leading white
        s/\s+$//;            # no trailing white

        if (/^Hostname:\s*(\S+)$/) {
            DB_replaceRouterName( $rt_id, $1 );
        }

        if (/^Model:\s*(\S+)$/) {
            DB_writeHostModel( $rt_id, $1 );
        }

        if (/^(JUNOS.*) \[(.*)\]/) {
            $sw_info{'sw_item'} = 'Software';
            ( $sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( $1, $2 );
            DB_writeSwInfo( $rt_id, \%sw_info );
            next;
        }
    }

    close( F_VERSF );

    return "ok";

}

sub juniper_parse_hardwr {

    my ($rt_id, $hardwr_file) = @_[0 .. 1];

    open( F_HARDWR, "<$hardwr_file" ) or
        return "error - hardware file $hardwr_file: $!\n";

    DB_startHwInfo( $rt_id );

    while (<F_HARDWR>) {
        chomp;            # no newline
        s/^\s+//;            # no leading white
        s/\s+$//;            # no trailing white

        my $str_process = $_;
        my @inventory = split ( m'\s{2,}' );

        # This works well now - only hardware anomalies cause error messages on the console, which is fine by me

        if (!defined $inventory[0]) { next;}
        if ($inventory[0] eq 'Hardware inventory:') {next;}
        if ($inventory[0] eq 'Item') { next;}
        if ($inventory[0] eq 'show chassis hardware') {next;} #suppress warnings
        if ($inventory[0] eq '{master:0}') {next;}#suppress warnings
        #        diag \@inventory,$str_process;
        $inventory[1] = substr $str_process, 17, 8;
        $inventory[2] = substr $str_process, 24, 12;
        $inventory[3] = substr $str_process, 37, 16;
        $inventory[4] = substr $str_process, 55;
        $inventory[2] =~ s/^\s+|\s+$//g;
        $inventory[3] =~ s/^\s+|\s+$//g;
        $inventory[4] =~ s/^\s+|\s+$//g;

        %hw_info = (    "hw_item" => "$inventory[0]",
            "hw_name"             => "$inventory[4]",
            "hw_ver"              => "$inventory[3]",
            "hw_amount"           => "$inventory[2]" );

        DB_writeHwInfo( $rt_id, \%hw_info );
        next;

    }

    close( F_HARDWR );

    return "ok";
}

#
# parse 'show running config' output
#
# Params:
#  router_id
#  run config file

sub juniper_parse_config {

    my ($rt_id, $config_file) = @_[0 .. 1];

    open( F_RCF, "<$config_file" ) or
        return "error - config file $config_file: $!\n";

    while (<F_RCF>) {
        chomp;            # no newline
        s/^\s+//;            # no leading white
        s/\s+$//;            # no trailing white

        if (/^location \"([^\"]+)\";/) {
            DB_writeHostLocation( $rt_id, $1 );
            next;
        }
    }
    close( F_RCF );
    return "ok";
}

#
# Params:
#  router_id
#  interfaces file

sub juniper_parse_interfaces {
    my ($rt_id, $ifc_file) = @_[0 .. 1];
    print "Parsing $ifc_file\n";

    open( F_RCF, "<$ifc_file" ) or
        return "error - interfaces file $ifc_file: $!\n";

    my @old_ph_ifcs = @{DB_getPhInterfaces( $rt_id )};
    my @old_ifcs = @{DB_getInterfaces( $rt_id )};

    my %phifc;
    my $ph_int_id = '';

    my $phInterface = "";
    my $logInterface = "";
    my $protocol = "";

    while (<F_RCF>) {
        chomp;            # no newline
        s/\s+$//;            # no trailing white

        #print "$_\n";

        if (/^Physical interface:\s+([^,]+),\s+([^,]+),\sPhysical link is\s(\S+)$/) {
            print "Ph. interface $1, state $2, link $3\n" if $verbose;
            my ($newPhInt, $newState, $newCond) = ($1, $2, $3);
            $newState = 'enabled' if $newState =~ /Enabled/;
            $newState = 'disabled' if $newState =~ /Disabled/;
            $newState = 'adm down' if $newState =~ /Administratively down/;
            $newCond = 'up' if $newCond =~ /Up/;
            $newCond = 'down' if $newCond =~ /Down/;
            if (($phInterface ne "") && !($phInterface =~ /^\.local\./)) {
                DB_writePhInterface( $rt_id, \%phifc );
                @old_ph_ifcs = grep {!/^$phifc{"interface"}$/} @old_ph_ifcs;
            }
            if (($logInterface ne "") && ($ifc{"ip address"} ne '0.0.0.0' && $ifc{"ip address"} ne '127.0.0.1')) {
                DB_writeInterface( $rt_id, $ph_int_id, \%ifc );
                @old_ifcs = grep {!/^$ifc{"interface"}$/} @old_ifcs;
            }
            $phInterface = $newPhInt;
            $logInterface = "";
            @ifc{("interface", "ip address", "mask", "description")} =
                ('', '0.0.0.0', '255.255.255.255', '');
            @phifc{("interface", "state", "condition", "speed", "description")} =
                ($phInterface, $newState, $newCond, '', '');
            $protocol = "";
            next;
        }

        # skip local phys interfaces
        if ($phInterface =~ /^\.local\./) {
            next;
        }

        if (/^  Description:\s+(.*)$/) {
            $phifc{"description"} = $1;
        }

        if (/^  (\S+\s+)*Speed:\s+([^,]*)[,]*.*$/) {
            my $speed = $2;
            $phifc{"speed"} = $speed;
            if ($speed =~ /^(\d+)m$/) {
                $phifc{"speed"} = $1."000000";
            }
            if ($speed =~ /^(\d+)mbps$/) {
                $phifc{"speed"} = $1."000000";
            }
            if ($speed =~ /^OC3$/) {
                $phifc{"speed"} = "155000000";
            }
            if ($speed =~ /^OC12$/) {
                $phifc{"speed"} = "622000000";
            }
            if ($speed =~ /^OC48$/) {
                $phifc{"speed"} = "2488000000";
            }
            if ($speed =~ /^OC192$/) {
                $phifc{"speed"} = "9952000000";
            }
            print "Speed: $phifc{'speed'}\n" if $verbose;
        }

        # Logical interface so-6/0/0.0 (Index 25) (SNMP ifIndex 20) (Generation 27)
        if (/^  Logical interface\s+(\S+)\s+\(Index\s+(\d+)\)\s+\(SNMP ifIndex\s+(\d+)\)/) {
            print "Log. interface $1, index $2, snmp idx $3\n" if $verbose;
            if ($logInterface eq "") {
                DB_writePhInterface( $rt_id, \%phifc );
                @old_ph_ifcs = grep {!/^$phifc{"interface"}$/} @old_ph_ifcs;
                $ph_int_id = DB_getPhInterfaceId( $rt_id, $phInterface );
            }

            $logInterface = $1;
            @ifc{("interface", "ip address", "mask", "description")} =
                ($1, '0.0.0.0', '255.255.255.255', '');
            $protocol = "";
            next;
        }

        # rest is for log interfaces only
        if ($logInterface eq "") {
            next;
        }

        if (/\sDescription:\s+(.*)$/) {
            $ifc{"description"} = $1;
        }

        # Protocol inet, MTU: Unlimited, Generation: 7, Route table: 0
        if (/^    Protocol\s+inet,/) {
            print "Protocol: inet\n" if $verbose;
            $protocol = "inet";
            next;
        }

        if (/^    Protocol\s+([^,]+),/) {
            print "Protocol: other\n" if $verbose;
            $protocol = $1;
            next;
        }

        if ($protocol eq "inet") {
            #        Destination: 172.26.27/24, Local: 172.26.27.20,
            if (/^        Destination:\s+(\d+\.\d+\.\d+\.\d+|\d+\.\d+\.\d+|\d+\.\d+|\d+)\/(\d+),\s+Local:\s+(\d+\.\d+\.\d+\.\d+)\D*/) {
                print "Dest: $1, bits: $2, local: $3\n" if $verbose;
                $ifc{ 'ip address' } = $3;
                $ifc{ 'mask' } = bits2mask( $2 );
                if (($logInterface ne "") && ($ifc{"ip address"} ne '0.0.0.0')) {
                    DB_writeInterface( $rt_id, $ph_int_id, \%ifc );
                    @old_ifcs = grep {!/^$ifc{"interface"}$/} @old_ifcs;
                }
                print "mask: $ifc{ 'mask' }\n " if $verbose;
                next;
            }

            # handle this for local interfaces only
            if (/^        Destination:\s+(\w+),\s+Local:\s+(\d+\.\d+\.\d+\.\d+)\D*/) {
                $ifc{ 'ip address' } = $2;
                if ($phInterface =~ /^lo\d+/) {
                    print "Local interface, ip $ifc{ 'ip address' }\n" if $verbose;
                    $ifc{ 'mask' } = '255.255.255.255';
                    if (($logInterface ne "") && ($ifc{"ip address"} ne '0.0.0.0')) {
                        DB_writeInterface( $rt_id, $ph_int_id, \%ifc );
                        @old_ifcs = grep {!/^$ifc{"interface"}$/} @old_ifcs;
                    }
                }
                #print "Dest: $1, local: $2\n";
                next;
            }
        }
    }

    if (($phInterface ne "") && !($phInterface =~ /^\.local\./)) {
        DB_writePhInterface( $rt_id, \%phifc );
        @old_ph_ifcs = grep {!/^$phifc{"interface"}$/} @old_ph_ifcs;
    }
    if (($logInterface ne "") && ($ifc{"ip address"} ne '0.0.0.0' && $ifc{"ip address"} ne '127.0.0.1')) {
        DB_writeInterface( $rt_id, $ph_int_id, \%ifc );
        @old_ifcs = grep {!/^$ifc{"interface"}$/} @old_ifcs;
    }

    DB_dropPhInterfaces( $rt_id, \@old_ph_ifcs );
    DB_dropInterfaces( $rt_id, \@old_ifcs );

    close( F_RCF );
    return "ok";
}

# END { print "deleting NGNMS_Juniper\n" };

1;
# ABSTRACT: This file is part of open source NG-NetMS tool.

__END__
