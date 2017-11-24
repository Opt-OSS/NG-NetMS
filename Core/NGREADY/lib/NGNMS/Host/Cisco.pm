#
# NextGen NMS
#
# NGNMS_Cisco.pm: interfacing with Cisco routers
#
# Copyright (C) 2002,2003 OptOSS LLC
#
# Author: M.Golov
#
use strict;
use warnings FATAL => 'all';

package NGNMS::Host::Cisco;

# use Data::Dumper;
use NGNMS::OLD::DB;
use NGNMS::OLD::Util;
use NGNMS::Log4;
use NGNMS::Net::Connect;
use Try::Tiny;
use Moo::Role;
use Emsgd qw(diag);





# your exported package globals go here,
# as well as any optionally exported functions

my $getTopReturn;



# Preloaded methods

my $community = 'public';



###################################################
# getting stuff from routers

my $session;
my $Error;


my $Log = NGNMS::Log4->new();
my $logger = $Log->get_new_category_logger(__PACKAGE__);

sub cisco_connect {
    my $connect_params = shift;
    $connect_params->{personality}='ios';
    $connect_params->{connect_options}->{opts} =  $connect_params->{connect_options};
    if (exists $connect_params->{jumphost}) {
        push @{ $connect_params->{jumphost}{connect_options} },('-p',$connect_params->{jumphost}{port}) if $connect_params->{jumphost}{port};
        $connect_params->{jumphost} = Net::Appliance::Session->new(
            transport       => 'SSH',
            personality     => 'bash',
            timeout         => $connect_params->{jumphost}{timeout} || 10,
            host            => $connect_params->{jumphost}{host},
            username        => $connect_params->{jumphost}{username},
            password        => $connect_params->{jumphost}{password},
            connect_options => { opts => $connect_params->{jumphost}{connect_options} },

        );
    }
    $Log->put_debug_key('host',$connect_params->{host});
    $session = NGNMS::Net::Connect->new( $connect_params );
    return try{
            $session->connect();

            $session->begin_privileged();

            my @output = $session->macro( 'check_privileged' );
            $output[0] =~ s/\n//g;
            return 'ok' if $output[0] eq "Current privilege level is 15";
            $Error = "$connect_params->{host} ios: enable level 15 failed!";
            #        $session->close();
            return $Error;
        }catch{
                $Error = $_;
                #last resonce could throw exception if port was not opened :connection refused etc
                try {$Error = $session->last_response();}catch{};
                        $Error =  $connect_params->{host}.": ".$Error;
                $logger->error( $Error);
                return $Error;
            };
}


sub cisco_get_file($$) {
    my ($cmd, $fname) = @_[0 .. 1];
    $Error = undef;
    #    Emsgd::diag($session);
    $session->connect();
    $session->begin_privileged();
    my @data = $session->get( $cmd );
    if (!@data) {
        $Error = "cisco: no data for cmd '$cmd'";
        return undef;
    }
    if (!open( F_DATA, ">$fname" )) {
        $Error = "Cannot open file $fname for writing: $!";
        return undef;
    }
    print F_DATA @data;
    close ( F_DATA );
    1;
}
sub cisco_get_bgp_file($) {
    my $fname = shift;
    $Error = undef;
    #    Emsgd::diag($session);
    $session->connect();
    $session->begin_privileged();
    my $data;
    $data = $session->macro( 'bgp_database_summary' );
    $data .= $session->macro( 'bgp_database_neighbors' );
    if (!$data) {
        $Error = "cisco: no data for bgp macros";
        return undef;
    }
    if (!open( F_DATA, ">$fname" )) {
        $Error = "Cannot open file $fname for writing: $!";
        return undef;
    }
    print F_DATA $data;
    close ( F_DATA );
    1;
}

# get ISIS and OSPF topologies from router
# Params:
#  host name or ip
#  username (may be "")
#  password
#  enable password
#
# Output:
#  creates 2 files:
#  <host>_isis.txt
#  <host>_ospf.txt
#
# Return:
#  "ok" or error text
#

