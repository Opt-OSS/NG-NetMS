package NGNMS_Extreme;

use strict;
use warnings;
use NGNMS_DB;
use NGNMS_util;
use Data::Dumper;
use File::Copy qw(copy);
use Data::Dumper;
use Net::Netmask;
use Net::Appliance::Session;
use Try::Tiny;
    
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
				  &extreme_create_session
				  &extreme_parse_version
			      &extreme_parse_hardwr
		          &extreme_parse_config		  
				  &extreme_parse_interfaces
				  &extreme_get_topologies
				  &extreme_get_configs);

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


sub extreme_create_session {
  my ($host, $username) = @_[0..1];
  my @passwds = @_[2..3];
  my $configPath = $_[4];
  my $access =@_[6..6];
  my $path_to_key =$_[7];

  
  print "Path : $configPath\n";
  my $version ='';
  
  $Error = undef;
  
  if(!defined($access))
  {
	$access = "Telnet";
  }
  
  my $file_vers = $configPath."_version.txt";
  my $interfaces_file = $configPath."_interfaces.txt";
  my $config_file = $configPath."_config.txt";
  $session = Net::Appliance::Session->new({
		personality => 'extremexos',
		transport => $access,
		timeout => 30,
		connect_options => { host => $host},
 });
$session->do_paging(0);
	try {
		# try to login to the ios device, ignoring host check
		$session->connect({ username => $username, password => $passwds[0] });
		$session->cmd("disable clipaging");
		return 1;
		}
	catch {
		warn "failed to execute command: $_";
		$Error = "Cannot connect to ".$host;
	}
}

