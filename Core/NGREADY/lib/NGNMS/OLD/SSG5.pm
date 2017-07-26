package NGNMS::OLD::SSG5;

use strict;
use warnings;
use NGNMS::OLD::DB;
use NGNMS::OLD::Util;
use NGNMS::Log4;
use Data::Dumper;
use File::Copy qw(copy);
use Data::Dumper;
use Net::Netmask;
use Net::Appliance::Session;
    
if (defined($ENV{"NGNMS_TIMEOUT"})) {
  $Net::Extreme::TIMEOUT = $ENV{"NGNMS_TIMEOUT"};
} else {
  $Net::Extreme::TIMEOUT = 60;
}

require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $data);

@ISA = qw(Exporter AutoLoader);

## set the version for version checking; uncomment to use
$VERSION     = 0.01;

@EXPORT      = qw(
				  &ssg5_create_session
				  &ssg5_parse_version
			      &ssg5_parse_hardwr
		          &ssg5_parse_config		  
				  &ssg5_parse_interfaces
				  &ssg5_get_topologies
				  &ssg5_get_configs);

# your exported package globals go here,
# as well as any optionally exported functions
@EXPORT_OK   = qw($data);

# print "loading NGNMS_Extreme\n";

# data

$data = "my data";
my @word;
my @rword;
# Preloaded methods

my $session;
my $Error;
my $model_device;
my $name_device;
my $location_switch;
my $log_interfaces;
my $ph_interfaces;
my $sys_info;
my $configuration;
my @swarray = ();
my @hwarray = ();	
my %sw_info = (	"sw_item" => undef,
		"sw_name" => undef,
		"sw_ver"  => undef );
my %hw_info = (	"hw_item" => undef,
		"hw_name" => undef,
		"hw_ver"  => undef,
		"hw_amount"  => undef );

my %ifc;


sub ssg5_create_session {
  my ($host, $username) = @_[0..1];
  my @passwds = @_[2..3];
  my $configPath = $_[4];
  my $access =@_[6..6];
  my $path_to_key =$_[7];

  
  ngnms_debug "Path : $configPath\n";
  my $version ='';
  
  $Error = undef;
  
  if(!defined($access))
  {
	$access = "SSH";
  }
    if ($access =~ /SSH/i)
    { #old pollhost behavior fix
        $access = 'SSH';
    }

    my $file_vers = $configPath."_version.txt";
  my $interfaces_file = $configPath."_interfaces.txt";
  my $config_file = $configPath."_config.txt";
  $session = Net::Appliance::Session->new({
		personality => 'junos',
		transport => $access,
		timeout => 30,
		connect_options => { host => $host},
 });
	try {
		# try to login to the ios device, ignoring host check
		$session->connect(username => $username, password => $passwds[0], SHKC => 0);
		return 1;
		}
	catch {
		warn $_;
		$Error = "Cannot connect to ".$host;
	}
}

sub ssg5_get_file($$) {
  my ($cmd, $fname) = @_[0..1];
  my @data; 
  $Error = undef;
  if (!open(F_DATA, ">$fname")) {
	 $session->_socket->close;
	 $Error = "Cannot open file $fname for writing: $!";
	 return undef;
	}
	
  @data = $session->cmd($cmd);
  
  for my $line (@data) {
		$line =~ s/[\n]//g;
		print F_DATA "$line\n";
	}

  close (F_DATA);
}

sub ssg5_write_to_file($$)
{
	my @data = @{$_[0]};
	my $fname = $_[1];
	
	if (!open(F_DATA, ">>$fname")) {

    $Error = "Cannot open file $fname for writing: $!";
    return undef;
	}
	
	for  my $line1 (@data) {
	        
				$line1 =~ s/^[\n]//g;
				print F_DATA $line1;			
	}
	close (F_DATA);
	1;	
}


