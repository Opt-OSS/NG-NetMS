#
# NextGen NMS
#
# NGNMS_Linux.pm: interfacing with Linux servers
#
# Copyright (C) 2002,2003 OptOSS LLC
# Copyright (C) 2014 Opt/Net BV
#
# Author: T.Matselyukh, A. Jaropud
#

package NGNMS_Linux;

use strict;


use Net::Telnet;
use Net::OpenSSH;
use Data::Dumper;
use NGNMS_DB;
use NGNMS_util;
use JSON::Parse 'json_file_to_perl';

my $module_version='0.0.1';
##print "using NGNMS_Linux.pm, version $module_version\n";



require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $data);

@ISA = qw(Exporter AutoLoader);

## set the version for version checking; uncomment to use
$VERSION     = 0.0.1;

@EXPORT      = qw(
		  &linux_parse_version
		  &linux_parse_config
		  &linux_parse_interfaces
		  &linux_get_topologies
		  &linux_get_configs
	       );

# your exported package globals go here,
# as well as any optionally exported functions
@EXPORT_OK   = qw($data);

# print "loading NGNMS_Juniper\n";

# data

$data = "my data";

# Preloaded methods

my $session;
my $Error;
my $username = "ngnms";
my $password = "Rfhfv,jkM27";
my $timeout  = 10;
my $cmd2			= 'ls /tmp/mc-ngnms'; 
my $debug = 0;
my $src_folder_name = '/tmp/mc-ngnms';
my $dst_folder_name = '/var/www/ngnms_perl/test';



sub host		{
					if($_[0]->_access eq 'Telnet')
					{
						$_[0]->opened ? $_[0]->_socket->host : undef
					}
					else
					{
						$_[0]->_socket->host 
					}
				}
sub logged_in		{ $_[0]->{'logged_in'} }
sub _access	   { $_[0]->{'t_access'} }
sub _socket		{ $_[0]->{'socket'} }

sub opened		{
					 if($_[0]->_access eq 'Telnet')
					 { $_[0]->_socket && $_[0]->_socket->opened }
					 else { 1 }
				 }
sub errmsg		{ $_[0]->{'error'} }

