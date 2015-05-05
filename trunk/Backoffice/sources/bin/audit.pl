#!/usr/bin/perl -w
 

# NextGen NMS Discovery/audit 
#
# Audit main module
#
# Usage: audit.pl [switches] host user passwd enpasswd accesstype(Telnet/SSH1/SSH2)
#
# Switches:
#  -np       skip poll stage
#  -s		 run subnets scanner
#  -f fname  get topologies from files 'file_isis.txt' and 'file_ospf.txt'
#  -t type   host type for the file
#  -d        print debugging info to screen
#  -L        DB host 
#  -D		 DB name
#  -U		 DB User
#  -W 		 Pasword for DB user	
#  -P        DB port
#  -K        absolute path to public Key
#  -H        passpHrase for public key  
#  
# Example: audit.pl c1600 "" cisco cisco Telnet
#
# Environment:
#
#  NGNMS_DEBUG - if not empty, equivalent to -d switch set
#
#  NGNMS_LOGFILE - if set and no debug output to sreen, log is written to this file
#
# Copyright (C) 2002,2003 OptOSS LLC
# Copyright (C) 2014 Opt/Net BV
#
# Author: M.Golov, T.Matselyukh, A. Jaropud
#

use strict;
use threads;

use NGNMS_DB;
use NGNMS_util;

use NGNMS_Cisco;
use NGNMS_JuniperJav;
use NGNMS_Linux;
use NGNMS_Extreme;
use NGNMS_HP;
use DateTime;
use DateTime::Format::Strptime;
use List::Util qw( min max );

use Data::Dumper;

#####################################################################
# General configuration section
#

# Number of simultaneous poll processes
#
my $slots = 12;

#####################################################################
# Variables
#

# Skip the poll stage
#
my $noPoll = 0;

# Print debugging output to screen
my $verbose = "";
my $dbhost = "localhost";
my $dbname = "";
my $dbuser = "";
my $dbpasswd = "";
my $dbport = "5432";
$verbose = $ENV{"NGNMS_DEBUG"} if defined($ENV{"NGNMS_DEBUG"});
my $filesDir="";
my $isis_file;
my $ospf_file;
my $bgp_file;
my $criptokey ;
my $test_topologies;
my $test_host_type;
my $ocx_session;
my $prom_val;
my $scan = 0;
my $interact = 0;
my $bgps;
my $bgp_status = 1;
my $flag_bgp;
my $seedHosts = '';
my $user      = '';
my $passwd    = '';
my $enpasswd  = '';
my $access    = 'Telnet';
my $community = 'public';


 my $path_to_key = "" ;
 my $passphrase = "";
