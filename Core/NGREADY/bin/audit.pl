#!/usr/bin/perl -w

# NextGen NMS Discovery/audit 
#
# Audit main module
#
# Usage: audit.pl [switches] host user passwd enpasswd [Telnet/SSHv1/SSHv2]
#
# Switches:
#  -np       skip poll stage
#  -s		 run subnets scanner
#  -f fname  get topologies from files 'file_isis.txt' and 'file_ospf.txt'
#  -t type   seed host type [Juniper/Cisco/Linux]
#  -d        verbose info to screen
#  -L        DB host
#  -D		 DB name
#  -U		 DB User
#  -W        Pasword for DB user
#  -P        DB port
#  -K        absolute path to public Key
#  -H        passphrase for public key
#  -i        interactive status updates
#
# Example: audit.pl c1600 "" cisco cisco Telnet
#
# Environment:
#
#  NGNMS_DEBUG   - if set to 1, equivalent to -d switch set. Use for deep debug.
#  NGNMS_LOGFILE - if set, log is written to this file
#
# Copyright (C) 2002,2003 OptOSS LLC
# Copyright (C) 2014,2015 Opt/Net BV
#
# Author: M.Golov, T.Matselyukh, A. Jaropud
#


#TODO remove depencity on DateTime -it wantsa too many deps for it
use lib "$ENV{'NGNMS_HOME'}/lib/";

use strict;
use threads;
use warnings;

#=for ddd
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# DB Version !!!!!!!!! IMPORTANT FOR ABILITY TO PROCESS OLD ARCHIVES
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#=cut
use constant DB_VERSION => 35001;# x.xx.xx

use NGNMS::OLD::DB;
use NGNMS::DB;
use NGNMS::App::Crypt;
use NGNMS::OLD::Util;
use NGNMS::Log4;

use NGNMS::Host::Cisco;
use NGNMS::Host::Juniper;
use NGNMS::Host::SeedHost;
use NGNMS::Topology::BGP;

use NGNMS::Host::Linux;
use Net::Netmask;
use List::Util qw(min max);
use NGNMS::OLD::Util;
use Data::Dumper;

use Emsgd qw(diag);
my $Log = NGNMS::Log4->new();
my $logger = $Log->get_new_category_logger('audit');

############################   START ################################
$logger->info("Audit Program initialization ----->");
#####################################################################
# General configuration section
#####################################################################
# Variables
#
# Number of simultaneous poll processes
#
my $slots = 12;
# Skip the poll stage by default
#
my $noPoll = 0;

my $dbhost = $ENV{NGNMS_DB_HOST} || "localhost";
my $dbname = $ENV{NGNMS_DB} || "ngnms";
my $dbuser = $ENV{NGNMS_DB_USER} || "ngnms";
my $dbpasswd = $ENV{NGNMS_DB_PASSWORD} || "ngnms";
my $dbport = $ENV{NGNMS_DB_PORT} || "5432";

my $filesDir = "";
#my $isis_file;
#my $ospf_file;
#my $bgp_file;
my $criptokey;
my $test_topologies;
my $single_host_only=0;
my $test_host_type;
my $prom_val;
my $scan = 0;
my $interact = 0;
my $force_rediscovery = 0;
my $bgps;
my $bgp_status = 1;
my $flag_bgp;
my $seedHosts = '';
my $user = '';
my $passwd = '';
my $enpasswd = '';
my $access = '';
my $community = '';
my $logFile = "/dev/stdout";
my $path_to_key = "";
my $passphrase = "";
my @bgp_parser_queue = ();

# Print debugging output to screen if in debug
my $verbose = $ENV{"NGNMS_DEBUG"} || 0;



