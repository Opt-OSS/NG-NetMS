package NGNMS_HP;

use strict;

# use Data::Dumper;
use NGNMS_DB;
use NGNMS_util;
use Data::Dumper;
use File::Copy qw(copy);
use Net::HPProcurve qw($Error $debug $TIMEOUT);


# $Net::Juniper::debug=1;

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
				  &hp_create_session
				  &hp_parse_version
			      &hp_parse_hardwr
		          &hp_parse_config		  
				  &hp_parse_interfaces
				  &hp_get_topologies
				  &hp_get_configs);

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
my $model_switch;
my $name_switch;
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
# Firmware versions that don't have the "Press any key" prompt.
my %nopress = (
    "K.14.47" => 1,
    "W.14.49" => 1,
);
my %MODEL_MAP = (
    'J8131A' => 'WAP-420-WW',
    'J8130A' => 'WAP-420-NA',
    'J8133A' => 'AP520WL',
    'J8680A' => '9408sl',
    'J9091A' => '8212zl',
    'J9475A' => '8206zl',
    'J9265A' => '6600ml-24XG',
    'J9264A' => '6600ml-24G-4XG',
    'J9263A' => '6600ml-24G',
    'J9452A' => '6600-48G-4XG',
    'J9451A' => '6600-48G',
    'J8474A' => '6410cl-6XG',
    'J8433A' => '6400cl-6XG',
    'J8992A' => '6200yl-24G',
    'J4902A' => '6108',
    'J8698A' => '5412zl',
    'J8719A' => '5408yl',
    'J8697A' => '5406zl',
    'J8718A' => '5404yl',
    'J4819A' => '5308XL',
    'J4850A' => '5304XL',
    'J8773A' => '4208vl',
    'J8770A' => '4204vl',
    'J8772A' => '4202vl-72',
    'J9032A' => '4202vl-68G',
    'J9031A' => '4202vl-68',
    'J8771A' => '4202vl-48G',
    'J4865A' => '4108GL',
    'J4887A' => '4104GL',
    'J9588A' => '3800-48G-PoE+-4XG',
    'J9574A' => '3800-48G-PoE+-4SFP+',
    'J9586A' => '3800-48G-4XG',
    'J9576A' => '3800-48G-4SFP+',
    'J9584A' => '3800-24SFP-2SFP+',
    'J9587A' => '3800-24G-PoE+-2XG',
    'J9573A' => '3800-24G-PoE+-2SFP+',
    'J9585A' => '3800-24G-2XG',
    'J9575A' => '3800-24G-2SFP+',
    'J8693A' => '3500yl-48G-PWR',
    'J8692A' => '3500yl-24G-PWR',
    'J9473A' => '3500-48-PoE',
    'J9472A' => '3500-48',
    'J9471A' => '3500-24-PoE',
    'J9470A' => '3500-24',
    'J4906A' => '3400cl-48G',
    'J4905A' => '3400cl-24G',
    'J4815A' => '3324XL',
    'J4851A' => '3124',
    'J9562A' => '2915-8G-PoE',
    'J9148A' => '2910al-48G-PoE+',
    'J9147A' => '2910al-48G',
    'J9146A' => '2910al-24G-PoE+',
    'J9145A' => '2910al-24G',
    'J9050A' => '2900-48G',
    'J9049A' => '2900-24G',
    'J4904A' => '2848',
    'J4903A' => '2824',
    'J9022A' => '2810-48G',
    'J9021A' => '2810-24G',
    'J8165A' => '2650-PWR',
    'J4899B' => '2650-CR',
    'J4899C' => '2650C',
    'J4899A' => '2650',
    'J8164A' => '2626-PWR',
    'J4900B' => '2626-CR',
    'J4900C' => '2626C',
    'J4900A' => '2626',
    'J9627A' => '2620-48-PoE+',
    'J9626A' => '2620-48',
    'J9624A' => '2620-24-PPoE+',
    'J9625A' => '2620-24-PoE+',
    'J9623A' => '2620-24',
    'J9565A' => '2615-8-PoE',
    'J9089A' => '2610-48-PWR',
    'J9088A' => '2610-48',
    'J9087A' => '2610-24-PWR',
    'J9086A' => '2610-24/12PWR',
    'J9085A' => '2610-24',
    'J8762A' => '2600-8-PWR',
    'J4813A' => '2524',
    'J9298A' => '2520G-8-PoE',
    'J9299A' => '2520G-24-PoE',
    'J9137A' => '2520-8-PoE',
    'J9138A' => '2520-24-PoE',
    'J4812A' => '2512',
    'J9280A' => '2510G-48',
    'J9279A' => '2510G-24',
    'J9020A' => '2510-48A',
    'J9019B' => '2510-24B',
    'J9019A' => '2510-24A',
    'J4818A' => '2324',
    'J4817A' => '2312',
    'J9449A' => '1810G-8',
    'J9450A' => '1810G-24',
    'J9029A' => '1800-8G',
    'J9028A' => '1800-24G',
	'J0000A' => 'unknown'
 );
 
 my %SPEED_MAP =(
	'J9279A' => 48000000,
	'J9280A' => 96000000,
	'J9020A' => 17600000,
	'J0000A' => 'unknown'
			);


