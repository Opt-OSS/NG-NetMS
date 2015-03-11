#!/usr/bin/perl -w
 
#
# Poll configuration from a single host
#
# Usage:
#  poll_host.pl [switches] host user passwd en_passwd community access_type pass_to_key
#
# Switches:
#  -np      Only process config files
#  -p path  Path to config files
#  -t type  Host type
#  -L        DB host (default:localhost)
#  -D		 DB name
#  -U		 DB User
#  -W 		 Pasword for DB user	
#  -P        DB port
#
# Produces 3 logs (<host>_*.log) and 3 output files (<host>_*.txt)
# Updates the database
#
# Environment:
#
#  NGNMS_DEBUG - if not empty, equivalent to -d switch set
#
#  NGNMS_LOGFILE - if set and no debug output to sreen, log is written to this file
#
# Copyright (C) 2002,2003 OptOSS LLC
#
# Author: M.Golov
#
use strict;

use NGNMS_Cisco;
use NGNMS_JuniperJav;
use NGNMS_Linux;
use NGNMS_Extreme;
use NGNMS_HP;
use NGNMS_SSG5;

use NGNMS_util;
use NGNMS_DB;

 use Data::Dumper;

use passwds;

#####################################################################
# General configuration section
#

# (empty)

#####################################################################
# Variables
#

# Skip the poll stage
my $noPoll = 0;
my $dbname = "";
my $dbuser = "";
my $dbpasswd = "";
my $dbport = "5432";
my $dbhost = 'localhost';
my $rt_id;
my $criptokey;
my $host;
my $user;
my $passwd;
my $enpasswd;
my $community;
my $access;
my $path_to_key;
my $prom_val;
my $flag;
my $type_router;

my $hostType;

# Where are the config files stored
my $configPath = "";

my $test_host_type;

my $seedf = "$ENV{'NGNMS_HOME'}/share/poll.cfg";

# Print debugging output to screen
my $verbose = "";
$verbose = $ENV{"NGNMS_DEBUG"} if defined($ENV{"NGNMS_DEBUG"});

#####################################################################
# Parse command line
#

