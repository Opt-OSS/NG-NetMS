#!/usr/bin/perl -w
#
# Download configuration files from remote host via ssh
#
# 
#
# Usage: scaricare.pl options 
#
# Options:
#  -S        source folder(remote host)
#  -D        destination folder(local host)
#  -i        remote host 
#  -d        print debugging info to screen
#  -U 		 User 
#  -W		 passWord	
#  -P        Port (default 22)
#  -k        path to key
#  -f        passphrase
#
# Example: scaricare -S /tmp/mc-ngnms/ -D /tmp/ - i test1.opt.net.eu - U ngnms -W 123344 -P 822
#
# Environment:
#
#
# Copyright (C) 2014 Opt/Net
#
# Author: A.Iaropud
#
use strict;
use warnings;
use NGNMS_DB;
use Net::OpenSSH;
use Data::Dumper;
use DBI;

my $hostname = "";
my $username = "";
my $password = "";
my $port = 22;
my $timeout  = 60;
my $cmd		= 'ls '; 
my $file;
my $file1;
my $src_folder_name = '';
my $dst_folder_name = '';
my $path_to_key = '';
my $passphrase = '';
my @flag =(0,0,0,0,0,0,0)  ;
my $type_access = 0;
my $verbose = 0;
my $opts;

my $DB_host = "localhost"; 
my $DB_name = 'ngnms';
my $DB_user= 'ngnms';
my $DB_passwd = 'optoss';
my $DB_port = '5432';
my $script_name = "$ENV{'NGNMS_HOME'}/bin/audit.pl";

#####################################################################
# Parse command line
#

while (($#ARGV >= 0) && ($ARGV[0] =~ /^-.*/)) {
 
  if ($ARGV[0] eq "-S") {
    shift @ARGV;
    $src_folder_name = $ARGV[0] if defined($ARGV[0]);
    shift @ARGV;
	$flag[0] = 1; 
    next;
  }
  if ($ARGV[0] eq "-D") {
    shift @ARGV;
    $dst_folder_name = $ARGV[0] if defined($ARGV[0]);
    shift @ARGV;
    $flag[1] = 1; 
    next;
  }
  if ($ARGV[0] eq "-d") {
    $verbose = 1;
  }
  
  if ($ARGV[0] eq "-i") {
    shift @ARGV;
    $hostname = $ARGV[0] if defined($ARGV[0]);
	shift @ARGV;
	$flag[2] = 1; 
    next;
  }
  
  if ($ARGV[0] eq "-U") {
	shift @ARGV;
    $username = $ARGV[0] if defined($ARGV[0]);
	shift @ARGV;
	$flag[3] = 1; 
    next;
  }
  
  if ($ARGV[0] eq "-W") {
    shift @ARGV;
    $password = $ARGV[0] if defined($ARGV[0]);
	shift @ARGV;
	$flag[4] = 1; 
    next;
  }
  
  if ($ARGV[0] eq "-P") {
    shift @ARGV;
    $port = $ARGV[0] if defined($ARGV[0]);
	shift @ARGV;
    next;
  }
  
  if ($ARGV[0] eq "-k") {
	shift @ARGV;
    $path_to_key = $ARGV[0] if defined($ARGV[0]);
	shift @ARGV;
	$flag[5] = 1; 
    next;
  }
  
  if ($ARGV[0] eq "-f") {
    shift @ARGV;
    $passphrase = $ARGV[0] if defined($ARGV[0]);
	shift @ARGV;
	$flag[6] = 1; 
    next;
  }
  if ($ARGV[0] eq "-h") {
    print <<EOF ;
Usage: scaricare.pl options

 Options:
  -S        source folder(remote host)
  -D        destination folder(local host)
  -i        remote host 
  -d        print debugging info to screen
  -U 	    User 
  -W        passWord	
  -P        Port (default 22)
  -k        path to key
  -f        passphrase


EOF
    exit;
  }
  shift @ARGV;
}

#####################################################################
if($flag[3]>0 && $flag[4]>0)
{
	$type_access = 1;
	}
elsif($flag[5]>0)
{
	$type_access = 2;
	}
		
if($flag[0] < 1 || $flag[1] < 1 || $flag[2] < 1 || $type_access < 1)
{
	print <<EOF ;
Usage: scaricare.pl options

 Options:
  -S        source folder(remote host)
  -D        destination folder(local host)
  -i        remote host 
  -d        print debugging info to screen
  -U		User 
  -W        passWord	
  -P   		Port (default 22)
  -k        path to key
  -f        passphrase


EOF
exit;
	}
	
# Open connection via ssh
	
if($type_access == 1)
{
	$opts = {
		user => $username, 
		password => $password,
		port => $port,
		timeout     => $timeout,
		master_opts => [ -o => "StrictHostKeyChecking=no" ]
	};
	
	
}
elsif($type_access == 2)
{
	$opts = {
		passphrase => $passphrase,
		key_path   => $path_to_key,
		port => $port,
		timeout     => $timeout,
		master_opts => [ -o => "StrictHostKeyChecking=no" ]
	}

}

my $ssh = Net::OpenSSH->new(
		$hostname,
		%$opts
	);	
$ssh->error and die "Unable to connect to remote host: " . $ssh->error;

if($verbose > 0)
{
	  $Net::OpenSSH::debug = ~0;
	}

# Download files from remote server	
$cmd .=  $src_folder_name;
my @lines = eval { $ssh->capture($cmd) };
foreach (@lines) {
    print $_;
    $file = $src_folder_name.$_;
    $file1 = $dst_folder_name.$_;
    $file =~ s/^\s+|\s+$//g;
    $file =~ s/\h+/ /g;
    $file1 =~ s/^\s+|\s+$//g;
    $file1 =~ s/\h+/ /g;
    $ssh->scp_get(  $file, $file1);
};

# close connection
$ssh->system("exit");

# Run proccwsing files
scan_dir();

###########################################
# Scan dir and run proccesing conf ig files
###########################################
sub scan_dir
{
	my $vendor = '';
# Stable part of command line for files proccesing	
	my $cmd ="perl ".$script_name." -np -D ".$DB_name." -U ".$DB_user." -W ".$DB_passwd;
# Command line  for files proccesing
    my $cmd1 = "";
# Open directory	
	opendir (DIR,$dst_folder_name);
    
	while ($file = readdir DIR) {
      next if $file eq '.' || $file eq '..';
      
      $file1=$dst_folder_name.$file;
      
      if (-f $file1) { ## if it is file
			my @values = split('_', $file); ##parse file name 
            $vendor = getVendor($values[0]); ## get router type
            if (defined($vendor))
            {
				$cmd1 = $cmd. " -f ". $values[0]." -t ".$vendor; ## create command line to run proccessing
print $cmd1."\n";
				system($cmd1); ## run command line
			} 
		}
# TODO : add recursive proccess		
#	 if (-d $file1) {
#			print "This is a directory: " . $file;
#		}
    }

# Close dir
closedir(DIR);
}

###################################
# Get router type
###################################
sub getVendor($){
	my $router_name=$_[0]; ## get router name
	my $dbh;
## open connection to DB    
   DB_open($DB_name,$DB_user,$DB_passwd,$DB_port);
   my $vendor = DB_getRouterVendor($router_name);
   DB_close;  
	
	if (defined($vendor)){
## cut head and tail space		
	$vendor =~ s/^\s+|\s+$//g;
    $vendor  =~ s/\h+/ /g;
    return $vendor;
	}
	return undef;
		

	}
	