sub hp_create_session {
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

  
  $session = Net::HPProcurve->new($access,$configPath,$host, $username, @passwds,$path_to_key);
  
  
  if(defined($session->logged_in))
  {
		my $file_vers = $configPath."_version.txt";
		my $interfaces_file = $configPath."_interfaces.txt";
		my $config_file = $configPath."_config.txt";
		if (!open(F_DATA, ">$file_vers")) {
			$session->_socket->close;
			$Error = "Cannot open file $file_vers for writing: $!";
			return undef;
		}
		

        if($access eq "Telnet")
		{
			my ($prematch, $match) = $session->_socket->waitfor(Match => '/ProCurve.*?Switch.*\n/', Errmode=>'return', Timeout => 4);
			
			if($match)
			{
				print F_DATA "$match\n";
			}
			
			($prematch, $match) = $session->_socket->waitfor(Match => '/(Firmware|Software) revision.*\n/', Errmode=>'return');
			if($match)
			{
				print F_DATA "$match\n";
			}
			
			close (F_DATA);
			
			$match =~ m/(Software|Firmware) revision (.*)/i;
			$version = $2 || "";
			$version =~ s/[\r\n]//g;
		}
		else
		{
		    my $str =$session->_model();
		    print F_DATA "$str\n";	
			my $strversion = $session->_strver();
			 print F_DATA "$strversion\n";	
			 close (F_DATA);
			$version = $session->_version(); 
			$log_interfaces = $session->_logint();
			$ph_interfaces = $session->_phint();
			$sys_info = $session->_sysinfo();
			$configuration = $session->_config();
			
		}	
		# Some versions of the firmware don't have this prompt.
		
        if($access eq "Telnet")
		{
			if (!$nopress{$version}) 
			{
			$session->_socket->waitfor(Match => '/Press any key to continue/',Errmode=>'return');
			$session->_socket->print("");
			}
			$session->_socket->waitfor('/Password: /');
		    $session->_socket->print($passwds[0]);
			$session->_socket->waitfor(Match => '/> /',Errmode=>'return');
		}		
		
		if (!open(F_DATA1, ">$interfaces_file")) {
		    if($access eq "Telnet"){$session->_socket->close;}		
			$Error = "Cannot open file $interfaces_file for writing: $!";
			return undef;
		}
		my $titlef = 'Interfaces:';
		print F_DATA1 "$titlef\n";
		close (F_DATA1);
		
		if (!open(F_DATA2, ">$config_file")) {
			if($access eq "Telnet"){$session->_socket->close;}		
			$Error = "Cannot open file $config_file for writing: $!";
			return undef;
		}
		$titlef = '';
		print F_DATA2 $titlef;
		close (F_DATA2);
	}
	else
	{
		$session->_set_error("Conection with $host via $access was not established")
	}	

  if($session->{'error'}) {
    $Error = $session->errmsg;
  }
  else {  
    my $MB = 1024 * 1024;
  } 
}