sub extreme_get_file($$) {
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

sub extreme_write_to_file($$)
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


sub extreme_get_configs {
  my ($host, $username) = @_[0..1];
  my @passwds = @_[2..3];
  my $configPath = $_[4];
  my $acc = $_[6];
  my @output=();
  print "Getting configs from $host\n";
  my @params = ($_[0],$_[1],$_[2],$_[3],$_[4],'',$_[6]);

  extreme_create_session(@params);
  return $Error if $Error;

  # version
  #
  my $file_vers = $configPath."_version.txt";
  my $file_hard = $configPath."_hardware.txt";
  my $file_conf = $configPath."_config.txt";
  my $file_interf = $configPath."_interfaces.txt";
  
################
	
	try {
     print $session->cmd("disable clipaging");
		}
	catch {
		$session->close;
		$Error = "$host:failed to execute command: $_";
		return $Error;
	};
 
  extreme_get_file('sh ver detail', $file_vers) or
		return $Error; 
  @output = $session->cmd("sh switch");	
  extreme_write_to_file(\@output,$file_vers) or
 		return $Error; 	
  copy $file_vers,$file_hard or return $Error;
  
  extreme_get_file('sh ports information detail', $file_interf) or
		return $Error; 	
  @output = $session->cmd("sh ipconfig ipv4");	
  extreme_write_to_file(\@output,$file_interf) or
		return $Error; 	
  extreme_get_file('show configuration detail', $file_conf) or
		return $Error;
	 			
################  
  
  return "ok";
}

sub extreme_get_topologies ($$$$$) {

  return "ok";
}

#
# parse 'show version' output
#
# Params:
#  router_id
#  vers file

sub extreme_parse_version {

  my ($rt_id,$version_file) = @_[0..1];
  my @word;
  my $img_vers;
  my $softwr;
  my @arr_sw;
  open my $info, $version_file or
    return "error - version file $version_file: $!\n"; 

  DB_startSwInfo($rt_id);
  
  
  while( my $line = <$info>)  { 
	  $line =~ s/[\n]//g;  
      if($line =~ m/BootROM:\s(.*)    IMG:\s(.*)\s$/i)
		{
			$sw_info{'sw_item'} = 'Firmware';
           ( $sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( 'BootROM', $1 );
			DB_writeSwInfo($rt_id, \%sw_info);
			$sw_info{'sw_item'} = 'Firmware';
           ( $sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( 'IMG', $2 );
		    DB_writeSwInfo($rt_id, \%sw_info);
            
		}
		elsif($line =~ m/Image   :\s(.*) version\s(.*)$/i)
		{
			$img_vers = $2;
			@word = (split /\s/, $img_vers);
			$img_vers = $word[0];
			$sw_info{'sw_item'} = 'Firmware';
           ( $sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( $1, $img_vers );
			DB_writeSwInfo($rt_id, \%sw_info);
		}
		elsif($line =~ m/Diagnostics\s:\s(.*)$/i)
		{
			$sw_info{'sw_item'} = 'Firmware';
           ( $sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( 'Diagnostics', $1 );
			DB_writeSwInfo($rt_id, \%sw_info);

		}
	    elsif ($line =~ m/System Type:      (.*)$/i) { # Model of switch
			my $model_switch = $1;
	
			DB_writeHostModel($rt_id,$model_switch);
		}
		elsif($line =~ m/SysName:          (.*)$/i) { # Name of switch
			my $name_switch = $1;
			DB_replaceRouterName($rt_id,$name_switch);
		}
	}

  close $info;

  return "ok";

}


sub extreme_parse_hardwr {  
  my ($rt_id,$hardwr_file) = @_[0..1];
  my %ret_arr;
  my @arr_hw = ();
  my $serial_number;
  my $name_hw;
  my $hw_rev;
  my $switch_record_number;
  my $switch_record_desc;
  my $switch_record_info;
  $ret_arr{ok} ='ok';
  open my $info, $hardwr_file or
  return "error - hardware file $hardwr_file: $!\n";

  DB_startHwInfo($rt_id);
  
  while( my $line = <$info>)  {   
   $line =~ s/[\n]//g;
   if ($line =~ m/Switch      :\s(.*)\sRev/i) { # Name of switch
	   $switch_record_number = $1;
			}
		elsif($line =~ m/PSU-1       :\s(.*)$/i)
		{
			%hw_info = (	"hw_item" => 'PSU-1',
			"hw_name" => $1,
			"hw_ver"  =>'',
			"hw_amount" => '' );
			DB_writeHwInfo($rt_id, \%hw_info);
		}
		elsif($line =~ m/PSU-2       :\s(.*)$/i)
		{
			%hw_info = (	"hw_item" => 'PSU-1',
			"hw_name" => $1,
			"hw_ver"  =>'',
			"hw_amount" => '' );
			DB_writeHwInfo($rt_id, \%hw_info);
		}
		elsif($line =~ m/Switch        (.*)$/i)
		{
			my @t_arr0 = split(/:/,$1);
			my $ind0 = $#t_arr0;
			$switch_record_info = $t_arr0[$ind0];
		}
		elsif ($line =~ m/System Type:      (.*)$/i) { # Model of switch
			$switch_record_desc = $1;	
		}
 }
 
	if(defined $switch_record_desc || defined $switch_record_number || defined $switch_record_info){
	%hw_info = ("hw_item" => 'Switch',
				"hw_name" => $switch_record_desc,
				"hw_ver"  =>$switch_record_number,
				"hw_amount" => $switch_record_info );
				DB_writeHwInfo($rt_id, \%hw_info);
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

sub extreme_parse_config {

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

sub extreme_parse_interfaces {
  my ($rt_id,$ifc_file) = @_[0..1];
  my %speeds;
  my $cur_int ='';
  
  print "Parsing $ifc_file\n";

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
  my $speed = 'Unspecified';
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
  my $flag_switch = 0;
  my $flag_save = 0;
  my $phint_name = '';
  my $phDescr = '';
  
  
  $ifc{ 'ip address' } = '';
  
  while( my $line = <$info>)  {   
   $line =~ s/[\n]//g;

   if($line =~ m/Interface    IP Address          Flags                   nSIA/i)
   {
	   $flag_switch = 1;
   } 
	if($flag_switch)  #### logical interfaces
	{	
		if ($line =~ /\d+\.\d+\.\d+\.\d+/)
				{			
					@arr_interfaces = split(/ {2,}/, $line);					
					@arr_subarr =  split(/ {1,}/,$arr_interfaces[2]);
					my $mask1  = substr $arr_subarr[0], 1, 2;
					$block = new Net::Netmask ($arr_interfaces[1]."/".$mask1);
					
						if($arr_subarr[1] =~ /U/)
						{
							$newCond = 'up';
						}
						else
						{
							$newCond = 'down';
						}
						if($arr_subarr[1] =~ /E/)
						{
							$newState = 'enabled';
						}
						else
						{
							$newState = 'disabled';
						}	
						
						$logInterface = $arr_interfaces[0];
						push( @logInterfaceIp, $arr_interfaces[1]);
						@ifc{("interface","ip address","mask","description")} =($logInterface ,$arr_interfaces[1],$block->mask(),$newCond);
						$phInterface = $logInterface;						
							$speed = 'Unspecified';	
						@phifc{("interface","state","condition","speed","description")} =
			            ($phInterface,$newState,$newCond,$speed ,'');

						DB_writePhInterface($rt_id, \%phifc);
					    @old_ph_ifcs = grep {!/^$phifc{"interface"}$/} @old_ph_ifcs;
					    my $ph_int_id = DB_getPhInterfaceId($rt_id, $phInterface);
						DB_writeInterface( $rt_id, $ph_int_id, \%ifc );
						$count_logint++;
						@old_ifcs = grep {!/^$ifc{"interface"}$/} @old_ifcs;
					
				}
				
	}
	else ##physical interfaces
	{
		
		$line =~ s/[\n]//g;
		if($line =~ m/^port:\s(.*)$/i)
		{
			 $phint_name = "Port ".$1;
		}
		elsif($line =~ m/Admin state:\s(.*)$/i)
		{
			@arr_phint = split(/ {2,}/, $1);
			my($st, $garbige) = split(/ {1,}/, $arr_phint[0]);
			$newState = lc $st;
			if(defined $arr_phint[1])
			{
				if($arr_phint[1] =~ /(\d+)G/)
				{				
					$speed = $1*1000000000;
				}
			}	
		}
		elsif($line =~ m/Link State:\s(.*)$/i)
		{
			@arr_phint = split(/, /, $1);
			if($arr_phint[0] eq 'Active')
			{
				$newCond = 'up';
			}
			else
			{
				$newCond = 'down';
			}
			
			if(defined $arr_phint[1])		
			{
				if($arr_phint[1] =~ /(\d+)G/)
				{				
					$speed = $1*1000000000;
				}
			}
			$flag_save = 1;
		}
		elsif($line =~ m/Description String:\s(.*)$/i)
		{
			my $phDescr = $1;
		}
		if($flag_save)
		{
			@phifc{("interface","state","condition","speed","description")} =
				($phint_name,$newState,$newCond,$speed,$phDescr);
				print Dumper(%phifc);
				$phint_name = '';
				$phDescr = '';
				$speed = 'Unspecified';
				$flag_save = 0;
			DB_writePhInterface($rt_id, \%phifc);
			@old_ph_ifcs = grep {!/^$phifc{"interface"}$/} @old_ph_ifcs;
		}
		
	}	
    
	}
 
  if($count_logint < 2)
  {
	$ssg_layer = 2;
	DB_updateRouterId($rt_id,$logInterfaceIp[0]);
  }
  DB_setHostLayer($rt_id,$ssg_layer);
  DB_dropPhInterfaces($rt_id, \@old_ph_ifcs);
  DB_dropInterfaces($rt_id, \@old_ifcs);
  close $info;
  return "ok";
}

1;

__END__