#####################################################################
# Parse command line
#
if($#ARGV < 0)
{
	print <<EOF ;
Usage: audit.pl [switches] host user passwd enpasswd accesstype(Telnet/SSH1/SSH2)

Switches:
 -np       skip poll stage
 -s	   run subnets scanner
 -f fname  get isis topology from file
 -t type   host type for the file
 -d        print debugging info to screen
 -L        DB host (default:localhost)
 -D        DB name
 -U        DB User
 -W        Pasword for DB user
 -P        DB Port
 -K        absolute path to public Key
 -H        passpHrase for public key  
Example: audit.pl c1600 "" cisco cisco Telnet
EOF
    exit;
}
while (($#ARGV >= 0) && ($ARGV[0] =~ /^-.*/)) {
  
  if ($ARGV[0] eq "-np") {
    $noPoll = 1;
  }
  if ($ARGV[0] eq "-i") {
	$interact = 1;
  }
  if ($ARGV[0] eq "-s") {
    $scan = 1;
  }
  if ($ARGV[0] eq "-f") {
    shift @ARGV;
    $test_topologies = $ARGV[0] if defined($ARGV[0]);
    shift @ARGV;
	$seedHosts = $test_topologies;
    next;
  }
  if ($ARGV[0] eq "-t") {
    shift @ARGV;
    $test_host_type = $ARGV[0] if defined($ARGV[0]);
    shift @ARGV;
    next;
  }
  if ($ARGV[0] eq "-d") {
    $verbose = 1;
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
    print <<EOF ;
Usage: audit.pl [switches] host user passwd enpasswd accesstype(Telnet/SSH1/SSH2)

Switches:
 -np       skip poll stage
 -s		   run subnets scanner
 -f fname  get isis topology from file
 -t type   host type for the file
 -d        print debugging info to screen
 -L        DB host (default:localhost)
 -D        DB name
 -U        DB User
 -W 	   Pasword for DB user
 -P        DB Port
 -K        absolute path to public Key
 -H        passpHrase for public key  
Example: audit.pl c1600 "" cisco cisco Telnet
EOF
    exit;
  }
  
  shift @ARGV;
}

#####################################################################

# Redirect stdout if no debugging needed

if ($verbose eq "") {
  # Print debugging output to file

  my $logFile = "/dev/null";
  if (defined($ENV{"NGNMS_LOGFILE"})) {
    $logFile = $ENV{"NGNMS_LOGFILE"};
  }

  open( STDERR, ">&STDOUT") or
    warn "Failed to redirect stderr to stdout: $!\n";
  open( STDOUT, "> $logFile") or
    warn "Failed to redirect stdout to $logFile: $!\n";
}


my $seedf = "$ENV{'NGNMS_HOME'}/share/poll.cfg";
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

DB_open($dbname,$dbuser,$dbpasswd,$dbport,$dbhost);
    
	if(DB_isOpenedDiscovery())
	{
		my $ls_discovery = DB_lastchangeDiscovery();
		my $parser = DateTime::Format::Strptime->new(
			pattern => '%Y-%m-%d %H:%M:%S',
			on_error => 'croak',
		);
		my $dt = $parser->parse_datetime($ls_discovery);
		my $ls_timestamp = $dt->epoch;
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =localtime(time);
		$year = $year + 1900;
		$mon = $mon+1;;
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
		if($tm_diff > 600)
		{
			DB_stopDiscovery (0,1,0);
		}

		
		die "Audit cannot be run! There is other open audit \n";
	}
     
	 
	DB_insertDiscoveryStatus ('ngnms',$interact); 
    
	my $p=48;
	$criptokey = DB_getCriptoKey();
	my $length = length $criptokey ;
	$p -= $length; 
	my $suffix =  ( '0' x $p );
	$criptokey.=$suffix;
	
    $prom_val = DB_getSettings('seedHost');
    $seedHosts = getAttrVal($prom_val->[0]);
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
$seedHosts = shift @ARGV if $#ARGV >=0;
$user      = shift @ARGV if $#ARGV >=0;
$passwd    = shift @ARGV if $#ARGV >=0;
$enpasswd  = shift @ARGV if $#ARGV >=0;
$access    = shift @ARGV if $#ARGV >=0;
$community = shift @ARGV if $#ARGV >=0;
if($access =~ m/SSH/i)
{
	$access = 'SSH';
}

	$access    = 'Telnet' unless ($access eq 'SSH' || $access eq 'Telnet');


=for
print $seedHosts."\n";
print $user."\n";
print $passwd."\n";
print $enpasswd."\n";
print $access."\n";
print $community."\n";
=cut


my @seedHostList = split /,/,$seedHosts ;

print "Seed host(s): $seedHosts\n";
##print "User:         $user\n";
# print "Password:     $passwd\n";
# print "En. password: $enpasswd\n";
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
		  logError("bgp", "Failed to get topology from $cur_bgp_host: $ret\n");
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
foreach $seedHost (@seedHostList) {
  $seedHost =~ s/^\s+//;			# no leading white
  $seedHost =~ s/\s+$//;			# no trailing white

  if (!defined($test_topologies)) {
    if (defined($test_host_type)) {
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
	logError("audit", "$seedHost: unknown seed host type\n");
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
  ##print "$seedHost: host type \"$hostType\"\n";

  # get network topology from this host

  if (!defined($test_topologies)) {
    
		$ret = &getTopologies($hostType,$seedHost,$user,$passwd,$enpasswd,$access);

		if($ret ne "ok") {
		  logError("audit", "Failed to get topology from $seedHost: $ret\n");
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
  DB_updateDiscoveryStatus(15,0);## getting Topology process was ended
} # loop through seed hosts

if ($noPoll) {
  print "Skipping polling stage.\n";
  DB_close;
  exit;
}


# now we have all nodes in the network
# start polling them all

my %hosts = DB_getRouters(".*");
=for
foreach my $child (keys %hosts) {
	print $child."->".$hosts{$child}."\n";
	}
 die();
=cut
 
	if(!%hosts) {
	  logError("audit","No network found\n");
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
		logError("audit","pipe create failed: $!");
		return undef;
	  }
	  my $pid = fork();
	  if(!defined($pid)) {
		logError("audit","fork failed: $!");
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
			print "OCX type is skipped\n";
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

DB_close;
sleep(1);
if($scan > 0)
{

		&runScanner("$ENV{'NGNMS_HOME'}/bin/subnets_scanner.pl");
}




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
		system( @cmd2, @params );
	
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
__END__