sub get_topologies ($$$$) {
    return $getTopReturn if defined( $getTopReturn );

    my ($host, $connect_params) = (shift,shift);
    my $filename1 = $host."_isis.txt";
    my $filename2 = $host."_ospf.txt";
    my $filename3 = $host."_bgp.txt";
    my $er = cisco_connect( $connect_params );

    #    $session->connect();
    #    my @output;
    #    try {
    #        $session->get(' ');
    ##        @output = $session->get('show privil');
    #        @output = $session->macro('check_privileged');
    #        $output[0] =~ s/\n//g;
    #        Emsgd::diag('ok') if $output[0] eq "Current privilege level is 15";
    ##        @eee = $session->macro('bgp_database');
    #    }catch{
    #        Emsgd::diag('Error catched');
    #    };
    #    Emsgd::diag(@output );
    #    exit();

    return $er if ( $er !~ m/ok/ );

    if (defined( $ENV{"NGNMS_DATA"} )) {
        $filename1 = $ENV{"NGNMS_DATA"}."/topologies/".$filename1;
        $filename2 = $ENV{"NGNMS_DATA"}."/topologies/".$filename2;
        $filename3 = $ENV{"NGNMS_DATA"}."/topologies/".$filename3;
    }

    $logger->info( "Getting ISIS topology...");
    if (!cisco_get_file( 'show isis database detail', $filename1 )) {
        if ($Error =~ /% Invalid input detected/) {
            $logger->info( "NGNMS: $host: ISIS protocol not supported");
        }
        #        else {
        #            $session->close();
        #            return $Error;
        #        }
    }

    $logger->info(  "Getting OSPF topology...");
    if (!cisco_get_file( 'show ip ospf database router', $filename2 )) {
        $session->close();
        return $Error;
    }

    $logger->info(  "Getting BGP topology...");
    if (!cisco_get_bgp_file( $filename3 )) {
        $session->close();
        return $Error;
    }

    $session->close;
    $logger->info(  "Done");

    return "ok";
}
#moved to poll-host plugin
#@deprecated
sub cisco_get_configs {
    my ($host, $username, $password, $enablepw) = @_[0 .. 3];
    my $configPath = $_[4];
    my $access = $_[6];
    $community = $_[5]; #this should be global, WTF
    $logger->info ("Getting configs from $host");

    my $er = cisco_connect( $host, $username, $password, $enablepw, $access );
    return $er if ( $er !~ m/ok/ );

    # get version
    #
    if (!cisco_get_file( 'show version', $configPath."_version.txt" )) {
        $session->close();
        return $Error;
    }

    # Running config
    #
    $Error = undef;
    my @data = $session->get( 'show running-config' );
    if (!@data) {
        $session->close;
        return "cisco: no data for running config";
    }
    # strip out all lines from the beginning until ! is found
    my $i = 0;
    while ($data[$i] !~ m/!/) {
        $data[$i] = '';
        $i++;
    }

    my $fname = $configPath."_running_config.txt";
    if (!open( F_DATA, ">$fname" )) {
        $session->close;
        return "Cannot open file $fname for writing: $!";
    }
    print F_DATA @data;
    close ( F_DATA );

    # Interfaces
    #
    if (!cisco_get_file( 'show interfaces', $configPath."_interfaces.txt" )) {
        $session->close();
        return $Error;
    }

    $session->close;

    return "ok";
}

###################################################
# parsing

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