#####################################################################
# Parse command line
#
$logger->info("Parsing command line");
if ($#ARGV < 0) {
    &usage;
    $logger->error("Started without arguments. Exiting audit programme.");
    exit;
}
while (($#ARGV >= 0) && ($ARGV[0] =~ /^-.*/)) {

#        $logger->debug( " in arg while $ARGV[0]");

    if ($ARGV[0] eq "-d") {

        # Redirect stdout if deep debugging is required
        $logger->warn("Started in debug mode cause -d flag provided");
        $slots = 1;
        shift @ARGV;
        next;
    }

    if ($ARGV[0] eq "-np") {
        $noPoll = 1;
        shift @ARGV;
        next;
    }
    if ($ARGV[0] eq "--force-rediscovery") {
        $force_rediscovery = 1;
        shift @ARGV;
        next;
    }
    if ($ARGV[0] eq "-i") {
        $interact = 1;
        shift @ARGV;
        next;
    }
    if ($ARGV[0] eq "-s") {
        $scan = 1;
        shift @ARGV;
        next;
    }
    if ($ARGV[0] eq "-f") {
        shift @ARGV;
        $test_topologies = $ARGV[0] || $ENV{"NGNMS_DATA"} . '/topologies';
        $seedHosts = $test_topologies;
        $logger->info("##### FILE MODE - get configs from directory : $test_topologies\n");
        shift @ARGV;
        next;
    }
    if ($ARGV[0] eq "-t") {
        shift @ARGV;
        $test_host_type = $ARGV[0] if defined($ARGV[0]);
        $logger->info("test_host_type: $test_host_type");
        shift @ARGV;
        next;
    }
    if ($ARGV[0] eq "--single-host") {
        $single_host_only = 1;
        shift @ARGV;
        next;
    }

    if ($ARGV[0] eq "-D") {
        shift @ARGV;
        $dbname = $ARGV[0] if defined($ARGV[0]);
        shift @ARGV;
        next;
    }

    if ($ARGV[0] eq "-U") {
        shift @ARGV;
        $dbuser = $ARGV[0] if defined($ARGV[0]);
        shift @ARGV;
        next;
    }

    if ($ARGV[0] eq "-W") {
        shift @ARGV;
        $dbpasswd = $ARGV[0] if defined($ARGV[0]);
        shift @ARGV;
        next;
    }

    if ($ARGV[0] eq "-P") {
        shift @ARGV;
        $dbport = $ARGV[0] if defined($ARGV[0]);
        shift @ARGV;
        next;
    }

    if ($ARGV[0] eq "-L") {
        shift @ARGV;
        $dbhost = $ARGV[0] if defined($ARGV[0]);
        shift @ARGV;
        next;
    }

    if ($ARGV[0] eq "-K") {
        shift @ARGV;
        $path_to_key = $ARGV[0] if defined($ARGV[0]);
        shift @ARGV;
        next;
    }

    if ($ARGV[0] eq "-H") {
        shift @ARGV;
        $passphrase = $ARGV[0] if defined($ARGV[0]);
        shift @ARGV;
        next;
    }

    if ($ARGV[0] eq "-h") {
        &usage;
        $logger->error("Displaying help, exiting audit programme.");
        exit;
    }

    shift @ARGV;
}
$logger->debug("Finished argument processing");
#####################################################################

# forward sub declaration
sub spawnChild;
sub waitForSlot;
sub spawnForAll;
sub getTopologies;
sub discoveryBgp;
sub getBgpCommunity;
sub usage;
sub getAttrVal;

$logger->debug("Opening DB");

DB_open($dbname, $dbuser, $dbpasswd, $dbport, $dbhost);

if (!DB_ping) {
    $logger->logdie("Could not connect to DB");
}
my $ls_discovery = DB_lastchangeDiscovery();
if (defined $ls_discovery) {
    if ($force_rediscovery) {
        ## forse rediscovery
        $logger->info ("
        ==============================================================
        ======          WARNING: Discovery force start      ==========
        ==============================================================
        ");
        $logger->warn("started in force mode");
        DB_stopDiscovery (0, 1, 0); # %=0, finish=1, mode=0 (override overdue session closure)
    }
    else {
        ## potential issue here if one discovery not updated longer than 10min
        if ($ls_discovery > 600) {
            $logger->warn("Canceling previouse discovery (runing $ls_discovery seconds)");
            DB_stopDiscovery (0, 1, 0); # %=0, finish=1, mode=0 (override overdue session closure)

        }
        $logger->error("Warning! Audit process cannot be run at this time! There is another running ($ls_discovery seconds) audit process...");
        exit;
    }
}
## Start
$logger->debug("Initiating start of discovery: User:[$user]. Interactive mode:[$interact]");
DB_insertDiscoveryStatus ($user, $interact);

$logger->debug("Setting crypto access to DB");
my $p = 48;
$criptokey = DB_getCriptoKey();
my $length = length $criptokey;
$p -= $length;
my $suffix = ('0' x $p);
$criptokey .= $suffix;

$logger->debug("Getting access credentials and seed host settings from DB");
#Important section where command line arguments should override DB settings if defined
$prom_val = DB_getSettings('seedHost');
$seedHosts = getAttrVal($prom_val->[0]);
$prom_val = DB_getSettings('hostType');
my $default_host_type = getAttrVal($prom_val->[0]);


#$prom_val = DB_getSettings( 'username' );
#$user = getAttrVal( $prom_val->[0] );
#$prom_val = DB_getSettings( 'password' );
#$passwd = getAttrVal( $prom_val->[0] );
#$prom_val = DB_getSettings( 'enpassword' );
#$enpasswd = getAttrVal( $prom_val->[0] );
#$prom_val = DB_getSettings( 'type access' );
#my $access1 = getAttrVal( $prom_val->[0] );
#$access = $access1 if defined( $access1 );
#$prom_val = DB_getSettings( 'community' );
my $community1 = getAttrVal($prom_val->[0]);
$community = $community1 if defined($community1);
DB_close;

$logger->debug("Seed host settings initialized");

if ($#ARGV >= 0){
    $seedHosts = shift @ARGV
}else{
    if ($single_host_only ){
        print "\n--single host requires seed host given in command line\n";
        usage();
    }
};
$user = shift @ARGV if $#ARGV >= 0;
$passwd = shift @ARGV if $#ARGV >= 0;
$enpasswd = shift @ARGV if $#ARGV >= 0;
$access = shift @ARGV if $#ARGV >= 0;
$community = shift @ARGV if $#ARGV >= 0;



# Determine access type for seed host
if ($access eq 'SSH') {
    $access = 'SSHv2'
}
#$access = 'Telnet' unless $access =~ m/SSHv[12]/i;

my @seedHostList = split /,/, $seedHosts;



$logger->info ("Starting with seed host(s): $seedHosts");

#my $cmd1 = " -D ".$dbname." -U ".$dbuser." -W ".$dbpasswd." -P ".$dbport." -L ".$dbhost;

DB_open($dbname, $dbuser, $dbpasswd, $dbport, $dbhost);


#DB_vacuum;



####
DB_updateAllBgpRouterStatus();
DB_clearRouterPeers();
# Loop through the seed hosts
$logger->debug("Looping through all seed hosts...");
#cleanup and add to queue
foreach my $seedHost (@seedHostList) {
    $seedHost =~ s/^\s+//;    # no leading white
    $seedHost =~ s/\s+$//;    # no trailing white
    push @bgp_parser_queue, $seedHost;
    if ($single_host_only){
        #only first host
        last;
    }
}

@bgp_parser_queue = List::Util::uniqstr(@bgp_parser_queue);

my $conf_dir = './';
$logger->error("NGNMS_DATA is not set") && die unless $ENV{"NGNMS_DATA"};
if (!$test_topologies) {
    $conf_dir = $ENV{"NGNMS_DATA"} . '/topologies' || './';
    `/bin/rm -f $conf_dir/*.txt`;
    $logger->debug("Saving topology files in $conf_dir directory");
}
else {
    $conf_dir = $test_topologies;
    $logger->debug("Looking for offline topology files in $conf_dir location");
}
my (%bgp_host_ips, %bgp_links, %bgp_autonomous_systems);
my $dbg_lastSeedHost = '';
my $dbg_host_type;
$logger->info ("=== Discovery Iteraton  Started ====");
my $NEWDB = NGNMS::DB->new(dbh => NGNMS::OLD::DB::getDbh);
#diag($user);
my $NEW_CRYPT = NGNMS::App::Crypt->new(
    DB                  => $NEWDB,
    username            => $user,
    password            => $passwd,
    privileged_password => $enpasswd,
    transport           => $access,
);
discoveryBgp(\@bgp_parser_queue, 1);
DB_updateDiscoveryStatus(5, 0);## Host type was determined by one of the methods (CLI/SNMP)

#loop over all remained BGP hosts
if (!$single_host_only){
    my $max_iterations = 3;
    while (!$max_iterations--) {
        my $my_hosts = DB_getBgpRouters();
        last unless defined $my_hosts;
        $logger->info("=== Discovery Iteraton {$max_iterations} ====");
        #    Emsgd::diag  $my_hosts, 'Discovered hosts step-in '.$max_iterations;
        discoveryBgp($my_hosts, 0);
    }

}else{
    DB_updateDiscoveryStatus(100, 1);
    $logger->info("==== end audit :  --seedhost-only option given");
    exit;
}


my $routers_ospf = DB_getRoutersWithProtocol();
if (scalar($routers_ospf)) {
    $logger->info("================== Non-BGP routers discovering.... ================");
    discoveryBgp($routers_ospf, 0);
}

DB_updateDiscoveryStatus(15, 0);


$logger->info("Preparing polling stage...");

if ($noPoll) {
    $logger->warn("No poll flag is set. Skipping polling stage.");
    if ($interact < 1) {

        DB_stopDiscovery(15, 1, 1); # in non interactive mode setting %=15, finish=1, mode=1 (normal)

    }
    else {
        DB_stopDiscovery(15, 0, 1); # in interactive mode setting %=15, finish=0, mode=1 (normal) -- WHY finish=0?
    }
    DB_close;
    exit;
}

#########################################
# now we have all nodes in the network
# start polling them all
#
my %hosts = DB_getRouters(".*");

$logger->info("Initiating polling of all nodes from topology");
foreach my $child (keys %hosts) {
    $logger->debug("Preparing poll " . $child . "  host_ID=" . $hosts{$child});
}

if (!%hosts) {
    $logger->error("audit", "No network hosts found to poll. Exiting...");
    if ($interact < 1) {
        DB_stopDiscovery(15, 1, 1);
    }
    else {
        DB_stopDiscovery(15, 0, 1);
    }
    DB_close;
    exit;
}

my $fdset = '';
my %pipes;
my %fdmap;
my $freeslots;
my $remaining;
my $start_bar = 15;
my $pr_bar = 35;
my $int_bar;
my $step_bar;
my $rest;
my @params = ();

my $Nchildren = keys %hosts;

$logger->info("Starting polling: $slots slots: $Nchildren children");

$int_bar = $Nchildren;

spawnForAll ("$ENV{'NGNMS_HOME'}/bin/AppRun.pl", keys %hosts);

DB_open($dbname, $dbuser, $dbpasswd, $dbport, $dbhost);     # open DB connect
my $cur_percent = DB_percentDiscovery();
if ($cur_percent < 51) {
    DB_updateDiscoveryStatus(50, 0);                     ## Polling process was ended
}
$logger->info("Polling done");

sleep(1);                                               # wait a second before a scan...

if ($scan > 0) {
    $logger->info("Commencing subnet scan");
    &runScanner("$ENV{'NGNMS_HOME'}/bin/subnets_scanner.pl");
}
else {
    $logger->info("No scanning flag is set. Skipping scanning stage.");

    #    todo bind to somewhere
    if ($dbg_host_type eq 'Linux') {
        $logger->info("but seed host type was Linux");
        my $seed_router_id = DB_getRouterId($dbg_lastSeedHost);
        #        NGNMS_DB::DB_getInterfacesAll  returns
        #           [
        #               [
        #                   'TRAFFIC_EXT_CORE', = Interface name
        #                    '77.243.174.102', = IP
        #                    '255.255.255.252' = mask
        #                    '1001' = intercace id
        #               ]
        #            ],
        my @seedIntefaces = @{DB_getInterfacesAll($seed_router_id)};

        my @arrIp = ();
        foreach my $seedInterface(@seedIntefaces) {
            push @arrIp, $seedInterface->[1];
        }

        my $hostswls = DB_getRoutersWithoutLinks();
        foreach my $hostswl (@{$hostswls}) {
            my @wlinterfaces = @{DB_getInterfacesAll($hostswl->[0])};
            foreach my $wlinterface(@wlinterfaces) {
                my $control_block = Net::Netmask->new($wlinterface->[1], $wlinterface->[2]);
                if ($control_block->match($arrIp[0])) {
                    DB_writeLink($seed_router_id, $hostswl->[0], 'B')
                }
            }
        }
    }

}

$logger->info("Scanning done");

DB_close;

DB_open($dbname, $dbuser, $dbpasswd, $dbport, $dbhost);                     # open DB connect

my $control_rout;
my $count_union;
my $count_intersect;
my $arr_router_id;
my $arr_router_names = &DB_getAllHostname();
$logger->info("Duplicate hostname cleanup");
foreach my $namehost(@{$arr_router_names}) {
    $Log->put_debug_key('host', $namehost);
    $arr_router_id = &DB_getRouterIdDuplicateHostname($namehost);
    my @arr_rid = @{$arr_router_id};


    #Pruning routers

    $control_rout = DB_getMinRouterIdentifier($namehost);
    $logger->debug("got main router id $control_rout  for $namehost by router identifier ") if $control_rout;

    if (!$control_rout) {
        $control_rout = &DB_getMinRouterRA($namehost);
        $logger->debug("got main router id $control_rout for $namehost  by access list ") if $control_rout;
    }
    if (!$control_rout) {
        $control_rout = min @arr_rid;
        $logger->debug("got main router id $control_rout for $namehost  by min id ") if $control_rout;
    }

    foreach my $rout_id(@{$arr_router_id}) {
        if ($rout_id != $control_rout) {
            $count_union = &DB_getCountUnion($rout_id, $control_rout);
            $count_intersect = &DB_getCountIntersect($rout_id, $control_rout);
            if ($count_union == $count_intersect) {
                $logger->info("Hostname clenup: $namehost replace id $rout_id with $control_rout");
                &DB_updateLinkA($rout_id, $control_rout);
                &DB_updateLinkB($rout_id, $control_rout);
                &DB_dropRouterId($rout_id);
            }
        }
    }
}
$logger->info("Duplicate hostname clenup done");
#
#foreach my $namehost(@{$arr_router_names})
#{
#    $arr_router_id = &DB_getRouterIdDuplicateHostname( $namehost );
#    my @arr_rid = @{$arr_router_id};
#    my $min_id = min @arr_rid;
#    my $ra_router_id = &DB_getMinRouterRA( $namehost );
#
#    if (defined( $ra_router_id ))
#    {
#        $control_rout = $ra_router_id;
#    }
#    else
#    {
#        $control_rout = $min_id;
#    }
#
#    foreach my $rout_id(@{$arr_router_id})
#    {
#        if ($rout_id != $control_rout)
#        {
#            $count_union = &DB_getCountUnion( $rout_id, $control_rout );
#            $count_intersect = &DB_getCountIntersect( $rout_id, $control_rout );
#            if ($count_union == $count_intersect)
#            {
#                &DB_updateLinkA( $rout_id, $control_rout );
#                &DB_updateLinkB( $rout_id, $control_rout );
#                &DB_dropRouterId( $rout_id );
#            }
#        }
#    }
#}

if ($interact < 1) {

    DB_stopDiscovery(100, 1, 1);
    $logger->info("Audit completed normally.");
}
else {
    DB_stopDiscovery(100, 0, 1);
    $logger->info("Audit completed interactively.");
}

DB_close;

$logger->info ("<------- Closed DB and exiting Audit process.");
## loop through seed hosts
##BGP Discovery
sub discoveryBgp {
    my ($arr_bgps, $is_first_iteration) = @_;
    $logger->info ('===== About to audit hosts[ ',join(' ',@$arr_bgps).' ]');

    foreach my $seedHost (@$arr_bgps) {
        my $bgp_router_id = NGNMS::OLD::DB::DB_getBgpRouterId($seedHost) || 'Undefined';
        $Log->put_debug_key('host', $seedHost);
        $logger->info("Process SeedHost  $seedHost  bgp router id $bgp_router_id");

        #mark self as finished, so it will not bi in reqursive loop
        #        my $bgp_type = 'external';
        #        DB_addBgpRouter($seedHost, $bgp_type, '', '0.0.0.0') unless defined DB_getBgpRouterId($seedHost);
        #        DB_updateBgpRouterStatus($seedHost, $bgp_status);


        my ($hostType, $er);
        if (!$test_topologies) {
            # execute this section if started without -f <file> option
            # poll host with SNMP to get host type
            if ($is_first_iteration && $test_host_type) {
                $hostType = $test_host_type;
                $logger->info("Using host type $hostType from command line for $seedHost") if $hostType;
            }
            if (!$hostType) {
                my $cur_rid = DB_getRouterId($seedHost);
                my $cur_bgp_community = $cur_rid ? getBgpCommunity($cur_rid, $seedHost) : $community;

                ($hostType, $er) = getHostType($seedHost, $cur_bgp_community);
                $logger->info("Using  host type  $hostType from SNMP for $seedHost") if $hostType;
            }
            if (!$hostType) {
                $hostType = DB_getHostVendor($seedHost);
                $logger->info("Using  host type  $hostType from DB for $seedHost") if $hostType;
            }
            if (!$hostType && $is_first_iteration) {
                $hostType = $default_host_type;
                $logger->info("Using DEFAULT  host type  $hostType for $seedHost") if $hostType;
            }

        }
        else {
            # get host type from test file
            if ($is_first_iteration && $test_host_type) {
                $hostType = $test_host_type;
            }
            else {
                ($hostType, $er) = NGNMS::OLD::Util::autodetect_host_type_by_file_content($conf_dir, $seedHost);
                $logger->info("Using  host type  $hostType from files content of $conf_dir") if $hostType;
            }
        }
        if (!$hostType) {
            $logger->error("Skipping $seedHost could not get host type: $er");
            NGNMS::OLD::DB::DB_updateBgpRouterStatus($seedHost, 1); #prevent scanning again
            next;
        }

        if ($hostType eq "unknown") {
            $logger->error("$seedHost: unknown seed host type " . $er);
            NGNMS::OLD::DB::DB_updateBgpRouterStatus($seedHost, 1); #prevent scanning again
            next;
        }
        $dbg_lastSeedHost = $seedHost if ($is_first_iteration);
        $dbg_host_type = $hostType if ($is_first_iteration);

        $logger->debug("$seedHost: host type \"$hostType\"");
        # get network topology from this host


        if (!$test_topologies) {
            # execute this section if started without -f <file> option
            my $new_connect_params = $NEW_CRYPT->getHostCredentials($seedHost);
            #( $user, $passwd, $enpasswd, $access, $path_to_key )
            $new_connect_params->{host} = $seedHost;
            #            my @connect_params = NGNMS::OLD::Util::decode_router_access_method( $seedHost, $user, $passwd, $enpasswd,$access );
            my $ret = &getTopologies($hostType, $new_connect_params);
            #        $ret = &getTopologies($hostType, $seedHost, $user, $passwd, $enpasswd, $access);

            if ($ret ne "ok") {
                $logger->error("Failed to get topology from $seedHost");
                NGNMS::OLD::DB::DB_updateBgpRouterStatus($seedHost, 1); #prevent scanning again
                next;
            }
        }
        if ($hostType eq "Cisco" || $hostType eq "Juniper") {
            my ($bgp_config) = __parse_files ($seedHost, $hostType);
            $logger->error ("Could not parse $hostType files for $seedHost") && next if (!$bgp_config);
            NGNMS::Topology::BGP->new()->write_bgp_topology ($bgp_config, $seedHost);
        }
        else {
            NGNMS::OLD::DB::DB_updateBgpRouterStatus($seedHost, 1); #prevent scanning again
        }
    }
    $Log->put_debug_key('host', '');
}

sub __parse_files {

    my ($cur_bgp_host, $hostBgpType) = @_;
    my $shost = NGNMS::Host::SeedHost->new(
        'config_dir' => $conf_dir,
        'ip_addr'    => $cur_bgp_host,
        'host_type'  => $hostBgpType
    );
    my ($bgp_config);
    $shost->parse_isis();
    $shost->parse_ospf();
    $bgp_config = $shost->parse_bgp();
    #    diag $bgp_config;
    return $bgp_config;
}
sub spawnChild {
    my $spawn_marker = shift;

    my $cmd = shift;
    my $flag_t = 0;
    my $r = \ do {local *FH};
    my $w = \ do {local *FH};
    if (!pipe($r, $w)) {
        $logger->error("Spawn-$spawn_marker :: spawnChild pipe creation failed: $!");
        return;
    }
    my $pid = fork();
    if (!defined($pid)) {
        $logger->error("Spawn-$spawn_marker :: spawnChild fork failed: $!");
        return;
    }

    DB_open($dbname, $dbuser, $dbpasswd, $dbport, $dbhost);         # open DB connect
    my $type_router = DB_getRouterVendor($_[0]);
    DB_close;
    $params[0] = '--host';
    $params[1] = $_[0];

    if (!$pid) {
        # child
        close $r;
        my @cmd2 = ($cmd);

        push @cmd2, '--mode';
        push @cmd2, 'poll-host';
        #        push @cmd2, '-v';
        #        push @cmd2, 2; #todo fix verbose level to override appenders
        push @cmd2, '-L';
        push @cmd2, $dbhost;
        push @cmd2, '-D';
        push @cmd2, $dbname;
        push @cmd2, '-U';
        push @cmd2, $dbuser;
        push @cmd2, '-W';
        push @cmd2, $dbpasswd;
        push @cmd2, '-P';
        push @cmd2, $dbport;

        if ($type_router) {
            $type_router =~ s/\s+$//;                               # remove trailing spaces

            if ($type_router =~ /ocx/i || $type_router eq 'CloudProvider') {
                $flag_t = 1;
            }
        }
        if ($flag_t > 0) {
            $logger->debug("Spawn-$spawn_marker :: spawnChild - OCX type skipped");
        }
        else {
            system(@cmd2, @params);
        }
        exit 0;
    }
    # parent
    close $w;
    return $r;
}

sub waitForSlot {
    # wait for someone to wake up
    my $fdout;
    while (select($fdout = $fdset, undef, undef, undef)) {
        $logger->debug("WaitForSlot - fds: " . unpack("b*", $fdout));

        my @fds = split(//, unpack("b*", $fdout));
        foreach my $fd (0 .. $#fds) {
            #            $logger->debug "Audit_waitForSlot - fd: $fd $fds[$fd]\n";
            next unless $fds[$fd];
            my $awaken = $fdmap{$fd};
            my $buf;
            my $nr = read $pipes{$awaken}, $buf, 8192;
            if ($nr) {
                ;                                                                        # do nothing
            }
            elsif (defined $nr) {
                # EOF reached
                $logger->debug("Child $awaken finished");
                $freeslots++;
                $remaining--;
                $rest = $int_bar - $remaining;                                          # update discovery progress indicator
                $step_bar = int(($pr_bar * $rest) / $int_bar);
                my $up_percent = $start_bar + $step_bar;
                $logger->debug("REST $rest UPPERCENT:$up_percent.");
                DB_open($dbname, $dbuser, $dbpasswd, $dbport, $dbhost);                 # open DB connect
                $cur_percent = DB_percentDiscovery();

                if ($cur_percent < 51 && $cur_percent < $up_percent) {
                    DB_updateDiscoveryStatus ($up_percent, 0);
                }
                DB_close;

                vec($fdset, $fd, 1) = 0;
            }
            else {
                $logger->error ("ERROR: Read error in WaitForSlot sub $!");
                die "Read error: $!\n";
            }
        }
        last if $freeslots;
    }
}

sub spawnForAll {
    my $cmd = shift;
    my @children = @_;
    my $community_l;
    my $amount;
    my $arr_param;
    $freeslots = $slots;
    $remaining = @children;
    my $t_p = 48;
    $criptokey = DB_getCriptoKey();
    my $length = length $criptokey;
    $t_p -= $length;
    my $suffix = ('0' x $t_p);
    $criptokey .= $suffix;
    my $spawn_marker = 0;
    foreach my $child (@children) {

        unless ($freeslots) {
            $logger->info("Child $child is waiting for slot");
            waitForSlot;
        }

        $community_l = $community;          # use generic SNMP community if set
        $arr_param = '';
        DB_open($dbname, $dbuser, $dbpasswd, $dbport, $dbhost);
        my $r_id = DB_getRouterId($child);
        $amount = DB_isCommunity($r_id);
        $logger->debug(" Audit_spawnForAll - preparing to spawn for r_id: $r_id and amount: $amount...");
        if ($amount > 0) {
            $arr_param = DB_getCommunity($r_id);
            foreach my $emp(@$arr_param) {
                $community_l = decryptAttrvalue($criptokey, $emp->[0]) if defined($emp->[0]);
                $community_l = decryptAttrvalue($criptokey, $emp->[1]) if defined($emp->[1]);
            }
            $logger->debug("Audit_spawnForAll - community_l: $community_l...");
        }
        DB_close;

        $logger->info("Spawning child $child");
        my $p = spawnChild ($spawn_marker++, $cmd, $child);
        defined $p or next;
        $pipes{$child} = $p;

        my $fd = fileno($pipes{$child});
        vec($fdset, $fd, 1) = 1;
        $freeslots--;

        $fdmap{$fd} = $child;
    }

    # Wait for all to finish
    while ($remaining) {
        waitForSlot;
    }
}


# Get topology from host
# Params:
# host name or ip
# user
# passwd
# enpasswd
#
sub getTopologies {
    my ($hostType, $connect_params) = (shift, shift);

    #    diag $connect_params;
    $logger->debug("Getting topologies from $hostType device");
    $hostType eq "Cisco" and return &NGNMS::Host::Cisco::get_topologies($connect_params);
    $hostType eq "Juniper" and return &NGNMS::Host::Juniper::get_topologies($connect_params);
    $hostType eq "Linux" and return &NGNMS::Host::Linux::linux_get_topologies($connect_params);
    $hostType eq "HP" and return "ok";
    $hostType eq "Extreme" and return "ok";
}

sub runScanner() {
    my $cmd = shift;

    my @cmd2 = ($cmd);

    push @cmd2, '-L';
    push @cmd2, $dbhost;
    push @cmd2, '-D';
    push @cmd2, $dbname;
    push @cmd2, '-U';
    push @cmd2, $dbuser;
    push @cmd2, '-W';
    push @cmd2, $dbpasswd;
    push @cmd2, '-P';
    push @cmd2, $dbport;
    push @cmd2, '-v';
    push @cmd2, $verbose;

    #    push @cmd2, $user;
    #    push @cmd2, $passwd;
    #    push @cmd2, $enpasswd;
    #    push @cmd2, $access;
    #    push @cmd2, $community;
    #    Emsgd::diag( \@cmd2 ) if ($verbose > 1);
    $logger->info("Initiating subnet scanning process");
    system(@cmd2);

}
#@deprecated, see NGNMS::App:Crypt->decode_snmp_community
sub getBgpCommunity {
    my $r_id = shift;
    my $bgp_host = shift;
    my $amount1 = DB_isCommunity($r_id);
    my $community_cur;

    if ($amount1 > 0) {
        my $arr_param1 = DB_getCommunity($r_id);
        foreach my $emp1(@$arr_param1) {
            $community_cur = decryptAttrvalue($criptokey, $emp1->[0]) if defined($emp1->[0]);
            $community_cur =~ s/\s+$//;
        }
    }
    else {
        my $arr_param7 = DB_isDueCommunity($bgp_host);
        my $counter7 = 0;

        foreach my $emp7(@$arr_param7) {
            if (defined($emp7->[1])) {
                $counter7++;
                $r_id = $emp7->[1];
            }
        }
        if ($counter7) {
            my $arr_param1 = DB_getCommunity($r_id);
            foreach my $emp1(@$arr_param1) {
                $community_cur = decryptAttrvalue($criptokey, $emp1->[0]) if defined($emp1->[0]);
                $community_cur =~ s/\s+$//;
            }
        }
        else {
            my $prom_val = DB_getSettings('community');
            my $community1 = getAttrVal($prom_val->[0]);
            $community_cur = $community1 if defined($community1);
        }
    }

    return $community_cur;
}



sub usage {
    print <<EOF;
Usage: audit.pl [switches] host user passwd enpasswd accesstype[Telnet/SSHv1/SSHv2]

    Switches:
    -np                 skip poll stage
    -s                  run subnets scanner
    -f dirname          get topology from files in dirname
    -t type             host type
    -d                  print verbose info to screen
    -L                  DB host (default:localhost)
    -D                  DB name
    -U                  DB User
    -W                  Pasword for DB user
    -P                  DB Port
    -K                  absolute path to public Key
    -H                  passphrase for public key
    -i                  interactive status updates
    --force-rediscovery Force new discovery. That is - even if previouse process still running new process will be started
    --single-host       Run only audit on single host (host required), scan and poll will not be performed
    Example:
    audit.pl c1600 "" cisco cisco Telnet
    audit.pl -s -L localhost -D ngnms -U ngnms -W ngnms 192.168.3.1 lab cisco cisco SSHv2
    Environment:
    NGNMS_DEBUG - if set to 1, equivalent to -d switch set. Use for debug.
EOF
    exit;
}
sub getAttrVal($) {
    my $in_val = shift;
    my $ret_val;
    $in_val =~ s/^\s+//;            # no leading white
    $in_val =~ s/\s+$//;            # no trailing white
    $ret_val = decryptAttrvalue($criptokey, $in_val) if defined($in_val);
    if (defined($ret_val)) {
        $ret_val =~ s/^\s+//;            # no leading white
        $ret_val =~ s/\s+$//;            # no trailing white
    }

    return $ret_val;
}
__END__