sub ssg5_get_configs {
  my ($host, $username) = @_[0..1];
  my @passwds = @_[2..3];
  my $configPath = $_[4];
  my $acc = $_[6];
  my @output=();
  ngnms_log "Getting configs from $host";
  my @params = ($_[0],$_[1],$_[2],$_[3],$_[4],'',$_[6]);

  ssg5_create_session(@params);
  if($Error)
  {
	  my $rt_id = DB_getRouterId($_[0]);
	  my $ip_addr = DB_getRouterIpAddr($rt_id);
	  @params = ($ip_addr,$_[1],$_[2],$_[3],$_[4],'',$_[6]);
	  return $Error if $Error;
  }
 

  # version
  #
  my $file_vers = $configPath."_version.txt";
  my $file_hard = $configPath."_hardware.txt";
  my $file_conf = $configPath."_config.txt";
  my $file_interf = $configPath."_interfaces.txt";
  
################
  $session->cmd("set console page 0");
  ssg5_get_file('get system', $file_vers) or
		return $Error; 
  @output = $session->cmd("get hostname");	
  ssg5_write_to_file(\@output,$file_vers) or
 		return $Error; 	
  ssg5_get_file('get chassis', $file_hard) or
		return $Error; 	
  ssg5_get_file('get config', $file_conf) or
		return $Error; 			
  ssg5_get_file('get interface', $file_interf) or
		return $Error; 		
  @output = $session->cmd("get driver phy");	
  ssg5_write_to_file(\@output,$file_interf) or
		return $Error; 	
  $session->cmd("unset console page");
################  
  
  return "ok";
}

sub ssg5_get_topologies ($$$$$) {

  return "ok";
}

#
# parse 'show version' output
#
# Params:
#  router_id
#  vers file

