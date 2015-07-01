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
use Net::IPv4Addr;

my $module_version='0.0.1';
##print "using NGNMS_Linux.pm, version $module_version\n";



require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $data);

@ISA = qw(Exporter AutoLoader);

## set the version for version checking; uncomment to use
$VERSION     = 0.0.1;

use constant NR_DEFAULT_ROUTE4 => '0.0.0.0/0';
use constant NR_DEFAULT_ROUTE6 => '::/0';
use constant NR_LOCAL_ROUTE4 => '0.0.0.0';
use constant NR_LOCAL_ROUTE6 => '::';


our %EXPORT_TAGS = (
   constants => [qw(
      NR_DEFAULT_ROUTE4
      NR_DEFAULT_ROUTE6
      NR_LOCAL_ROUTE4
      NR_LOCAL_ROUTE6
   )],
);


@EXPORT      = qw(
		  &linux_parse_version
		  &linux_parse_config
		  &linux_parse_interfaces
		  &linux_get_topologies
		  &linux_get_configs
	       );

# your exported package globals go here,
# as well as any optionally exported functions
@EXPORT_OK   = qw($data @{$EXPORT_TAGS{constants}});

# data

$data = "my data";

# Preloaded methods

my $session;
my $Error;
my $username ;
my $password ;
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
		
			$model =  Net::OpenSSH->new($host,
											user => $username, 
											password => $password,
											timeout     => $timeout,
											master_opts => [ -o => "StrictHostKeyChecking=no" ]);
		
		$model->error and   warn "Unable to connect to remote host: ".$host.": "  . $model->error;
##		$model->error and die "Unable to connect to remote host ".$host.": " . $model->error;
											
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
  my $password =$_[2];
	my $enpassword=$_[3];
  my $access = $_[4];
  
  $Error = undef;
  if($access eq "Telnet")
  {
	  $session = new Net::Telnet (Errmode=>'return',Host => $host) ;
##      $session->errmode('return');
      if (defined($session)){
       $session->login($username, $password)  ;
	}
  }
  else
  {
	$session =  Net::OpenSSH->new($host,
											user => $username, 
											password => $password,
											timeout     => $timeout,
											master_opts => [ -o => "StrictHostKeyChecking=no" ]);
##	$session->error and die "Unable to connect to remote host: " . $session->error;
	  }
  
    return $session;

}

