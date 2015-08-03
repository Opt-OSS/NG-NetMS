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
use lib "$ENV{'NGNMS_HOME'}/lib/";

use strict;
use threads;
use warnings;

use NGNMS_DB;
use NGNMS_util;
use NGNMS_Cisco;
use NGNMS_JuniperJav;
use NGNMS_Linux;
use NGNMS_Extreme;
use NGNMS_HP;
use Net::Netmask;
use DateTime;
use DateTime::Format::Strptime;
use List::Util qw( min max );

use Data::Dumper;

use Emsgd;

############################   START ################################
logError("audit","Program initialization");

#####################################################################
# General configuration section
#####################################################################
# Variables
#
# Number of simultaneous poll processes
#
my $slots           = 12;
# Skip the poll stage by default
#
my $noPoll          = 0;

my $dbhost = "localhost";
my $dbname          = "";
my $dbuser          = "";
my $dbpasswd        = "";
my $dbport      = "5432";
my $filesDir        = "";
my $isis_file;
my $ospf_file;
my $bgp_file;
my $criptokey ;
my $test_topologies;
my $test_host_type;
my $ocx_session;
my $prom_val;
my $scan            = 0;
my $interact        = 0;
my $bgps;
my $bgp_status      = 1;
my $flag_bgp;
my $seedHosts       = '';
my $user            = '';
my $passwd          = '';
my $enpasswd        = '';
my $access          = '';
my $community       = '';
my $lastSeedHost    = '';
my $logFile= "/dev/null";
my $path_to_key     = "";
my $passphrase      = "";

# Print debugging output to screen if in debug
my $verbose = 0;
$verbose = $ENV{"NGNMS_DEBUG"} if defined($ENV{"NGNMS_DEBUG"});

# Redirect stdout if deep debugging is required
if ($verbose) {
  # Print debugging output to file if NGNMS_DEBUG is defined
  logError("audit", "Started in debug mode due to NGNMS_DEBUG= $verbose...");

  if (defined($ENV{"NGNMS_LOGFILE"})) {
    $logFile = $ENV{"NGNMS_LOGFILE"};
# reduce number of slots to 1 if debugging an issue
    $slots = 1;
print "#Debug - Reducing number of slots to: $slots\n" if ($verbose > 1);
print "-> Will print debug output to file [$logFile]\n";
  }
# Will create a new file or overrite existing $logFile
  open( STDERR, ">&STDOUT") or
    warn "Failed to redirect STDERR to STDOUT: $!\n";
  open( STDOUT, "> $logFile") or
    warn "Failed to redirect STDOUT to $logFile: $!\n";
}