sub ssg5_parse_version {

  my ($rt_id,$host,$version_file) = @_[0..2];
  my @word;
  my $img_vers;
  my $softwr;
  my @arr_sw;
  open my $info, $version_file or
    return "error - version file $version_file: $!\n"; 

  DB_startSwInfo($rt_id);
  
  
  while( my $line = <$info>)  {   
		$line =~ s/[\n]//g;
		 		
			if($line =~ m/^Software Version:\s(.*)$/i)
				{
					$softwr = $1;
					@arr_sw = split(",",$softwr);
					$sw_info{'sw_item'} = 'Software';
					$arr_sw[1] =~ s/Type:\s//g;
					$arr_sw[1] =~ s/^\s+//;
			        ($sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( $arr_sw[1], $arr_sw[0] );
					DB_writeSwInfo($rt_id, \%sw_info);
				}
				elsif($line =~ m/^Product Name:\s(.*)$/i)
				{
					$model_device = $1;
					DB_writeHostModel($rt_id,$model_device);
					
				}
				elsif($line =~ m/^Hostname:\s(.*)$/i)
				{
					$name_device	= $1;
					DB_replaceRouterName($rt_id,$name_device);
				}		
  }

  close $info;

  return "ok";

}


sub ssg5_parse_hardwr {  
  my ($rt_id,$hardwr_file) = @_[0..1];
  my %ret_arr;
  my @arr_hw = ();
  my $serial_number;
  my $name_hw;
  my $hw_rev;
  $ret_arr{ok} ='ok';
  open my $info, $hardwr_file or
  return "error - hardware file $hardwr_file: $!\n";

  DB_startHwInfo($rt_id);
  
  while( my $line = <$info>)  {   
   $line =~ s/[\n]//g;
   if($line !~ m/Slot/i)
   {
	  @arr_hw = split(/ {2,}/, $line);
	  $name_hw = $arr_hw[1];
	  $name_hw =~ s/\s+$//;
	  $serial_number = $arr_hw[2];
	  $serial_number =~ s/\s+$//;
	  $hw_rev = $arr_hw[3];
	  $hw_rev =~ s/\s+$//;
				  
	  %hw_info = (	"hw_item" => 'Chassis ',
					"hw_name" => $name_hw,
					"hw_ver"  => $serial_number,
					"hw_amount" => $hw_rev );
	DB_writeHwInfo($rt_id, \%hw_info);
	}		
 }

  close $info;
  return "ok";
}

#
# parse 'show running config' output
#
# Params:
#  router_id
#  run config file

sub ssg5_parse_config {

  my ($rt,$config_file) = @_[0..1];

  open(F_RCF,"<$config_file") or
    return "error - config file $config_file: $!\n";
  close(F_RCF);
  DB_addConfigFile($rt,$config_file) ;
  return "ok";
}



#
# Params:
#  router_id
#  interfaces file

sub ssg5_parse_interfaces {
  my ($rt_id,$ifc_file,$version_file) = @_[0..2];
  my %speeds;
  my $cur_int ='';
  ngnms_debug "Get speed for logical interface";
  open my $info0, $version_file or
    return "error - system file $version_file: $!\n";
     while( my $line0 = <$info0>)  {   
		$line0 =~ s/[\n]//g;
		if($line0 =~ m/^Interface\s(.*):/i)
		{
			$cur_int = $1;
		}
		elsif($line0 =~ m/physical\s(\d+)kbps/i)
		{
			$speeds{$cur_int} = $1;
		}
	}
  close $info0;  
  
  ngnms_debug "Parsing $ifc_file\n";

   open my $info, $ifc_file or
    return "error - interfaces file $ifc_file: $!\n";

  my @old_ifcs = @{DB_getInterfaces($rt_id)};
  my @old_ph_ifcs = @{DB_getPhInterfaces($rt_id)};

  my %phifc;
  my $ph_int_id = '';
  my $phint;
  my $phInterface = "";
  my $logInterface = "";
  my @logInterfaceIp = (); 
  my $protocol = "";
  my $speed;
  my $newInt;
  my $newState;
  my $newCond;
  my @arr_phint;
  my @arr_interfaces;
  my $block;
  my $ip_addr;
  my @arr_subarr;
  my $ssg_layer = 3;
  my $count_logint = 0;
  my $flag_switch = 1;
  $ifc{ 'ip address' } = '';
  while( my $line = <$info>)  {   
   $line =~ s/[\n]//g;
   if($line =~ m/port/i)
   {
	   $flag_switch = 0;
   } 
	if($flag_switch)  #### logical interfaces
	{
		if ($line =~ /\d+\.\d+\.\d+\.\d+\/\d/)
				{
					@arr_interfaces = split(/ {2,}/, $line);
					$block = new Net::Netmask ($arr_interfaces[1]);
					if($block->base() ne '0.0.0.0')
					{
						if($arr_interfaces[5] eq 'D')
						{
							$newCond = 'down';
						}
						else
						{
							$newCond = 'up';
						}
						@arr_subarr =  split("/",$arr_interfaces[1]);
						push( @logInterfaceIp, $arr_subarr[0]);
						$logInterface = $arr_interfaces[0];
						@ifc{("interface","ip address","mask","description")} =($logInterface ,$arr_subarr[0],$block->mask(),$newCond);
						$phInterface = $logInterface;
						
						if(defined $speeds{$phInterface})
						{
							$speed = $speeds{$phInterface}*1000;
						}
						else
						{
							$speed = 'Unspecified';
						}	
						@phifc{("interface","state","condition","speed","description")} =
			            ($phInterface,'enabled',$newCond,$speed ,'');
						DB_writePhInterface($rt_id, \%phifc);
					    @old_ph_ifcs = grep {!/^$phifc{"interface"}$/} @old_ph_ifcs;
					    my $ph_int_id = DB_getPhInterfaceId($rt_id, $phInterface);
						DB_writeInterface( $rt_id, $ph_int_id, \%ifc );
						$count_logint++;
						@old_ifcs = grep {!/^$ifc{"interface"}$/} @old_ifcs;
					}
				}
	}
	else ##physical interfaces
	{
		my $phint_name = '';
		$line =~ s/[\n]//g;

		if($line !~ m/port/i && $line !~ m/power/i && $line !~ m/----/i && $line !~ m/mii/i)
		{
			 @arr_phint = split(/ {1,}/, $line);
			 if($arr_phint[4] eq 'ena')
			 {
				 $newState = 'enabled';
			 }
			 else
			 {
				 $newState = 'disabled';
			 }
			 if($arr_phint[10] =~ m/(\d+)/)
			 {
				 $speed = $1*1000000;
			 }
			 else
			 {
				 $speed = 'Unspecified';
			 }
			 		 		 
			 $phint_name = "Port ".$arr_phint[1];
			 @phifc{("interface","state","condition","speed","description")} =
			 ($phint_name,$newState,$arr_phint[8],$speed,'');
			 DB_writePhInterface($rt_id, \%phifc);
			 @old_ph_ifcs = grep {!/^$phifc{"interface"}$/} @old_ph_ifcs;
		}
	}	
    
	}
 
  if($count_logint < 2)
  {
	$ssg_layer = 2;
	if(defined $logInterfaceIp[0]){
	DB_updateRouterId($rt_id,$logInterfaceIp[0]);
	}
  }
  
  DB_setHostLayer($rt_id,$ssg_layer);
  DB_dropPhInterfaces($rt_id, \@old_ph_ifcs);
  DB_dropInterfaces($rt_id, \@old_ifcs);
  close $info;
  return "ok";
}

1;
# ABSTRACT: This file is part of open source NG-NetMS tool.

__END__