sub linux_get_topologies ($$$$$) {
	my ($host, $username, $password, $enablepw, $access) = @_[0..4];
	my @nets;
    my $sess = linux_create_session($host, $username, $password, $enablepw, $access);
    if(!defined($sess) ){
		return "Unable to connect to remote host: $host\n";
		}
    if($access eq 'Telnet'){
		if($sess->errmsg){
			print "$host: ",$sess->errmsg,"\n";
			return  "$host: ",$sess->errmsg,"\n";
			}
		} else {
				if($sess->error) {
				return "Unable to connect to remote host: " . $sess->error;
			}
		}
    
	if($access eq 'Telnet'){
			@nets = $sess->cmd("netstat -rn");
			if($sess->errmsg){
				return  "remote netstat command failed: ",$sess->errmsg,"\n"
			}
		} else {
			@nets = $sess->capture("netstat -rn");
			if($sess->error) {
				return "remote netstat command failed: " . $sess->error;
			}
		}
    
	
    if($access eq 'Telnet'){
			$sess->cmd("exit");
		} else {
			$sess->system("exit");
		}
    my @routes = ();
    my %cache = ();
    my %host_ips;
	my %links;
	my $state = '';
	my $DR = '';


   for my $line (@nets) {
      my @toks = split(/\s+/, $line);
      my $route = $toks[0];
      my $gateway = $toks[1];
      my $netmask = $toks[2];
      my $flags = $toks[3];
      my $mss = $toks[4];
      my $window = $toks[5];
      my $irtt = $toks[6];
      my $interface = $toks[7];

      if (defined($route) && defined($gateway) && defined($interface)
      &&  defined($netmask)) {
         # A first sanity check to help Net::IPv4Addr
         if ($route !~ /^[0-9\.]+$/ || $gateway !~ /^[0-9\.]+$/
         ||  $netmask !~ /^[0-9\.]+$/) {
            next;
         }

         eval {
            my ($ip1, $cidr1) = Net::IPv4Addr::ipv4_parse($route);
            my ($ip2, $cidr2) = Net::IPv4Addr::ipv4_parse($gateway);
            my ($ip3, $cidr3) = Net::IPv4Addr::ipv4_parse($netmask);
         };
         if ($@) {
            #chomp($@);
            #print "*** DEBUG[$@]\n";
            next; # Not a valid line for us.
         }

         # Ok, proceed.
         my %route = (
            route => $route,
            gateway => $gateway,
            interface => $interface,
         );

         # Default route
         if ($route eq '0.0.0.0' && $netmask eq '0.0.0.0') {
            $route{default} = 1;
            $route{route} = NR_DEFAULT_ROUTE4();
         }
         else {
            my ($ip, $cidr) = Net::IPv4Addr::ipv4_parse("$route / $netmask");
            $route{route} = "$ip/$cidr";
         }

         # Local subnet
         if ($gateway eq '0.0.0.0') {
            $route{local} = 1;
            $route{gateway} = NR_LOCAL_ROUTE4();
         }

         my $id = _to_psv(\%route);
         if (! exists($cache{$id})) {
            push @routes, \%route;
            $cache{$id}++;
         }
      }
   }

 
	DB_addHostNoWrite( \%host_ips, $host);
    DB_addHostIP( \%host_ips, $host, $host); 
   
for my $route(@routes) {
	if($route->{default}){
		my $ip = $route->{gateway};
		$DR=$ip;
		DB_addHostNoWrite( \%host_ips, $DR);
		DB_addHostIP( \%host_ips, $DR, $ip);
		DB_addLinkNoWrite( \%links, $host, $DR, "B" );
		}
	}
	
	DB_writeTopology( \%host_ips, \%links );   
	DB_setHostVendorByIP($host, 'Linux');

    return "ok";
}

sub _to_psv {
   my ($route) = @_;

   my $psv = $route->{route}.'|'.$route->{gateway}.'|'.$route->{interface}.'|'.
      (exists($route->{default})?'1':'0').'|'.(exists($route->{local})?'1':'0');

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
    my $iface;
    my $line; 
    my %phifc;
    my %ifc;
    my $speede;
    my $new_rid;
    my $control_ip;
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
    
	if(!defined $linux_vendor || $linux_vendor eq '' || $linux_vendor !~/ubuntu/i)
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
	$new_rid  = DB_getRouterId($linux_compname);
	
	if(!defined($new_rid))
	{
		$new_rid  = DB_getRouterId($cur_ip);
	}
	else
	{
		$control_ip = DB_getRouterIpAddr($new_rid);
		if($control_ip ne $cur_ip)
		{
			$new_rid  = DB_getRouterId($cur_ip);
		}
	}
	
	if (!defined($new_rid)) {
		$new_rid = DB_addRouter($linux_compname,$cur_ip,'up');						
	}
	else
	{
		DB_replaceRouterName($new_rid,$linux_compname);
		DB_setHostState($new_rid,'up');
		if($cur_ip eq '0.0.0.0' && $linux_compname =~ /\d+\.\d+\.\d+\.\d+/)
		{
			DB_updateRouterId($new_rid,$linux_compname);
		}						
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

	foreach(@linux_interfaces)
  {
	$line = $_;
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
		if($speede =~ m/^Cannot/){
			$speede = 'Unspecified';
			}
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
				($k,$ip{$k}->[0],$mask{$k},'');
			 DB_writeInterface( $new_rid, $ph_int_id, \%ifc );
			 if($k eq 'eth0')
			 {
				 DB_updateRouterId($new_rid,$ip{$k}->[0]);
			 }
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