sub hp_get_file($$$) {
  my ($cmd, $fname,$stop) = @_[0..2];
  my @data; 
  $Error = undef;
 
  my $cl = '/'.$stop.'/';
 
   $session->_socket->print($cmd) ;  
  my ($prematch, $match) = $session->_socket->waitfor(Match => $cl,Errmode=>'return' );

  if (! $prematch) {
    $session->_socket->close;
    $Error = "HP: " . $session->_socket->errmsg();
	print STDERR $Error."\n";
    return undef;
  }

  if (!open(F_DATA, ">>$fname")) {
    $session->_socket->close;
    $Error = "Cannot open file $fname for writing: $!";
    return undef;
  }
  
  @data = split(/\r/,$prematch);
      print STDERR @data;
  for my $line (@data) {
	print F_DATA "$line\n";
	}
##  print F_DATA @data;
  close (F_DATA);

  1;
}

sub hp_write_to_file($$)
{
	my @data = @{$_[0]};
	my $fname = $_[1];
	my @data1=();
	
	if (!open(F_DATA, ">>$fname")) {
    $session->_socket->close;
    $Error = "Cannot open file $fname for writing: $!";
    return undef;
	}
	for my $line (@data) {
		@data1 =  split(/\n/,$line);
	}
	my $i = 0;
	for  my $line1 (@data1) {
	        if($i > 0 && $i < $#data1 )
			{
				$line1 =~ s/^[\n]//g;
				print F_DATA "$line1\n";
			}			
		$i++;
	}
	close (F_DATA);
	1;
	
}

sub  hp_ssh_write_to_file($$)
{
	my @data = @{$_[0]};
	my $fname = $_[1];
	
	if (!open(F_DATA, ">>$fname")) {

    $Error = "Cannot open file $fname for writing: $!";
    return undef;
	}
	
	for  my $line1 (@data) {
	        
				$line1 =~ s/^[\n]//g;
				print F_DATA "$line1\n";			
	}
	close (F_DATA);
	1;
}

sub hp_get_configs {
  my ($host, $username) = @_[0..1];
  my @passwds = @_[2..3];
  my $configPath = $_[4];
  my $acc = $_[6];
  my @output;
  print "Getting configs from $host\n";
  my @params = ($_[0],$_[1],$_[2],$_[3],$_[4],'',$_[6]);

  hp_create_session(@params);
  return $Error if $Error;

  # version
  #
  my $file_vers = $configPath."_version.txt";
  my $file_hard = $configPath."_hardware.txt";
  my $file_conf = $configPath."_config.txt";
  my $file_interf = $configPath."_interfaces.txt";
  if($acc eq 'Telnet')
  {
		hp_get_file('show system-information', $configPath."_version.txt",'IP Mgmt') or
		return $Error; 

	  # hardware inventory
	  #

		copy $file_vers,$file_hard or return $Error;
		

	  # Running config
	  #
		$session->_socket->print(" enable");
		$session->_socket->waitfor(Match => '/Password: /' , Errmode=>'return',);
		$session->_socket->print($passwds[1]);
		my ($ok) = $session->_socket->waitfor(Match => '/# /', Errmode=>'return', Timeout => 4);
		if($ok)
		{
			print "Enable Mode\n";
			$session->_socket->print(' terminal length 1000');
			$session->_socket->waitfor(Match => '/# /', Errmode=>'return');
			$session->_socket->print(" show config");
			my ($prematch, $match) = $session->_socket->waitfor( Match => '/# /', Errmode=>'return' );
			my @in_arr  = split(/\r/,$prematch);
			my $j;
			my $i;
			my $sdvig = 1;
			my $first_el = $sdvig;
			for( $i=$first_el; $i < $#in_arr; $i++)
			{
			   $j = $i-$sdvig;
			   $in_arr[$i] =~ s/[\n]//g;
				chomp($in_arr[$i]);
			   if($in_arr[$i] =~/^\s*$/)
			   {
					$sdvig++;
			   }
			   else
			   {
					$output[$j] =  $in_arr[$i];
			   }
			}
			@output = grep{$_} @output;

			hp_ssh_write_to_file(\@output,$file_conf) or
			return $Error;
			$session->_socket->print(" show ip");
			($prematch, $match) = $session->_socket->waitfor( Match => '/# /', Errmode=>'return' );
			@output = split(/\r\n/,$prematch);
			hp_write_to_file(\@output,$file_interf) or
			return $Error;
			$session->_socket->print(" show interfaces brief");
			($prematch, $match) = $session->_socket->waitfor( Match => '/# /', Errmode=>'return' );
			@output = split(/\r\n/,$prematch);
			hp_write_to_file(\@output,$file_interf) or
			return $Error;
		}	
		else
		{
			$session->_socket->print(' show ip');
			my ($prematch, $match) = $session->_socket->waitfor( '/> /' );
			hp_get_file(' show ip', $configPath."_interfaces.txt",'> ') or
			return $Error;
			$session->_socket->print(' show interfaces brief');
			($prematch, $match) = $session->_socket->waitfor( '/> /' );
			hp_get_file(' show interfaces brief', $configPath."_interfaces.txt",'> ') or
			return $Error;
		}
	  

	  # Interfaces
	  #
	  
	  $session->_socket->close;
  }
  else
  {
	if(defined $sys_info)
	{
		 @output = split(/~~~~/,$sys_info);
			hp_ssh_write_to_file(\@output,$file_vers) or
			return $Error;
	}
	
	copy $file_vers,$file_hard or return $Error;
	if(defined $configuration)
	{
		 @output = split("~~~~",$configuration);
			hp_ssh_write_to_file(\@output,$file_conf) or
			return $Error;
	}
	if(defined $log_interfaces)
	{
		 @output = split("~~~~",$log_interfaces);
			hp_ssh_write_to_file(\@output,$file_interf) or
			return $Error;
	}
	if(defined $ph_interfaces)
	{
		 @output = split("~~~~",$ph_interfaces);
			hp_ssh_write_to_file(\@output,$file_interf) or
			return $Error;
	}
  }
  

  return "ok";
}

sub hp_get_topologies ($$$$$) {

  return "ok";
}

#
# parse 'show version' output
#
# Params:
#  router_id
#  vers file

sub hp_parse_version {

  my ($rt_id,$host,$version_file) = @_[0..2];
  my @word;
  my $img_vers;
  open my $info, $version_file or
    return "error - version file $version_file: $!\n";

  

  DB_startSwInfo($rt_id);
  
  
  while( my $line = <$info>)  {   
   $line =~ s/[\n]//g;
		    if($line =~ m/^ProCurve\s(.*)$/i) {
				my $model = $1;
				$model =~ s/\s*J\d+[AB]\s*//i;
				$model =~ s/\s*Switch\s*//i;
				DB_writeHostModel($rt_id,$model);
			}
			elsif ($line =~ m/ System Name        :\s(.*)$/i) { # Name of switch
				$name_switch	= $1;
				DB_replaceRouterName($rt_id,$name_switch);
				}
			elsif($line =~ m/ System Location    :\s(.*)$/i){ #Location of switch
				$location_switch = $1;
				$location_switch =~ s/\s+$//;
				DB_writeHostLocation($rt_id, $location_switch);
			}	
			elsif($line =~ m/  ROM Version        :\s(.*)$/i){
				my $rom_vers = $1;
				@word = ($rom_vers =~ /(\w+)/g);
				@word = (split /\s/, $rom_vers)[0];
				$rom_vers = $word[0];
				$sw_info{'sw_item'} = 'Firmware';
			   ( $sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( 'ROM', $rom_vers );
			   DB_writeSwInfo($rt_id, \%sw_info);
			}
			elsif($line =~ m/(Software|Firmware) revision  :\s(.*)          Base MAC Addr/i){
				my $version = $2 || "";
				$version =~ s/[\r\n]//g;
				$sw_info{'sw_item'} = 'Software';
				($sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( 'Revision', $version );
				DB_writeSwInfo($rt_id, \%sw_info);
			}
			
  }

  close $info;

  return "ok";

}


sub hp_parse_hardwr {
    
  my ($rt_id,$hardwr_file) = @_[0..1];
  my %ret_arr;
  $ret_arr{ok} ='ok';
    open my $info, $hardwr_file or
    return "error - hardware file $hardwr_file: $!\n";


DB_startHwInfo($rt_id);
  while( my $line = <$info>)  {   
   $line =~ s/[\n]//g;

			if ($line =~ m/ Serial Number      :\s(.*)$/i) { # Serial number of switch
				my $serial_number	= $1;
				$serial_number =~ s/\s+$//;
				%hw_info = (	"hw_item" => 'Chassis ',
				"hw_name" => '',
				"hw_ver"  => $serial_number,
				"hw_amount" => '' );
				DB_writeHwInfo($rt_id, \%hw_info);
			}
			elsif($line =~ m/^ProCurve\s(.*)$/i){
				my $part_n =  $1;
				@word = ($part_n =~ /(\w+)/g);
				$part_n = $word[0];
				if(defined $part_n){
					$ret_arr{'part_n'} = $part_n;
				}
				else
				{
					$ret_arr{part_n} = 'J0000A';
				}
				%hw_info = (	"hw_item" => 'Part number',
						"hw_name" => '',
						"hw_ver"  => $part_n,
						"hw_amount" => '' );
					DB_writeHwInfo($rt_id, \%hw_info);
			}
  }

  close $info;
  return \%ret_arr;
}

#
# parse 'show running config' output
#
# Params:
#  router_id
#  run config file

sub hp_parse_config {

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

sub hp_parse_interfaces {
  my ($rt_id,$ifc_file,$part_n) = @_[0..2];
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
  my $speed;
  my $newInt;
  my $newState;
  my $newCond;
  my $hp_layer = 2;
  $ifc{ 'ip address' } = '';
  my $counter = 0 ;
  my $count_logint =0 ;
  
  while( my $line1 = <$info>)  {   
   $line1 =~ s/[\n]//g; 
   
   $counter++;
#####################
	if($line1 =~ / Internet (IP) Service/)
	{
		$counter = 0;
	}
	if ($counter >= 8 && $line1 =~ /\d+\.\d+\.\d+\.\d+\s+\d+\.\d+\.\d+\.\d+/)
		{
			$phint = $line1;
			$phint =~ s/^\s+//;
			$phint =~ s/\s+$//;
			@word = split(/\s/, $phint);
			$logInterface = $word[0];
			$phInterface = $logInterface;
			@ifc{("interface","ip address","mask","description")} =
			($logInterface,$word[7],$word[10],'');
			@phifc{("interface","state","condition","speed","description")} =
			($phInterface,'enabled','up',$SPEED_MAP{$part_n},'');
			if ($phInterface ne "") {
					DB_writePhInterface($rt_id, \%phifc);
					@old_ph_ifcs = grep {!/^$phifc{"interface"}$/} @old_ph_ifcs;
					  } else {
					$phInterface = $logInterface;
					for ($phInterface) {  s/\.\d+$//; }
					  }
					  if ($ifc{ 'ip address' } ne '' && $ifc{"ip address"} ne '127.0.0.1') {
					push( @logInterfaceIp, $ifc{"ip address"});	  
					my $ph_int_id = DB_getPhInterfaceId($rt_id, $phInterface);
					DB_writeInterface( $rt_id, $ph_int_id, \%ifc );
					$count_logint++;
					@old_ifcs = grep {!/^$ifc{"interface"}$/} @old_ifcs;
					  }
		}
	
	if ($line1 =~ /\d{1,2}\s/ && $line1 =~ /100/) { 
			@word = ($line1 =~ /(\w+)/g);
			@rword = reverse(@word);
			if ($rword[3] =~ /(\d+)(FDx|HDx)/) {
			$speed = $1;
			};
			$newInt = $rword[9];
			$newState = $rword[5];
			$newCond = $rword[4];
			$newState = 'enabled' if $newState =~ /Yes/;
			$newState = 'disabled' if $newState =~ /No/;
			$newCond = 'up' if $newCond =~ /Up/;
			$newCond = 'down' if $newCond =~ /Down/;
			$phInterface = "Port ".$newInt;
			@phifc{("interface","state","condition","speed","description")} =
	       ($phInterface,$newState,$newCond,$speed,'');
			if ($phInterface ne "") {
				DB_writePhInterface($rt_id, \%phifc);
				@old_ph_ifcs = grep {!/^$phifc{"interface"}$/} @old_ph_ifcs;
			  } 
			}
			
#####################   
 }
  if($count_logint > 1)
  {
	$hp_layer = 3;
  }
  else
  {
	  DB_updateRouterId($rt_id,$logInterfaceIp[0]);
	}
  DB_setHostLayer($rt_id,$hp_layer);
  DB_dropPhInterfaces($rt_id, \@old_ph_ifcs);
  DB_dropInterfaces($rt_id, \@old_ifcs);
  close $info;
  return "ok";
}

1;

__END__