#####################################################################
# Parse command line
#
print "#Audit -- Parsing command line...\n" if ($verbose);
if($#ARGV < 0)
{
    &usage;
    logError("audit", "Started without arguments. Exiting audit programme.");
    exit;
}
while (($#ARGV >= 0) && ($ARGV[0] =~ /^-.*/)) {

print "#Debug - in arg while $ARGV[0]\n" if ($verbose > 1);

  if ($ARGV[0] eq "-np") {
    $noPoll = 1;
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
    $test_topologies = $ARGV[0] if defined($ARGV[0]);
	$seedHosts = $test_topologies;
    shift @ARGV;
    next;
  }
  if ($ARGV[0] eq "-t") {
    shift @ARGV;
    $test_host_type = $ARGV[0] if defined($ARGV[0]);
    print "#Debug - test_host_type: $test_host_type\n" if ($verbose >1);
    shift @ARGV;
    next;
  }
  if ($ARGV[0] eq "-d") {
    $verbose = 1 if ($verbose == 0);    # ignore -d option if already in deep debug mode due to environment set
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
    logError("audit","Displaying help, exiting audit programme.");
    exit;
  }
  
  shift @ARGV;
}
print "#Debug - Finished argument processing...\n" if ($verbose >1);

#####################################################################

sub getAttrVal($)
{
	my $in_val = shift;
	my $ret_val;
	$in_val =~ s/^\s+//;			# no leading white
    $in_val =~ s/\s+$//;			# no trailing white
    $ret_val = decryptAttrvalue($criptokey, $in_val) if defined($in_val);
    if(defined($ret_val))
    {
		$ret_val =~ s/^\s+//;			# no leading white
		$ret_val =~ s/\s+$//;			# no trailing white
		}
    
    return $ret_val;
	}
print "Opening DB...\n" if ($verbose);

DB_open($dbname,$dbuser,$dbpasswd,$dbport,$dbhost);

	if(DB_isOpenedDiscovery())
	{
		my $ls_discovery = DB_lastchangeDiscovery();
		if (!$ls_discovery) {
	# Error exception - this will fix it until we find out why audit exits with no defined $ls_discovery timestamp
	# Most likely a new audit termination did not update the DB_stopDiscovery exit codes correctly
		print "#Debug - Something whent wrong in prior audit, \$ls_discovery is not defined\n" if ($verbose >1);
		$ls_discovery = "2000-01-01 00:00:00.0" if ($interact); # 'fixing' the problem, assuming that there is a person who runs audit interactively
		}
        print "#Debug - Last changeDiscovery was at $ls_discovery \n" if ($verbose >1);
      	my $parser = DateTime::Format::Strptime->new(
			pattern => '%Y-%m-%d%n%H:%M:%S.%N',
			on_error => 'croak',
		);

		my $dt = $parser->parse_datetime($ls_discovery);
            print "#Debug - dt=$dt\n" if ($verbose >1);

		my $ls_timestamp = $dt->epoch;
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =localtime(time);
		$year = $year + 1900;
		$mon = $mon+1;
		$dt = DateTime->new(
			year       => $year,
			month      => $mon,
			day        => $mday,
			hour       => $hour,
			minute     => $min,
			second     => $sec,  
		);  
		my $tm_now = $dt->epoch;
		my $tm_diff = $tm_now - $ls_timestamp;
		if($tm_diff > 600)  ## potential issue here if one discovery runs longer than 10min
		{
			DB_stopDiscovery (0,1,0); # %=0, finish=1, mode=0 (override overdue session closure)

		}
        logError("audit","Warning! Audit process cannot be run at this time! There is another running audit process...");
		die "Warning! Audit process cannot be run at this time! There is another running audit process... \n";
	}

print "Initiating start of discovery: User:[$user]. Interactive mode:[$interact]\n" if ($verbose);
	DB_insertDiscoveryStatus ($user,$interact); 

print "Setting crypto access to DB\n" if ($verbose);
	my $p=48;
	$criptokey = DB_getCriptoKey();
	my $length = length $criptokey ;
	$p -= $length; 
	my $suffix =  ( '0' x $p );
	$criptokey.=$suffix;
print "#Debug - cryptokey $criptokey\n" if ($verbose >1);

print "Getting access credentials and seed host settings from DB...\n" if ($verbose);
#Important section where command line arguments should override DB settings if defined
    $prom_val = DB_getSettings('seedHost');
    $seedHosts = getAttrVal($prom_val->[0]);
    $prom_val = DB_getSettings('hostType');
    my $test_host_type1 = getAttrVal($prom_val->[0]);
print "#Debug - test_host_type =[$test_host_type] \n" if ($verbose >1);
    $test_host_type = $test_host_type1 unless defined($test_host_type);
print "#Debug - test_host_type =[$test_host_type] -- if command line argument is set\n" if ($verbose >1);
    $prom_val = DB_getSettings('username');
    $user = getAttrVal($prom_val->[0]);
    $prom_val = DB_getSettings('password');
    $passwd = getAttrVal($prom_val->[0]);
    $prom_val = DB_getSettings('enpassword');
    $enpasswd = getAttrVal($prom_val->[0]);
    $prom_val = DB_getSettings('type access');
    my $access1 = getAttrVal($prom_val->[0]);
    $access = $access1 if defined($access1);
    $prom_val = DB_getSettings('community');
    my $community1 = getAttrVal($prom_val->[0]) ;
    $community = $community1 if defined($community1);
DB_close;

print "Seed host settings initialized\n" if ($verbose);
$seedHosts = shift @ARGV if $#ARGV >=0;
$user      = shift @ARGV if $#ARGV >=0;
$passwd    = shift @ARGV if $#ARGV >=0;
$enpasswd  = shift @ARGV if $#ARGV >=0;
$access    = shift @ARGV if $#ARGV >=0;
$community = shift @ARGV if $#ARGV >=0;

# Determine access type for seed host
if($access =~ m/SSH/i)
{
	$access = 'SSH';
}
	$access    = 'Telnet' unless ($access eq 'SSH' || $access eq 'Telnet');

print "#Debug -- seed host settings check:\
User: [$user]
Pswd: [$passwd]
Enpw: [$enpasswd]
Access type: [$access]
SNMP community: [$community]
Host Type: [$test_host_type]\n" if ($verbose > 1);

my @seedHostList = split /,/,$seedHosts ;

logError ("audit","Seed host(s): $seedHosts");

my $cmd1 = " -D ".$dbname." -U ".$dbuser." -W ".$dbpasswd." -P ".$dbport." -L ".$dbhost;

# Get ISIS topology from host
# Params:
#  host name or ip
# user
# passwd
# enpasswd

sub getTopologies {
  my $hostType = shift;
  $hostType eq "Cisco" and return &NGNMS_Cisco::cisco_get_topologies;
  $hostType eq "Juniper" and return &NGNMS_JuniperJav::juniper_get_topologies;
  $hostType eq "Linux" and return &NGNMS_Linux::linux_get_topologies;
  $hostType eq "HP" and return &NGNMS_HP::hp_get_topologies;
  $hostType eq "Extreme" and return &NGNMS_Extreme::extreme_get_topologies;
}


DB_open($dbname,$dbuser,$dbpasswd,$dbport,$dbhost);

#DB_vacuum;

my $hostType;
my $seedHost;
my $ret;

##BGP Discovery
sub discoveryBgp($){
	my @arr_bgps;
	my $cur_bgp_community;
	my $cur_bgp_host;
	my $cur_rid;
	my $hostBgpType;
	my $bgps1;
	my $er1;
	my $isis_file;
	my $ospf_file;
	my $bgp_file;
	
    my $bgps0 = shift;
	@arr_bgps = @{$bgps0};
    for (my $i = 0; $i < @arr_bgps; $i++) {
		 DB_updateBgpRouterStatus($arr_bgps[$i]->[0],$bgp_status);
         $cur_bgp_host = $arr_bgps[$i]->[0];
         $cur_rid = DB_getRouterId($cur_bgp_host);
         if(defined $cur_rid){
			$cur_bgp_community = &getBgpCommunity($cur_rid,$cur_bgp_host);	
		 }
		 else
		 {
			 $cur_bgp_community = $community;
		 }	  
		 ($hostBgpType, $er1) = getHostType($cur_bgp_host, $cur_bgp_community);
		 
		 if (!defined($hostBgpType)) {
			logError("bgp:", $er1);
			next;
		}
		
		if($hostBgpType ne 'Cisco' && $hostBgpType ne 'Juniper' )
		{
			logError("bgp:", "This device is not supported!");
			next;
		}
		
		$ret = &getTopologies($hostBgpType,$cur_bgp_host,$user,$passwd,$enpasswd,$access);

		if($ret ne "ok") {
		  logError("bgp", "Failed to get topology from $cur_bgp_host: $ret");
		  next;
		}
		if (defined($ENV{"NGNMS_CONFIGS"})) {
				$isis_file = $ENV{"NGNMS_CONFIGS"}."/"."${cur_bgp_host}_isis.txt";
				$ospf_file = $ENV{"NGNMS_CONFIGS"}."/"."${cur_bgp_host}_ospf.txt";
				$bgp_file = $ENV{"NGNMS_CONFIGS"}."/"."${cur_bgp_host}_bgp.txt";
			}
			else
			{
				$isis_file = "${cur_bgp_host}_isis.txt";
				$ospf_file = "${cur_bgp_host}_ospf.txt";
				$bgp_file = "${cur_bgp_host}_bgp.txt";
			}
		$ret = '';
		if ($hostBgpType eq "Cisco") {
			NGNMS_Cisco::cisco_parse_isis $isis_file;
			NGNMS_Cisco::cisco_parse_ospf $ospf_file;
			$bgps1 = NGNMS_Cisco::cisco_parse_bgp($bgp_file,$cur_bgp_host);
		}
		if ($hostBgpType eq "Juniper") {
		NGNMS_JuniperJav::juniper_parse_isis $isis_file;
		NGNMS_JuniperJav::juniper_parse_ospf $ospf_file;
		$bgps1 = NGNMS_JuniperJav::juniper_parse_bgp($bgp_file,$cur_bgp_host);
		}	
	    if(defined $bgps1){
			&discoveryBgp($bgps1);
			}		
	  }
	
	}
####
DB_updateAllBgpRouterStatus();
# Loop through the seed hosts
print "Looping through all seed hosts...\n" if ($verbose);
foreach $seedHost (@seedHostList) {
  $seedHost =~ s/^\s+//;			# no leading white
  $seedHost =~ s/\s+$//;			# no trailing white
  $lastSeedHost = $seedHost;

  if (!defined($test_topologies)) {
	  $length=$test_host_type=~y///c;
    if (defined($test_host_type) && $length > 0) {
		
      $hostType = $test_host_type;
    } else {
		
      # poll host to get host type
      my $er;
      ($hostType, $er) = getHostType($seedHost, $community);
      if (!defined($hostType)) {
		logError("audit", $er);
		next;
      }
      if ($hostType eq "unknown") {
	logError("audit", "$seedHost: unknown seed host type");
	next;
      }
    }
  } else {
    # get host type from test file or cmd line
    if( defined($test_topologies) && !defined($test_host_type) ) {
      $test_topologies =~ /.*(Cisco|Juniper).*/;
      $test_host_type = $1;
    }
	
    $hostType = $test_host_type;
  }
DB_updateDiscoveryStatus(5,0);## SNMP process was ended
  print "$seedHost: host type \"$hostType\"\n" if ($verbose);

  # get network topology from this host

  if (!defined($test_topologies)) {
    
		$ret = &getTopologies($hostType,$seedHost,$user,$passwd,$enpasswd,$access);

		if($ret ne "ok") {
		  logError("audit", "Failed to get topology from $seedHost: $ret");
		  next;
		}
		
		if($hostType ne 'OCX' && $hostType ne 'Linux' && $hostType ne 'HP' && $hostType ne 'Extreme')
		{	if (defined($ENV{"NGNMS_CONFIGS"})) {
				$isis_file = $ENV{"NGNMS_CONFIGS"}."/"."${seedHost}_isis.txt";
				$ospf_file = $ENV{"NGNMS_CONFIGS"}."/"."${seedHost}_ospf.txt";
				$bgp_file = $ENV{"NGNMS_CONFIGS"}."/"."${seedHost}_bgp.txt";
			}
			else
			{
				$isis_file = "${seedHost}_isis.txt";
				$ospf_file = "${seedHost}_ospf.txt";
				$bgp_file = "${seedHost}_bgp.txt";
			}
			
		}
  } else {
     if (defined($ENV{"NGNMS_CONFIGS"})) {
		$filesDir = $ENV{"NGNMS_CONFIGS"};
	}
    $isis_file = $filesDir."/"."${test_topologies}_isis.txt";
    $ospf_file = $filesDir."/"."${test_topologies}_ospf.txt";
    $bgp_file = $filesDir."/"."${test_topologies}_bgp.txt";
	
  }

  $ret = '';
  
	
  if ($hostType eq "Cisco") {
    NGNMS_Cisco::cisco_parse_isis $isis_file;
    NGNMS_Cisco::cisco_parse_ospf $ospf_file;
    $bgps = NGNMS_Cisco::cisco_parse_bgp($bgp_file,$seedHost);
  }
  if ($hostType eq "Juniper") {
    NGNMS_JuniperJav::juniper_parse_isis $isis_file;
    NGNMS_JuniperJav::juniper_parse_ospf $ospf_file;
    $bgps = NGNMS_JuniperJav::juniper_parse_bgp($bgp_file,$seedHost);
  }
  
  my $bgp_type = 'external';
  
  if(defined $bgps)
  {
	 $flag_bgp = DB_getBgpRouterId($seedHost);
    if(!defined($flag_bgp))
    {	
		$flag_bgp = DB_addBgpRouter($seedHost,$bgp_type,'');
	}
	DB_updateBgpRouterStatus($seedHost,$bgp_status);
	  discoveryBgp($bgps);
	}
  DB_updateDiscoveryStatus(15,0);
  ## getting Topology process ended
}
## loop through seed hosts

print "Preparing polling stage...\n" if ($verbose);

if ($noPoll) {
  logError("audit", "No poll flag is set. Skipping polling stage.");
  if($interact < 1)
	{
	
		DB_stopDiscovery(15,1,1); # in non interactive mode setting %=15, finish=1, mode=1 (normal)
	
	}
	else
	{
		DB_stopDiscovery(15,0,1); # in interactive mode setting %=15, finish=0, mode=1 (normal) -- WHY finish=0?
	}
  DB_close;
  exit;
}

#########################################
# now we have all nodes in the network
# start polling them all

my %hosts = DB_getRouters(".*");

    if ($verbose) {
     print "Initiating polling of all nodes from topology...\n";
    if ($verbose >1 ){
     foreach my $child (keys %hosts) {
	 print $child."-> host_ID=".$hosts{$child}."\n";
	    }
	  }
    }

	if(!%hosts) {
	  logError("audit","No network hosts found to poll. Exiting...");
	  if($interact < 1)
		{
			DB_stopDiscovery(15,1,1);
		}
	  else
		{
			DB_stopDiscovery(15,0,1);
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
	my $count_bar =0;
	my $int_bar;
	my $step_bar;
	my $rest;
	my $i;
	my @params = ();
	my $arr_param =();

	sub spawnChild {
	  my $cmd = shift;
	  my $flag_t = 0;
	  my $r = \ do {local *FH};
	  my $w = \ do {local *FH};
	  if(!pipe($r, $w)) {
		logError("audit.pl","pipe creation failed: $!");
		return undef;
	  }
	  my $pid = fork();
	  if(!defined($pid)) {
		logError("audit.pl","fork failed: $!");
		return undef;
	  }
	  
		
		my $flag ;

		DB_open($dbname,$dbuser,$dbpasswd,$dbport,$dbhost);# open DB connect
		my $type_router = DB_getRouterVendor($_[0]);
		$type_router =~ s/\s+$//;
		DB_close; ## close DB connect
		$params[0] = $_[0];
		
	  if (!$pid) {			# child
		close $r;
		my @cmd2=($cmd);
		
		push @cmd2,'-d';
		push @cmd2,'-L';
		push @cmd2,$dbhost;
		push @cmd2,'-D';
		push @cmd2,$dbname;
		push @cmd2,'-U';
		push @cmd2,$dbuser;
		push @cmd2,'-W';
		push @cmd2,$dbpasswd;
		push @cmd2,'-P';
		push @cmd2,$dbport;
	
		if(defined($type_router))
		{
			if($type_router =~/ocx/i || $type_router eq 'CloudProvider')
			{
				$flag_t = 1;
				}
		}
		if($flag_t > 0)
		{
			print "OCX type skipped\n" if ($verbose);
		}
		else 
		{	
		  system( @cmd2, @params );
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
	  while( select($fdout=$fdset, undef, undef, undef)) {
		# print "fds: ", unpack("b*", $fdout), "\n";

		my @fds = split(//, unpack("b*", $fdout));
		foreach my $fd (0..$#fds) {
		  # print "$fd $fds[$fd]\n";
		  next unless $fds[$fd];
		  my $awaken = $fdmap{$fd};
		  my $buf;
		  my $nr = read $pipes{$awaken}, $buf, 8192;
		  if ($nr) {
		;			# do nothing
		  } elsif (defined $nr) {	# EOF
		print "Child $awaken finished\n";
		$freeslots++;
		$remaining--;
		$rest = $int_bar - $remaining;
		$step_bar = int(($pr_bar * $rest)/$int_bar);
		my $up_percent = $start_bar + $step_bar;
		print "REST $rest UPPERCENT:$up_percent.\n";
			DB_open($dbname,$dbuser,$dbpasswd,$dbport,$dbhost);# open DB connect
			my $cur_percent = DB_percentDiscovery();
			
			if($cur_percent <51 && $cur_percent < $up_percent)
			{
				DB_updateDiscoveryStatus ($up_percent,0);	
			}
			DB_close;
		
		vec($fdset, $fd, 1) = 0;
		  } else {
		  logError ("audit", "ERROR: Read error in WaitForSlot sub $!");
		  print "DIE LINE 793" if ($verbose);
		  die "Read error: $!\n";
		  }
		}
		last if $freeslots;
	  }
	}

	sub spawnForAll ($@) {
	  my $cmd = shift;
	  my @children = @_;
	  my $community_l;
	  my $amount;	 
	  my $arr_param;
	  $freeslots = $slots;
	  $remaining = @children;
	  my $p=48;
	  $criptokey = DB_getCriptoKey();
	  my $length = length $criptokey ;
	  $p -= $length; 
	  my $suffix =  ( '0' x $p );
	  $criptokey.=$suffix;
	  
	  
	  foreach my $child (@children) {

		unless ($freeslots) {
		  print "Child $child is waiting for slot\n";
		  waitForSlot;
		}

		print "Spawning child $child\n";
		$community_l = $community;
		$arr_param = '';
		DB_open($dbname,$dbuser,$dbpasswd,$dbport,$dbhost);
			my $r_id = DB_getRouterId($child);
			$amount = DB_isCommunity($r_id);
			
			if($amount > 0)
			{
				$arr_param = DB_getCommunity($r_id);
				foreach my $emp(@$arr_param)
				{
					$community_l = decryptAttrvalue($criptokey, $emp->[0]) if defined($emp->[0]);
					$community_l = decryptAttrvalue($criptokey,$emp->[1]) if defined($emp->[1]);
				}
				 
				
			}
		DB_close;
		
		my $p = spawnChild ( $cmd, $child, $user, $passwd, $enpasswd,$community_l,$access,$path_to_key );
		defined $p or next;
		$pipes{$child} = $p;

		my $fd = fileno($pipes{$child});
		vec($fdset, $fd, 1) = 1;
		$freeslots--;

		$fdmap{$fd} = $child;
	  }

	  # Wait for all to finish
		while ( $remaining ) {
		  waitForSlot;
		}
	}

	my $Nchildren = keys %hosts;

	print "Starting polling\n";
	print "Total $slots slots\n";
	print "Total $Nchildren children\n";
	
    $int_bar = $Nchildren;
    
	spawnForAll ("$ENV{'NGNMS_HOME'}/bin/poll_host.pl", keys %hosts );

	print "Polling done\n";
DB_open($dbname,$dbuser,$dbpasswd,$dbport,$dbhost);# open DB connect
my $cur_percent = DB_percentDiscovery();
if($cur_percent <51)
{
	DB_updateDiscoveryStatus(50,0);## Polling process was ended
}


sleep(1);
if($scan > 0)
{

		&runScanner("$ENV{'NGNMS_HOME'}/bin/subnets_scanner.pl");
}
else
{
	if($hostType eq 'Linux'){
		
		my $seed_router_id = DB_getRouterId($lastSeedHost);
		my @seedIntefaces = @{DB_getInterfacesAll($seed_router_id)};
		my $control_block;
		my @arrIp = ();
		foreach my $seedInterface(@seedIntefaces){
			push @arrIp,$seedInterface->[1];
			}
		
		my $hostswls = DB_getRoutersWithoutLinks();
		foreach my $hostswl (@{$hostswls})
		{
			my @wlinterfaces = @{DB_getInterfacesAll($hostswl->[0])};
			foreach my $wlinterface(@wlinterfaces)
			{
				my $control_block=new Net::Netmask ($wlinterface->[1] , $wlinterface->[2]);
				if($control_block->match($arrIp[0])){
					DB_writeLink($seed_router_id,$hostswl->[0],'B')
					}
				}
		}
	}
}
DB_close;



DB_open($dbname,$dbuser,$dbpasswd,$dbport,$dbhost);# open DB connect

            my $control_rout;
			my $count_union;
			my $count_intersect;
			my $arr_router_id;
			my $arr_router_names = &DB_getAllHostname();
			
            foreach my $namehost(@{$arr_router_names})
            {
				$arr_router_id = &DB_getRouterIdDuplicateHostname($namehost);
				my @arr_rid = @{$arr_router_id};
				my $min_id = min @arr_rid;
				my $ra_router_id = &DB_getMinRouterRA($namehost);
				
				if(defined($ra_router_id))
				{
					$control_rout = $ra_router_id;
				}
				else
				{
					$control_rout = $min_id;
				}
			
				foreach my $rout_id(@{$arr_router_id})
				{
					if($rout_id != $control_rout)
					{
						$count_union = &DB_getCountUnion($rout_id,$control_rout);
						$count_intersect = &DB_getCountIntersect($rout_id,$control_rout);
						if($count_union == $count_intersect)
						{
							&DB_updateLinkA($rout_id,$control_rout);
							&DB_updateLinkB($rout_id,$control_rout);
							&DB_dropRouterId($rout_id);
						}
					}
				}
			}


if($interact < 1)
{
	
	DB_stopDiscovery(100,1,1);
	
}
else
{
	DB_stopDiscovery(100,0,1);
}

DB_close;
sub runScanner()
{
	my $cmd = shift;

	my @cmd2=($cmd);
	my @params = ($user, $passwd,$enpasswd,$access,$community);
	
		push @cmd2,'-L';
		push @cmd2,$dbhost;
		push @cmd2,'-D';
		push @cmd2,$dbname;
		push @cmd2,'-U';
		push @cmd2,$dbuser;
		push @cmd2,'-W';
		push @cmd2,$dbpasswd;
		push @cmd2,'-P';
		push @cmd2,$dbport;
		push @cmd2,$user;
		push @cmd2,$passwd;
		push @cmd2,$enpasswd;
		push @cmd2,$access;
		push @cmd2,$community;
		Emsgd::print(\@cmd2);
		system( @cmd2 );
	
	}
	
sub getBgpCommunity($$)	
{
	my $r_id = shift;
	my $bgp_host = shift;
	my $amount1 = DB_isCommunity($r_id);
	my $community_cur;		
	
	if($amount1 > 0)
	{
		my $arr_param1 = DB_getCommunity($r_id);
		foreach my $emp1(@$arr_param1)
		{
			$community_cur = decryptAttrvalue($criptokey, $emp1->[0]) if defined($emp1->[0]);
			$community_cur =~ s/\s+$//; 
		}						 	
	}
    else
	{
		my $arr_param7 = DB_isDueCommunity($bgp_host);
		my $counter7 = 0;
		
		foreach my $emp7(@$arr_param7){										
			if (defined($emp7->[1]))
			{
				$counter7++;
				$r_id =  $emp7->[1];
			}		 		
		}
		if($counter7)
		{
			my $arr_param1 = DB_getCommunity($r_id);
			foreach my $emp1(@$arr_param1)
			{
				$community_cur = decryptAttrvalue($criptokey, $emp1->[0]) if defined($emp1->[0]);
				$community_cur =~ s/\s+$//; 
			}	
		}
		else
		{
			my $prom_val = DB_getSettings('community');
			my $community1 = getAttrVal($prom_val->[0]) ;
			$community_cur = $community1 if defined($community1);
		}		
	}	
				
	return $community_cur;			
}

sub usage {
	print <<EOF ;
Usage: audit.pl [switches] host user passwd enpasswd accesstype[Telnet/SSHv1/SSHv2]

Switches:
 -np       skip poll stage
 -s	   run subnets scanner
 -f fname  get isis topology from file
 -t type   host type for the file
 -d        verbose info to screen
 -L        DB host (default:localhost)
 -D        DB name
 -U        DB User
 -W        Pasword for DB user
 -P        DB Port
 -K        absolute path to public Key
 -H        passpHrase for public key
 -i        interactive status updates
Example:
audit.pl c1600 "" cisco cisco Telnet
audit.pl -s -L localhost -D ngnms -U ngnms -W ngnms 192.168.3.1 lab cisco cisco SSHv2
Environment:
  NGNMS_DEBUG - if set to 1, equivalent to -d switch set. Use for deep debug.
  NGNMS_LOGFILE - if set, log is written to this file
EOF
exit;
}
__END__