sub new{
    my $type = shift;
    my $host = shift;
	my $username =shift;
	my $password =shift;
	my $enpassword=shift;
	my $access = shift;
	my $path_to_key=shift;
	my $passphrase = shift;
	my $model;
	

    $Error = '';
	if($access eq 'Telnet')
	{
	 	$model =  new Net::Telnet(errmode => 'return',host=>$host,Timeout => 10);
##		$model->login($username, $passwds[0]) or return warn "$host: ",$model->errmsg,"\n";
	}
	else
	{
		if(defined($path_to_key) && $path_to_key ne "" )
		{
			$model = Net::OpenSSH->new(
			$host,
			user =>$username,
			passphrase => $passphrase,
			key_path   => $path_to_key,
			timeout     => $timeout,
			master_opts => [ -o => "StrictHostKeyChecking=no" ]
			);
		}
		else
		{
			$model =  Net::OpenSSH->new($host,
											user => $username, 
											password => $password,
											timeout     => $timeout,
											master_opts => [ -o => "StrictHostKeyChecking=no" ]);
		}
		
		$model->error and   warn "Unable to connect to remote host: " . $model->error;
##		$model->error and die "Unable to connect to remote host: " . $model->error;
											
	}
	
    my $self = {
	'socket'	=> $model,
	'logged_in'	=> 0,
	'prompt'	=> '',
	'error'		=> '',
	'last_command'	=> '',
	't_access' => $access
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

	$debug = 0 if !defined($debug);
	 
    print  "connecting to $host\n" if $debug > 0;
    if($self->_access eq 'Telnet')
	{
	$self->_socket->open($host);
	$self->_socket->login($username,$passwords[0]) or return $self->_set_error($self->_socket->errmsg);
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
	if (defined($self->_socket))
	{
     if($self->_access eq 'Telnet')
		{
			if ($self->opened) {
				$self->_socket->cmd(String=>'quit', Timeout=>2) if $self->logged_in;
				$self->_socket->close;
				$$self{'logged_in'} = 0;
##				$self->prompt('');
			  }
		}
		else
		{
			$self->_socket->system("exit");
			$$self{'logged_in'} = 0;
		}
	}
	
    return $self;
}
sub linux_create_session {
  my ($host, $username) = @_[0..1];
  my @passwds = @_[2..3];
  my $access = $_[4];
  my $path_to_key = "/home/ngnms/.ssh/id_rsa" ;
  my $passphrase = "colonel";
  $Error = undef;
  if($access eq "Telnet")
  {
	  $session = new Net::Telnet ($host);
      $session->errmode('return');
 #     $session->errmode('die');
      $session->login($username, $passwds[0]) or return warn "$host: ",$session->errmsg,"\n";
  }
  else
  {
	$session = Net::OpenSSH->new(
    $host,
    passphrase => $passphrase,
    key_path   => $path_to_key,
    timeout     => $timeout,
    master_opts => [ -o => "StrictHostKeyChecking=no" ]
);
	$session->error and die "Unable to connect to remote host: " . $session->error;
	  }
  


}

sub linux_get_topologies ($$$$$) {
	
    
    return "ok";
}

sub linux_get_configs()
{
	return 'ok';
}
sub linux_parse_config
{
	my $isis_file = shift;
	use JSON::Parse 'json_file_to_perl';
    my $p = json_file_to_perl ($isis_file);
    
    proccessing_servers($p->{response}->{ocxServers});
    proccessing_clients($p->{response}->{ocxClients});
    processing_providers($p->{response}->{providers});
    return "ok";
	}
	
sub proccessing_servers()
{
	my $servers = shift;
	my $k;
	my $l;
	my $i1;
	my $i;
	my $j = 0;
	my @f_con;
	my @s_con;
	my %con_a;
	my @amount;
	my $rt_id;
	my $linkT= "P";
	my $server_connections;
	
	foreach my $k (keys $servers)
    {
		$rt_id = DB_getRouterId($servers->{$k}->{name});
		if (!defined($rt_id)) {
			$rt_id = DB_addRouter($servers->{$k}->{name}, '0.0.0.0', "up");
			DB_setHostVendor($rt_id,'OCX');
		}
		else {
				DB_dropLinks($rt_id);
			}			
		$con_a{$servers->{$k}->{name}} =  $rt_id;	
		$server_connections = $servers->{$k}->{connectedTo};
		for $i ( 0 .. $#{ $server_connections } ) 
						{
							    $f_con[$j] = $servers->{$k}->{name};
							    $s_con[$j] = $server_connections->[$i];
							    $amount[$j] = 0;
								$j++;		
														
						}
    }	
 
	for($l=0;$l<$j-1;$l++)	
    {
		for($i1=$l+1;$i1<$j;$i1++)
		{
			if(($s_con[$i1] eq $f_con[$l]) && ($s_con[$l] eq $f_con[$i1]))
			{
				$amount[$i1]++;
			}
		}
	}
	for($l=0;$l<$j;$l++)	
    {
		if($amount[$l] <1)
		{
			DB_writeLink($con_a{$f_con[$l]},$con_a{$s_con[$l]},$linkT);
		}
		
	}													
}

sub proccessing_clients()
{
	my $level_new;
	my $clients = shift;
	my $rt_id ;
	my $rt_id_vm ;
	my $router_addr;
	my $linkT= "P";
	my $status ;

	foreach my $k (keys $clients)
    {
		undef $router_addr;
		$level_new = $clients->{$k}->{instances}[0];
		
			if ($level_new->{address} =~ /\d+\.\d+\.\d+\.\d+/)
				{
					$router_addr = $level_new->{address};
				}
			else
				{
					$router_addr = $level_new->{id};
				}
			
			if(defined($router_addr))
				{
					$rt_id_vm = DB_getRouterId($router_addr);
					$rt_id = DB_getRouterId($clients->{$k}{ocxServer});
					if (!defined($rt_id_vm)) {	
						if($level_new->{status} =~ m/^RUNNING/i)
					   {	
						   $status = "up";		
						}	
						else
						{
							$status = "down";
						}		
						$rt_id_vm = DB_addRouter($level_new->{id}, $level_new->{address}, $status);
						DB_setHostVendor($rt_id_vm,$level_new->{role});
					}
					else {
					DB_dropLinks($rt_id_vm);
					}
					DB_writeLink($rt_id,$rt_id_vm,$linkT);
				}											
		
	}
}

sub processing_providers()
{
	my $providers = shift;
	my $level2;
	my $k1;
	my $k2;
    my $i;
    my $j;
    my $rt_id ;
	my $rt_id_vm ;
	my $rt_id_cl;
	my $router_addr;
	my $linkT= "P";
	my $status ;
	
	foreach my $k (keys $providers)
    {
		print "$k:$providers->{$k}->{ocxServer}\n" ;## cloud provider
		$rt_id = DB_getRouterId($providers->{$k}->{ocxServer});
		$rt_id_cl = DB_getRouterId($k);
		
		if (!defined($rt_id_cl)) {						
						$rt_id_cl = DB_addRouter($k, '0.0.0.0', "up");
						DB_setHostVendor($rt_id_cl,'CloudProvider');
					}
					else {
					DB_dropLinks($rt_id_cl);
					}
					
		DB_writeLink($rt_id,$rt_id_cl,$linkT);					
		$level2 = $providers->{$k}->{instances};	
				
	    for $j ( 0 .. $#{ $level2} ) 
		{						
			undef $rt_id_vm;
														
				if ($level2->[$j]->{address} =~ /\d+\.\d+\.\d+\.\d+/)
				{
					$router_addr = $level2->[$j]->{address};
				}
				elsif ($level2->[$j]->{networks}->{private}[0] =~ /\d+\.\d+\.\d+\.\d+/)
				{
					$router_addr = $level2->[$j]->{networks}->{private}[0];
				}
				
				if(defined($router_addr))
				{
					$rt_id_vm = DB_getRouterId($router_addr);
					if (!defined($rt_id_vm)) {
						if($level2->[$j]->{status} =~ m/^RUNNING/i)
						{
							$status = 'up';	
						}
						else
						{
							$status = "down";
						}
						$rt_id_vm = DB_addRouter($level2->[$j]->{id}, $router_addr, $status);
						DB_setHostVendor($rt_id_vm,'Linux');
					}
					else {
						DB_dropLinks($rt_id_vm);
					}
				}
				print "$rt_id_cl:$rt_id_vm\n";
				DB_writeLink($rt_id_cl,$rt_id_vm,$linkT);
				
				if(defined ($level2->[$j]->{networks}))
				{					 
					foreach $k2(keys $level2->[$j]->{networks})
					{		
						for $i ( 0 .. $#{ $level2->[$j]->{networks}->{$k2} } ) 
						{
							if( $level2->[$j]->{networks}->{$k2}[$i] =~ /\d+\.\d+\.\d+\.\d+/ ) 
							{
##								print " $i = $level2->[$j]->{networks}->{$k2}[$i]";
							}							
						}
##							print "\n";								 
					}				
				}																		
		}
	}	
}

sub linux_get_topologies_old ($$$$$) {
  my ($host, $username) = @_[0..1];
  my @passwds = @_[2..3];
  my $access = $_[4];
  my $p = json_file_to_perl ('ocx.json');
    my $k1;
    my $k2;
    my $level2;
    my $arr;
    my $rt_id;
    my $rt_id_vm;
    my $router_addr ;
    my $i;
    my $linkT= "P";

    foreach my $k (keys $p)
    {
		undef $rt_id;
		undef $router_addr ;
		print Dumper($k);## cloud provider
		$rt_id = DB_getRouterId($k);
		if (!defined($rt_id)) {
			$rt_id = DB_addRouter($k, '0.0.0.0', "up");
			DB_setHostVendor($rt_id,'CloudProvider');
		}
			else {
			DB_dropLinks($rt_id);
		}
		$level2 = $p->{$k};
		foreach  $k1(keys $level2)
		{
			undef $rt_id_vm;
			if($level2->{$k1}->{status} =~ m/^RUNNING/i)
			{								
				print $k1."\n";
				if ($level2->{$k1}->{address} =~ /\d+\.\d+\.\d+\.\d+/)
				{
					$router_addr = $level2->{$k1}->{address};
				}
				elsif ($level2->{$k1}->{networks}->{private}[0] =~ /\d+\.\d+\.\d+\.\d+/)
				{
					$router_addr = $level2->{$k1}->{networks}->{private}[0];
				}
				if(defined($router_addr))
				{
					$rt_id_vm = DB_getRouterId($router_addr);
					if (!defined($rt_id_vm)) {
						$rt_id_vm = DB_addRouter($k1, $router_addr, "up");
						DB_setHostVendor($rt_id_vm,'Linux');
					}
					else {
					DB_dropLinks($rt_id_vm);
					}
				}
				DB_writeLink($rt_id,$rt_id_vm,$linkT);
				if(defined ($level2->{$k1}->{networks}))
				{					 
					foreach $k2(keys $level2->{$k1}->{networks})
					{		
						for $i ( 0 .. $#{ $level2->{$k1}->{networks}->{$k2} } ) 
						{
							if( $level2->{$k1}->{networks}->{$k2}[$i] =~ /\d+\.\d+\.\d+\.\d+/ ) 
							{
								print " $i = $level2->{$k1}->{networks}->{$k2}[$i]";
							}							
						}
							print "\n";								 
					}				
				}	
			}		
		}
	}
	
  return "ok";
}

sub run_proccessing_alone
{
	my $self = shift;
	my $new_rid;
	my $linux_compname = $self->linux_parse_name();
	$new_rid  = DB_getRouterId($linux_compname);
					if (!defined($new_rid)) {
						$new_rid = DB_addRouter($linux_compname,$self->_socket->{_host},'unknown');		
						DB_setHostVendor($new_rid,'Linux');					
					}
	return $new_rid;
					
	}

sub run_proccessing
{
    my $self = shift;
	my $cur_ip = shift;
##    print Dumper($self);
    my $iface;
    my $line; 
    my %phifc;
    my %ifc;
    my $speede;
    my $new_rid;
	my $linux_layer = 5;
    my %sw_info = (	"sw_item" => undef,
		"sw_name" => undef,
		"sw_ver"  => undef );

    my %hw_info = (	"hw_item" => undef,
		"hw_name" => undef,
		"hw_ver"  => undef,
		"hw_amount"  => undef );
    my $ph_int_id;
    my (%ip6, %ip, %scope6, %bcast, %mask, %hwaddr, %ipcount,%condition);
    my $iface_count = 0;
    my $linux_vendor = $self->linux_parse_vendor();
	if(!defined $linux_vendor || $linux_vendor eq '')
	{
		$linux_vendor = 'Linux';
	}
	my $linux_softwr = $self->linux_parse_version();
	my $linux_compname = $self->linux_parse_name();
	if(!defined $linux_compname || $linux_compname eq '')
	{
		$linux_compname = $cur_ip;
	}
	my $linux_hardwr =  $self->linux_parse_hardwr();
	print "$linux_softwr:$linux_compname:$linux_hardwr\n";
	$new_rid  = DB_getRouterId($linux_compname);
	if(!defined($new_rid))
	{
		$new_rid  = DB_getRouterId($cur_ip);
	}
					if (!defined($new_rid)) {
						$new_rid = DB_addRouter($linux_compname,$cur_ip,'up');						
					}
					else
					{
						DB_replaceRouterName($new_rid,$linux_compname);
						DB_setHostState($new_rid,'up');
						}
	DB_setHostVendor($new_rid,$linux_vendor);				
	DB_setHostLayer($new_rid,$linux_layer);
	%hw_info = (	"hw_item" => "processor",
			"hw_name" => "$linux_hardwr",
			"hw_ver"  => "",
			"hw_amount" => "" );
	DB_startHwInfo($new_rid);
	DB_writeHwInfo($new_rid, \%hw_info);	

	%sw_info = (	"sw_item" => 'Operating system',
		"sw_name" => $linux_vendor,
		"sw_ver"  => $linux_softwr);
	DB_startSwInfo($new_rid);
    DB_writeSwInfo($new_rid, \%sw_info);
					
	my @linux_interfaces = $self->linux_parse_intefaces();
=for	
	foreach(@linux_interfaces)
  {
	print $_;
}
=cut	
	foreach(@linux_interfaces)
  {
	$line = $_;
##	print "interface:".$line."\n";
	if ($line =~ m/^([a-z0-9:]+)\s+.*?([a-z0-9:]+)\s*$/i) { # Linux interface
		$iface	= $1;
		my $iface_hwaddr = $2;
		$iface	= [ $iface =~ m/^([a-z0-9]+)/i ]->[0]; # convert "eth0:0" --> "eth0"
		$ipcount{$iface}++;
		$hwaddr{$iface} = $iface_hwaddr;
		$condition{$iface} = 'down';
		$iface_count++;
	}
	elsif ($line =~ m/^[ \t]+inet addr:/) { # Linux IP address
		die unless defined $iface;
		my @fields = split(/[\s:]+/, $line);
		push @{$ip{$iface}}, $fields[3];
		$bcast{$iface} = $fields[5]	|| ""; # invalid for loopback interface lo, but we don t need this
		$mask{$iface} = $fields[7]	|| $fields[5]; # for loopback interface lo
	}
	elsif($line =~ m/^[ \t]+inet6 addr:/) { # Linux IPv6 address
		die unless defined $iface;
		my @fields = split(/\s+/, $line);
		push @{$ip6{$iface}}, $fields[3];
		$scope6{$iface} = [ $fields[4] =~ m/Scope:(.*)$/i ]->[0];
	}
	elsif($line =~ m/^[ \t]+UP BROADCAST/) { # Up/Down
		die unless defined $iface;
		my @fields = split(/\s+/, $line);
		
		if($fields[3] =~ m/RUNNING/i )
		{
			$condition{$iface} = "up";
		}
		
	}
	

  }

foreach my $k1(keys %hwaddr)
{
	$speede = $self->linux_parse_speed_interface($k1);
	
	if(defined($speede))
	{
		$speede =~ s/\s+$//;
	}
	else
	{
		$speede = 'Unspecified';
	}
	
	@phifc{("interface","state","condition","speed","description")} =
	($k1,'enabled',$condition{$k1},$speede,$hwaddr{$k1});
	DB_writePhInterface($new_rid, \%phifc);
}  
  
 foreach my $k (keys %ip){
	if($ip{$k}->[0] ne '127.0.0.1')
		{
			 $ph_int_id = DB_getPhInterfaceId($new_rid,$k);
			 @ifc{("interface","ip address","mask","description")} =
				($k,$ip{$k}->[0],'255.255.255.255','');
			 DB_writeInterface( $new_rid, $ph_int_id, \%ifc );
		}	
	}
}

sub linux_parse_vendor {

  my $self = shift;
  my @lines  = $self->linux_cmd('uname -v') ;
  
  return parse_res($lines[0],1);
}

sub linux_parse_version {

  my $self = shift;
  my @lines  = $self->linux_cmd('uname -r') ;
  
  return parse_res($lines[0],0);
}

sub linux_parse_name
{
  my $self = shift;
  my @lines  = $self->linux_cmd('uname -n') ;
   
  return parse_res($lines[0],0);
}

sub linux_parse_hardwr {


  my $self = shift;
  my @lines  = $self->linux_cmd('uname -m') ;
  
  return parse_res($lines[0],0);
}

sub linux_parse_speed_interface {
	my $self = shift;
	my $interface_name =shift;
	my $ret_val;
	my $cmd1 = 'ethtool '.$interface_name." | awk '/Speed/ {sub(/:/,".'"",'.'$2);print $2}'."'";
	my @lines = $self->linux_cmd($cmd1) ;
	
	return $lines[0];
	}
	
sub parse_res()
{
  my $val = shift;
  my $first_s = shift;
  my $retval;
  if(defined $val && $val ne '' )
  {
	$val =~ s/^\s+//;			# no leading white
	$val =~ s/\s+$//;			# no trailing white
	my @arr_val = split(/ /,$val);
	$retval = substr $arr_val[0],$first_s;
  }
  else
  {
	$retval ='';
  }
  
  return $retval;
}
sub linux_parse_intefaces()
{
	my $self = shift;
 
 #  my @lines  = $self->linux_cmd('/sbin/ifconfig -a | sed -n '."'".'s/^\([^ ]\+\)'.'.'.'*/"\1"/p'."'".' | paste -sd ","'."'") ;                                
	my @lines  = $self->linux_cmd('/sbin/ifconfig -a');
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

sub linux_parse_interfaces {

  return "ok";
}

sub linux_cmd()
{
	$session = shift;
	my $cmd = shift;
 
	if($session->_access eq 'Telnet')
	{
		return $session->_socket->cmd($cmd);
	}
	else
	{
		return eval{$session->_socket->capture($cmd)}; 
	}
}

# END { print "deleting NGNMS_Linux\n" };



1;

__END__