while (($#ARGV >= 0) && ($ARGV[0] =~ /^-.*/)) {
  if ($ARGV[0] eq "-np") {
    $noPoll = 1;
  }
  if ($ARGV[0] eq "-p") {
    shift @ARGV;
    $configPath = $ARGV[0] if defined($ARGV[0]);
    shift @ARGV;
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
  
  if ($ARGV[0] eq "-L") {
    shift @ARGV;
    $dbhost = $ARGV[0] if defined($ARGV[0]);
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
	
  if ($ARGV[0] eq "-h") {
    print <<EOF ;
Usage:
  poll_host.pl [switches] host user passwd en_passwd community access_type(Telnet/SSH) pass_to_key(if it exist)

  Switches:
   -np      Only process config files
   -p path  Path to config files
   -t type  Host type
   -d       Print debug output to screen
   -L       DB host (default:localhost)
   -D       DB name
   -U	 	DB User
   -W		Pasword for DB user
   -P		DB Port
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

die "Usage: $0 host [user passwd en_passwd community]\n" unless ($#ARGV >= 0);
($host) = $ARGV[0];
DB_open($dbname,$dbuser,$dbpasswd,$dbport,$dbhost);# open DB connect
my $p=48;
$criptokey = DB_getCriptoKey();
my $length = length $criptokey ;
$p -= $length; 
my $suffix =  ( '0' x $p );
$criptokey.=$suffix;
########################

		
		$type_router = DB_getRouterVendor($host);
		my $r_id = DB_getRouterId($host);
		if(defined $type_router)
		{
			$type_router =~ s/\s+$//;
		}
		my $amount = DB_isInRouterAccess($host);# check exists special access to router
		if(!defined($amount))
		{
			$amount =0;
		}
           
		if($amount < 1)	##if is not special access to router then it connects with default parameters
		{
			$prom_val = DB_getSettings('username');
			$user = getAttrVal($prom_val->[0]);
			$prom_val = DB_getSettings('password');
			$passwd = getAttrVal($prom_val->[0]);
			$prom_val = DB_getSettings('enpassword');
			$enpasswd = getAttrVal($prom_val->[0]);
			$prom_val = DB_getSettings('type access');
			my $access1 = getAttrVal($prom_val->[0]);
			$access = $access1 if defined($access1);
		}
		else	##if is special access to router then gets data to connect
		{
			my $arr_param = DB_getRouterAccess($r_id);
			
			foreach my $emp(@$arr_param)
			{
				$access =  $emp->[0] if defined($emp->[0]);
				if(defined($emp->[1]))
				{
					$type_router = $emp->[1];
					$type_router =~ s/\s+$//;
				}
					
				$flag = lc($emp->[2]);

				if($flag eq 'login')	#username
				{
					$user = decryptAttrvalue($criptokey,$emp->[3]);
					$user =~ s/\s+$//; 
				}
				if($flag eq 'password')	#password
				{
					$passwd = decryptAttrvalue($criptokey,$emp->[3]); 
					$passwd =~ s/\s+$//; 
					$enpasswd = decryptAttrvalue($criptokey,$emp->[3]);
					$enpasswd =~ s/\s+$//; 
				}
				if($flag eq 'enpassword')	#enable password
				{
					$enpasswd = decryptAttrvalue($criptokey,$emp->[3]);
					$enpasswd =~ s/\s+$//; 
				}

	##			case "port"

	##			case "pathphrase"
				if($flag eq 'path_to_key')	#path to key
				{
					$path_to_key = decryptAttrvalue($criptokey,$emp->[3]);
					$path_to_key =~ s/\s+$//; 
				}
					
				
			}
		}
		
		my $amount1 = DB_isCommunity($r_id);
			
				if($amount1 > 0)
				{
					my $arr_param1 = DB_getCommunity($r_id);
					foreach my $emp1(@$arr_param1)
					{
						$community = decryptAttrvalue($criptokey, $emp1->[0]) if defined($emp1->[0]);
						$community =~ s/\s+$//; 
					}						 	
				}
			    else
				{
					$prom_val = DB_getSettings('community');
					my $community1 = getAttrVal($prom_val->[0]) ;
					$community = $community1 if defined($community1);
				}				
		DB_close;
		if($access =~/SSH/i)
		{
			$access = 'SSH';
		}
		
########################
=for
print $host."\n";
print $user."\n";
print $passwd."\n";
print $enpasswd."\n";
print $access."\n";
print $community."\n";
=cut

# Get all configs from host
# Params:
#  host name or ip
#  user
#  passwd
#  enpasswd
#  config path
#  community
sub getConfigs {
  my $host = $_[0];
  my $user = $_[1];
  my $passwd = $_[2];
  my $enpasswd = $_[3];
  my $community = $_[5];
  my $access = $_[6];
  my $path_to_key = $_[7];
  my $passphrase = '';

  if( !defined ($test_host_type)) {
    my $er;
    ($hostType,$er) = getHostType($host, $community);
    if (!defined $hostType) {
      return $er;
    }
    $hostType ne "unknown" or return "$host: unrecognised host type";
  } else {
    $hostType = $test_host_type;
  }

  $hostType =~ s/\s+$//;
  print "$host: host type \"$hostType\"\n";

  if ($hostType eq "Cisco") {
    return &NGNMS_Cisco::cisco_get_configs;
  }
  if ($hostType eq "Juniper") {
	  
    return &NGNMS_JuniperJav::juniper_get_configs;
  }
  if($hostType eq "Linux" || $hostType =~/ubuntu/i)
  {
	  return &NGNMS_Linux::linux_get_configs;
  }
  if($hostType eq "Extreme")
  {
	  return &NGNMS_Extreme::extreme_get_configs;
  }
  if($hostType eq "HP")
  {
	  return &NGNMS_HP::hp_get_configs;
  }
  if($hostType eq "SSG5")
  {
	  return &NGNMS_SSG5::ssg5_get_configs;
  }
  return "host type ${hostType} not supported yet";
}
#########################################################
sub parseConfigs {
  my ($host, $configPath) = @_[0..1];
  my $ret = "ok";
  my $config_file;
  my $run_config_file;
 
  DB_setHostVendor($rt_id,$hostType);
  DB_setHostState($rt_id,"up");

  if ($hostType eq "Cisco") {
    my $version_file=$configPath."_version.txt";
    my $run_config_file=$configPath."_running_config.txt";
    my $interfaces_file=$configPath."_interfaces.txt";

    $ret = &NGNMS_Cisco::cisco_parse_version ($rt_id,$host,$version_file);
    ($ret eq "ok") and
      &NGNMS_Cisco::cisco_parse_run_config ($rt_id,$run_config_file);
    ($ret eq "ok") and
      &NGNMS_Cisco::cisco_parse_interfaces ($rt_id,$interfaces_file);
	  
	 if(defined($host) && defined($run_config_file))
	  {
		DB_addConfigFile($host,$run_config_file);
	  }	  
  }

  if ($hostType eq "Juniper") {
    my $version_file=$configPath."_version.txt";
    my $config_file=$configPath."_config.txt";
    my $interfaces_file=$configPath."_interfaces.txt";
    my $hardwr_file=$configPath."_hardware.txt";

    $ret =
      &NGNMS_JuniperJav::juniper_parse_version ($rt_id,$host,$version_file);
    ($ret eq "ok") and
      $ret = &NGNMS_JuniperJav::juniper_parse_config ($rt_id,$config_file);
    ($ret eq "ok") and
      $ret = &NGNMS_JuniperJav::juniper_parse_interfaces ($rt_id,$interfaces_file);
    ($ret eq "ok") and
      $ret = &NGNMS_JuniperJav::juniper_parse_hardwr ($rt_id,$hardwr_file);
	  
	  if(defined($host) && defined($config_file))
	  {
		DB_addConfigFile($host,$config_file);
	  }	
  }
  
  if($hostType eq "Linux")
	{
		
	}
  
  if($hostType eq "Extreme")
	{
		my $version_file=$configPath."_version.txt";
		my $hardwr_file=$configPath."_hardware.txt";
		$ret =
      &NGNMS_Extreme::extreme_parse_version ($rt_id,$host,$version_file);
##	  ($ret eq "ok") and
##      $ret = &NGNMS_Extreme::extreme_parse_hardwr ($rt_id,$hardwr_file);
	}
  if($hostType eq "HP")
	{
		my $version_file = $configPath."_version.txt";
		my $hardwr_file = $configPath."_hardware.txt";
		my $interfaces_file = $configPath."_interfaces.txt";
		my $config_file = $configPath."_config.txt";
		$ret =
      &NGNMS_HP::hp_parse_version ($rt_id,$host,$version_file);
	  ($ret eq "ok") and
      my $ret2 = &NGNMS_HP::hp_parse_hardwr ($rt_id,$hardwr_file);
	  ($ret2->{'ok'} eq "ok") and
      $ret = &NGNMS_HP::hp_parse_interfaces ($rt_id,$interfaces_file,$ret2->{'part_n'});
	  ($ret eq "ok") and
      $ret = &NGNMS_HP::hp_parse_config ($host,$config_file);
	}	
	if($hostType eq "SSG5")
	{
		my $version_file = $configPath."_version.txt";
		my $hardwr_file = $configPath."_hardware.txt";
		my $interfaces_file = $configPath."_interfaces.txt";
		my $config_file = $configPath."_config.txt";
		$ret =
      &NGNMS_SSG5::ssg5_parse_version ($rt_id,$host,$version_file);
	  ($ret eq "ok") and
      my $ret = &NGNMS_SSG5::ssg5_parse_hardwr ($rt_id,$hardwr_file);
	  ($ret eq "ok") and
      $ret = &NGNMS_SSG5::ssg5_parse_interfaces ($rt_id,$interfaces_file,$version_file);
	  ($ret eq "ok") and
      $ret = &NGNMS_SSG5::ssg5_parse_config ($host,$config_file);
	}	
	
  return $ret;
}
###########################################################
# make config path
# params: host name, router id
# returns: current config path prefix
sub makeConfigPath($$) {
  my $host = shift;
  my $rt_id = shift;
  my @lt = localtime;
  my $ts = sprintf("%04d%02d%02d-%02d%02d%02d",
		   $lt[5]+1900, $lt[4]+1, $lt[3], $lt[2], $lt[1], $lt[0]);
  my $datadir = "$ENV{'NGNMS_HOME'}/data/rtconfig/$rt_id";
  mkdir("$ENV{'NGNMS_HOME'}/data", 0755);
  mkdir("$ENV{'NGNMS_HOME'}/data/rtconfig", 0755);
  mkdir($datadir,0755);
  if( !open(F_HOST, ">$datadir/$host.dir")) {
    logError("poll","Failed to create $datadir/$host.dir");
    exit;
  }
  close (F_HOST);
  return "$datadir/$ts";
}
####################################################################
sub getLinuxConfig()
{
  my $host = $_[0];
  my $user = $_[1];
  my $passwd = $_[2];
  my $enpasswd = $_[3];
  my $community = $_[5];
  my $access = $_[6];
  my $path_to_key = $_[7];
  my $passphrase = '';
  ##my $cur_id = DB_getRouterId($host);
  ##my $cur_ipaddr = DB_getRouterIpAddr($cur_id);
  my $cur_ipaddr = $host;
  my $ocx_session = NGNMS_Linux->new($cur_ipaddr,$user,$passwd,$enpasswd,$access,$path_to_key,$passphrase);
  $ocx_session->open($cur_ipaddr,$user,$passwd,$enpasswd);
  $ocx_session->run_proccessing($cur_ipaddr);
  $ocx_session->close;
  return 'ok';
	}
###############################################################
DB_open($dbname,$dbuser,$dbpasswd,$dbport,$dbhost);

$rt_id = DB_getRouterId($host);
if( !defined($rt_id)) {
  DB_close;
  logError("poll","host \'$host\' not found in the database");
  exit;
};

my $ret;
if (!$noPoll) {
  
  $configPath = makeConfigPath($host,$rt_id);
  $ret = &getConfigs($host,$user,$passwd,$enpasswd,$configPath,$community,$access,$path_to_key);
  
  if ($ret ne "ok") {
    logError("poll","get configs from \'$host\': $ret");
    # get host ip addr and try to connect using it
    my $addr = DB_getRouterIpAddr($rt_id);
    $ret = &getConfigs($addr,$user,$passwd,$enpasswd,$configPath,$community,$access,$path_to_key);
  }
  
  if ($ret ne "ok") {
    DB_setHostState($rt_id,"down");
    DB_close;
    logError("poll","get configs from \'$host\': $ret");
    exit;
  }
  
} else {

    # get host type from test file or cmd line
  if ( !defined($test_host_type) ) {
    $configPath =~ /.*(Cisco|Juniper).*/;
    $test_host_type = $1;
  }
  $hostType = $test_host_type;
}


if( $hostType eq "Linux" || $hostType =~/ubuntu/i) 
{
	print "Type:$hostType-$host\n";
		$ret = &getLinuxConfig($host,$user,$passwd,$enpasswd,$configPath,$community,$access,$path_to_key);
	}
elsif( $hostType =~/ocx/i)	
{
	print "Type:$hostType\n";
	}
else
{
	$ret = &parseConfigs($host,$configPath);
	}	



	
DB_close;
$ret eq "ok" or
  logError("poll","parse configs from \'$host\': $ret");

print "Done\n";

__END__