#@deprecated
sub cisco_parse_version {
    my ($rt_id, $host, $version_file) = @_[0 .. 2];
    $logger->debug( "Parsing $version_file");

    open( F_VERSF, "<$version_file" ) or
        return "error - version file $version_file: $!\n";

    skip_till( *F_VERSF, ".*Cisco Internetwork Operating System Software\.*" );

    DB_startSwInfo( $rt_id );
    DB_startHwInfo( $rt_id );

    while (<F_VERSF>) {
        chomp;            # no newline
        s/^\s+//;            # no leading white
        s/\s+$//;            # no trailing white

        if (/^(IOS .* Software [^,]*), Version ([^,]*).*/) {
            $sw_info{'sw_item'} = 'Software';
            ( $sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( $1, $2 );
            DB_writeSwInfo( $rt_id, \%sw_info );
            next;
        }

        if (/^(ROM: [^,]*), Version ([^,\s]*).*/) {
            $sw_info{'sw_item'} = 'Firmware';
            ( $sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( $1, $2 );
            DB_writeSwInfo( $rt_id, \%sw_info );
            next;
        }

        if (/^(BOOTLDR: [^,]*), Version ([^,\s]*).*/) {
            $sw_info{'sw_item'} = 'Firmware';
            ( $sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( $1, $2 );
            DB_writeSwInfo( $rt_id, \%sw_info );
            next;
        }

        if (/^(cisco .*)processor(.*)with (.*)of memory.*/) {

            %hw_info = (    "hw_item" => 'Processor',
                "hw_name"             => $1,
                "hw_ver"              => $2,
                "hw_amount"           => '' );
            DB_writeHwInfo( $rt_id, \%hw_info );

            %hw_info = (    "hw_item" => 'Memory',
                "hw_name"             => 'RAM',
                "hw_ver"              => '',
                "hw_amount"           => $3 );
            DB_writeHwInfo( $rt_id, \%hw_info );
            next;
        }

        # 507K bytes of non-volatile configuration memory.
        if (/^(\w* bytes) of non-volatile configuration memory.*/) {
            %hw_info = (    "hw_item" => 'Memory',
                "hw_name"             => 'NVRAM',
                "hw_ver"              => '',
                "hw_amount"           => $1 );
            DB_writeHwInfo( $rt_id, \%hw_info );
            next;
        }

        if (/^(\w* bytes).*Flash.PCMCIA.*at.(slot \d?).*/) {
            %hw_info = (    "hw_item" => 'Memory',
                "hw_name"             => 'Flash PCMCIA',
                "hw_ver"              => $2,
                "hw_amount"           => $1 );
            DB_writeHwInfo( $rt_id, \%hw_info );
            next;
        }

        if (/^(\w* bytes).*ATA.PCMCIA.*at.(slot \d?).*/) {
            %hw_info = (    "hw_item" => 'Memory',
                "hw_name"             => 'ATA PCMCIA',
                "hw_ver"              => $2,
                "hw_amount"           => $1 );
            DB_writeHwInfo( $rt_id, \%hw_info );
            next;
        }

        if (/^(\w* bytes).*Flash.internal.*(SIMM).*/) {
            %hw_info = (    "hw_item" => 'Memory',
                "hw_name"             => 'internal Flash',
                "hw_ver"              => $2,
                "hw_amount"           => $1 );
            DB_writeHwInfo( $rt_id, \%hw_info );
            next;
        }
    }

    close( F_VERSF );

    # get equipment type - to be used with ucd-snmp version: 4.2.5
    ##  old command : my $ht = `snmpget -m ALL -c $community $host sysObjectID.0`;

    my $ht = `snmpget -v 2c -m ALL -c $community $host sysObjectID.0`;
    ## parse old command $ht =~/OID:.*\.(.*$)/;
    if (defined $ht && $ht ne '')
    {
        my @t_arr = split( /:/, $ht );
        my $ind = $#t_arr;
        my $last_el = $t_arr[$ind];

        DB_writeHostModel( $rt_id, $last_el );
    }
    else
    {
        my $rout_id = DB_getRouterIpAddr( $rt_id );
        my $ht0 = `snmpget -v 2c -m ALL -c $community $rout_id sysObjectID.0`;
        if (defined $ht0 && $ht0 ne '')
        {
            my @t_arr0 = split( /:/, $ht0 );
            my $ind0 = $#t_arr0;
            my $last_el0 = $t_arr0[$ind0];
            DB_writeHostModel( $rt_id, $last_el0 );
        }
        else
        {
            my $ht1 = `snmpget -v 1 -m ALL -c $community $rout_id sysObjectID.0`;
            $ht1 =~ /OID:.*\.(.*$)/;
            if (defined $ht1 && $ht1 ne '') {
                DB_writeHostModel( $rt_id, $ht1 );
            }
        }

    }
    return "ok";
}

#
# parse 'show running config' output
#
# Params:
#  router_id
#  run config file

sub cisco_parse_run_config {
    my ($rt_id, $run_config_file) = @_[0 .. 1];
    $logger->debug( "Parsing $run_config_file");
    open( F_RCF, "<$run_config_file" );
    while (<F_RCF>) {
        chomp;            # no newline
        s/^\s+//;            # no leading white
        s/\s+$//;            # no trailing white
        if (/^hostname\s*(\S+)$/) {
            DB_replaceRouterName( $rt_id, $1 );
            last;
        }
    }
    close( F_RCF );

    return "ok";

}


#
# parse 'show interfaces' output
#
# Params:
#  router_id
#  interfaces file

sub cisco_parse_interfaces {
    my ($rt_id, $ifc_file) = @_[0 .. 1];
    $logger->debug( "Parsing $ifc_file");

    open( F_RCF, "<$ifc_file" ) or
        return "error - interfaces file $ifc_file: $!\n";

    my @old_ifcs = @{DB_getInterfaces( $rt_id )};
    my @old_ph_ifcs = @{DB_getPhInterfaces( $rt_id )};

    my %phifc;

    my $phInterface = "";
    my $logInterface = "";
    $ifc{ 'ip address' } = '';

    while (<F_RCF>) {
        chomp;            # no newline
        s/\s+$//;            # no trailing white

        #print "$_\n";

        if (/^(\S+)\s+is\s+([^,]+),\s+line protocol is\s+(.*)$/) {
            my ($newInt, $newState, $newCond) = ($1, $2, $3);
            $newState = 'enabled' if $newState =~ /up/;
            $newState = 'disabled' if $newState =~ /down/;
            $newCond = 'up' if $newCond =~ /up/;
            $newCond = 'down' if $newCond =~ /down/;
            $logger->debug( "Interface $newInt, state $newState, line $newCond");

            if ($phInterface ne "") {
                DB_writePhInterface( $rt_id, \%phifc );
                @old_ph_ifcs = grep {!/^$phifc{"interface"}$/} @old_ph_ifcs;
            } else {
                $phInterface = $logInterface;
                for ($phInterface) {  s/\.\d+$//; }
            }
            if ($ifc{ 'ip address' } ne '' && $ifc{"ip address"} ne '127.0.0.1') {
                my $ph_int_id = DB_getPhInterfaceId( $rt_id, $phInterface );
                DB_writeInterface( $rt_id, $ph_int_id, \%ifc );
                @old_ifcs = grep {!/^$ifc{"interface"}$/} @old_ifcs;
            }

            $logInterface = $newInt;
            $phInterface = '';
            unless ($logInterface =~ /\.\d+$/) {
                $phInterface = $logInterface;
            }

            @ifc{("interface", "ip address", "mask", "description")} =
                ($logInterface, '', '255,255,255', '');
            @phifc{("interface", "state", "condition", "speed", "description")} =
                ($phInterface, $newState, $newCond, '', '');
            next;
        }

        #   MTU 1500 bytes, BW 1000000 Kbit, DLY 10 usec,

        if (/^  .*\s+BW\s+([^,]*)[,]*.*$/) {
            my $speed = $1;
            if ($speed =~ /^(\d+)\s+Kbit$/) {
                $phifc{"speed"} = $1."000";
            };
            $logger->debug ("Speed: $phifc{'speed'}");
            next;
        }

        #  Description: vpn_int_cisco_1
        if (/^  Description:\s+(.*)$/) {
            $phifc{"description"} = $1;
            $ifc{"description"} = $1;
            next;
        }
        #  Internet address is 13.0.0.2/24
        if (/^  Internet address is\s+(\d+\.\d+\.\d+\.\d+)\/(\d+)$/) {
            $ifc{ 'ip address' } = $1;
            $ifc{ 'mask' } = bits2mask( $2 );
            $logger->debug( "IP: $ifc{ 'ip address' }, mask: $ifc{ 'mask' }");
            next;
        }
    }

    if ($phInterface ne "") {
        DB_writePhInterface( $rt_id, \%phifc );
        @old_ph_ifcs = grep {!/^$phifc{"interface"}$/} @old_ph_ifcs;
    } else {
        $phInterface = $logInterface;
        for ($phInterface) {  s/\.\d+$//; }
    }
    if ($ifc{ 'ip address' } ne '' && $ifc{"ip address"} ne '127.0.0.1') {
        my $ph_int_id = DB_getPhInterfaceId( $rt_id, $phInterface );
        DB_writeInterface( $rt_id, $ph_int_id, \%ifc );
        @old_ifcs = grep {!/^$ifc{"interface"}$/} @old_ifcs;
    }

    DB_dropPhInterfaces( $rt_id, \@old_ph_ifcs );
    DB_dropInterfaces( $rt_id, \@old_ifcs );

    close( F_RCF );
    return "ok";
}


# END { print "deleting NGNMS_Cisco\n" };

1;
# ABSTRACT: This file is part of open source NG-NetMS tool.

__END__
