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
# Preloaded methods

my $session;
my $Error;
my $model_switch;
my $name_switch;
my $location_switch;
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



sub hp_create_session {
  my ($host, $username) = @_[0..1];
  my @passwds = @_[2..3];
  my $access =@_[6..6];
  my $path_to_key =$_[7];

  $Error = undef;
  if(!defined($access))
  {
	$access = "Telnet";
  }

  
  $session = Net::HPProcurve->new($access,$host, $username, @passwds,$path_to_key);
  if(defined($session->_socket))
  {
		my ($prematch, $match) = $session->_socket->waitfor('/ProCurve.*?Switch.*\n/');
		my $model = $match;
		my $part_n = $match;
	    $part_n =~ s/ProCurve //i;
		@word = ($part_n =~ /(\w+)/g);
		$part_n = $word[0];
		%hw_info = (	"hw_item" => 'Part number',
			"hw_name" => '',
			"hw_ver"  => $part_n,
			"hw_amount" => '' );
	    push(@hwarray,%hw_info);
		$model =~ s/[\r\n]//g;
		$model =~ s/ProCurve //i;
		$model =~ s/\s*J\d+[AB]\s*//i;
		$model =~ s/\s*Switch\s*//i;
		$model_switch = $model;
		
		($prematch, $match) = 
        $session->_socket->waitfor('/(Firmware|Software) revision.*\n/');
		$match =~ m/(Software|Firmware) revision (.*)/i;
		my $version = $2 || "";
		$version =~ s/[\r\n]//g;
		print $version."\n";
		$sw_info{'sw_item'} = 'Software';
		($sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( 'Revision', $version );
		push(@swarray,%sw_info);
		# Some versions of the firmware don't have this prompt.
		if (!$nopress{$version}) {
        $session->_socket->waitfor('/Press any key to continue/');
        $session->_socket->print("");
		}
		$session->_socket->waitfor('/Password: /');
		$session->_socket->print($passwds[0]);
		$session->_socket->waitfor('/> /');
=for		
		$session->_socket->print("show system-information");
		($prematch, $match) = $session->_socket->waitfor( '/IP Mgmt/' );
		my @output = split(/\r/,$prematch);
		foreach my $line(@output)
		{
			$line =~ s/[\n]//g;
			if ($line =~ m/ System Name        :\s(.*)$/i) { # Name of switch
				$name_switch	= $1;
				}
			elsif($line =~ m/ System Location    :\s(.*)$/i){ #Location of switch
				$location_switch = $1;
				$location_switch =~ s/\s+$//;
			}	
			elsif($line =~ m/  ROM Version        :\s(.*)$/i){
				my $rom_vers = $1;
				@word = ($rom_vers =~ /(\w+)/g);
				@word = (split /\s/, $rom_vers)[0];
				$rom_vers = $word[0];
				$sw_info{'sw_item'} = 'Firmware';
			   ( $sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( 'ROM', $rom_vers );
			   push(@swarray,%sw_info);
			}
			if ($line =~ m/ Serial Number      :\s(.*)$/i) { # Serial number of switch
				my $serial_number	= $1;
				$serial_number =~ s/\s+$//;
				%hw_info = (	"hw_item" => 'Chassis ',
				"hw_name" => '',
				"hw_ver"  => $serial_number,
				"hw_amount" => '' );
				push(@hwarray,%hw_info);
			}		
		}
=cut		
	}
	else
	{
		$session->_set_error("Conection with $host via $access was not established")
	}	

print Dumper(@swarray);
print Dumper(@hwarray);

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
  
   $session->_socket->print($cmd);
  my ($prematch, $match) = $session->_socket->waitfor( '/'.$stop.'/' );

  if (! $prematch) {
##    $session->close;
    $Error = "HP: " . $session->errmsg();
    return undef;
  }
	 
  if (!open(F_DATA, ">$fname")) {
    $session->close;
    $Error = "Cannot open file $fname for writing: $!";
    return undef;
  }
  @data = split(/\r/,$prematch);
#      print @data;
  for my $line (@data) {
	print F_DATA "$line\n";
	}
##  print F_DATA @data;
  close (F_DATA);
  1;
}

sub hp_get_model($){
my $cmd =$_[0];
 
my $tm =5;
			
  $session->_socket->print($cmd);
  my ($prematch, $match) = $session->_socket->waitfor( '/> /' );
  my @data = split(/\n/,$prematch);
  if (! @data) {
    $session->close;
    $Error = "extreme: " . $session->errmsg();
    return undef;
  }
# print "model Extreme:\n";
#  print Dumper(@data);
# print "end model Extreme:\n"; 
  return @data;
}

sub hp_get_configs {
  my ($host, $username) = @_[0..1];
  my @passwds = @_[2..3];
  my $configPath = $_[4];
  my $acc = $_[6];
  print "Getting configs from $host\n";
  my @params = ($_[0],$_[1],$_[2],$_[3],'','',$_[6]);
##  juniper_create_session(@_);
  hp_create_session(@params);
  return $Error if $Error;

  # version
  #
  my $file_vers = $configPath."_version.txt";
  my $file_hard = $configPath."_hardware.txt";

  hp_get_file('show system-information', $configPath."_version.txt",'IP Mgmt') or
    return $Error;

  # hardware inventory
  #
#  extreme_get_file('show chass hardw', $configPath."_hardware.txt") or
#    return $Error;
	copy $file_vers,$file_hard or return $Error;

  # Running config
  #
#  extreme_get_file('show config', $configPath."_config.txt") or
#    return $Error;

  # Interfaces
  #
#  extreme_get_file('show interface extensive', $configPath."_interfaces.txt") or
#    return $Error;

#  $session->close;

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
  
  if (defined $model_switch) {
      DB_writeHostModel($rt_id,$model_switch);
    }
=for	
	if (defined $name_switch) {
	print "bbb: name\n";
		DB_replaceRouterName($rt_id,$name_switch);
    } 
=cut  
  while( my $line = <$info>)  {   
   print "line:$line\n"; 
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
		
		if ($line =~ m/Switch      :\s(.*)\sRev/i) { # Name of switch
			%hw_info = (
			"hw_item" => 'Switch',
			"hw_name" => $1,
			"hw_ver"  =>'',
			"hw_amount" => '' );
			DB_writeHwInfo($rt_id, \%hw_info);
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
			%hw_info = (	"hw_item" => 'Switch',
			"hw_name" => $1,
			"hw_ver"  =>'',
			"hw_amount" => '' );
			DB_writeHwInfo($rt_id, \%hw_info);
		}
		elsif($line =~ m/Subsystem     (.*)$/i)
		{
			%hw_info = (	"hw_item" => 'Subsystem',
			"hw_name" => $1,
			"hw_ver"  =>'',
			"hw_amount" => '' );
			DB_writeHwInfo($rt_id, \%hw_info);
		}
  }

  close $info;


  return "ok";

}


sub hp_parse_hardwr {
    
  my ($rt_id,$hardwr_file) = @_[0..1];

  
    open my $info, $$hardwr_file or
    return "error - hardware file $hardwr_file: $!\n";
print STDERR "hard=".$hardwr_file."\n";
  DB_startHwInfo($rt_id);

  while( my $line = <$info>)  {   
   $line =~ s/[\n]//g;
   print STDERR "line:$line\n"; 

if ($line =~ m/Switch      :\s(.*)\sRev/i) { # Name of switch
			%hw_info = (
			"hw_item" => 'Switch',
			"hw_name" => $1,
			"hw_ver"  =>'',
			"hw_amount" => '' );
			DB_writeHwInfo($rt_id, \%hw_info);
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
			%hw_info = (	"hw_item" => 'Switch',
			"hw_name" => $1,
			"hw_ver"  =>'',
			"hw_amount" => '' );
			DB_writeHwInfo($rt_id, \%hw_info);
		}
		elsif($line =~ m/Subsystem     (.*)$/i)
		{
			%hw_info = (	"hw_item" => 'Subsystem',
			"hw_name" => $1,
			"hw_ver"  =>'',
			"hw_amount" => '' );
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

sub hp_parse_config {

  my ($rt_id,$config_file) = @_[0..1];

  open(F_RCF,"<$config_file") or
    return "error - config file $config_file: $!\n";

  while (<F_RCF>) {
    chomp;			# no newline
    s/^\s+//;			# no leading white
    s/\s+$//;			# no trailing white

    if( /^location \"([^\"]+)\";/ ) {
      DB_writeHostLocation($rt_id, $1);
      next;
    }
  }
  close(F_RCF);
  return "ok";
}



#
# Params:
#  router_id
#  interfaces file

sub hp_parse_interfaces {
  my ($rt_id,$ifc_file) = @_[0..1];
  print "Parsing $ifc_file\n";

  open(F_RCF,"<$ifc_file") or 
    return "error - interfaces file $ifc_file: $!\n";

  my @old_ph_ifcs = @{DB_getPhInterfaces($rt_id)};
  my @old_ifcs = @{DB_getInterfaces($rt_id)};

  my %phifc;
  my $ph_int_id = '';

  my $phInterface = "";
  my $logInterface = "";
  my $protocol = "";
 

  while (<F_RCF>) {
    chomp;			# no newline
    s/\s+$//;			# no trailing white
    
    #print "$_\n";

    if(/^Physical interface:\s+([^,]+),\s+([^,]+),\sPhysical link is\s(\S+)$/) {
      print "Ph. interface $1, state $2, link $3\n";
      my ($newPhInt, $newState, $newCond) = ($1, $2, $3);
      $newState = 'enabled' if $newState =~ /Enabled/;
      $newState = 'disabled' if $newState =~ /Disabled/;
      $newState = 'adm down' if $newState =~ /Administratively down/;
      $newCond = 'up' if $newCond =~ /Up/;
      $newCond = 'down' if $newCond =~ /Down/;
      if (($phInterface ne "") && !($phInterface =~ /^\.local\./)) {
	DB_writePhInterface($rt_id, \%phifc);
	@old_ph_ifcs = grep {!/^$phifc{"interface"}$/} @old_ph_ifcs;
      }
      if (($logInterface ne "") && ($ifc{"ip address"} ne '0.0.0.0' && $ifc{"ip address"} ne '127.0.0.1')) {
	DB_writeInterface( $rt_id, $ph_int_id, \%ifc );
	@old_ifcs = grep {!/^$ifc{"interface"}$/} @old_ifcs;
      }
      $phInterface = $newPhInt;
      $logInterface = "";
      @ifc{("interface","ip address","mask","description")} =
	('','0.0.0.0','255.255.255.255','');
      @phifc{("interface","state","condition","speed","description")} =
	($phInterface,$newState,$newCond,'','');
      $protocol = "";
      next;
    }

    # skip local phys interfaces
    if ($phInterface =~ /^\.local\./) {
      next;
    }

    if (/^  Description:\s+(.*)$/) {
      $phifc{"description"} = $1;
    }

    if (/^  (\S+\s+)*Speed:\s+([^,]*)[,]*.*$/) {
      my $speed = $2;
      $phifc{"speed"} = $speed;
      if ($speed =~ /^(\d+)m$/) {
	$phifc{"speed"} = $1."000000";
      }
      if ($speed =~ /^(\d+)mbps$/) {
	$phifc{"speed"} = $1."000000";
      }
      if ($speed =~ /^OC3$/) {
	$phifc{"speed"} = "155000000";
      }
      if ($speed =~ /^OC12$/) {
	$phifc{"speed"} = "622000000";
      }
      if ($speed =~ /^OC48$/) {
	$phifc{"speed"} = "2488000000";
      }
      if ($speed =~ /^OC192$/) {
	$phifc{"speed"} = "9952000000";
      }
      print "Speed: $phifc{'speed'}\n";
    }

    # Logical interface so-6/0/0.0 (Index 25) (SNMP ifIndex 20) (Generation 27)
    if (/^  Logical interface\s+(\S+)\s+\(Index\s+(\d+)\)\s+\(SNMP ifIndex\s+(\d+)\)/) {
      print "Log. interface $1, index $2, snmp idx $3\n";
      if ($logInterface eq "") {
	DB_writePhInterface($rt_id, \%phifc);
	@old_ph_ifcs = grep {!/^$phifc{"interface"}$/} @old_ph_ifcs;
	$ph_int_id = DB_getPhInterfaceId($rt_id, $phInterface);
      } 
      if (($logInterface ne "") && ($ifc{"ip address"} ne '0.0.0.0')) {
	DB_writeInterface( $rt_id, $ph_int_id, \%ifc );
	@old_ifcs = grep {!/^$ifc{"interface"}$/} @old_ifcs;
      }
      $logInterface = $1;
      @ifc{("interface","ip address","mask","description")} =
	($1,'0.0.0.0','255.255.255.255','');
      $protocol = "";
      next;
    }

    # rest is for log interfaces only
    if ($logInterface eq "") {
      next;
    }
 
	 if (/\sDescription:\s+(.*)$/) {
      $ifc{"description"} = $1;
    }
	
    # Protocol inet, MTU: Unlimited, Generation: 7, Route table: 0
    if (/^    Protocol\s+inet,/) {
      print "Protocol: inet\n";
      $protocol = "inet";
      next;
    }

    if (/^    Protocol\s+([^,]+),/) {
      print "Protocol: other\n";
      $protocol = $1;
      next;
    }

    if ($protocol eq "inet") {
    #        Destination: 172.26.27/24, Local: 172.26.27.20,
      if (/^        Destination:\s+(\d+\.\d+\.\d+\.\d+|\d+\.\d+\.\d+|\d+\.\d+|\d+)\/(\d+),\s+Local:\s+(\d+\.\d+\.\d+\.\d+)\D*/) {
	print "Dest: $1, bits: $2, local: $3\n";
	$ifc{ 'ip address' } = $3;
	$ifc{ 'mask' } = bits2mask($2);
	print "mask: $ifc{ 'mask' }\n";
	next;
      }

      # handle this for local interfaces only
      if (/^        Destination:\s+(\w+),\s+Local:\s+(\d+\.\d+\.\d+\.\d+)\D*/) {
	$ifc{ 'ip address' } = $2;
	if ($phInterface =~ /^lo\d+/) {
	  print "Local interface, ip $ifc{ 'ip address' }\n";
	  $ifc{ 'mask' } = '255.255.255.255';
	}
	#print "Dest: $1, local: $2\n";
	next;
      }
    }
  }

  if (($phInterface ne "") && !($phInterface =~ /^\.local\./)) {
    DB_writePhInterface($rt_id, \%phifc);
    @old_ph_ifcs = grep {!/^$phifc{"interface"}$/} @old_ph_ifcs;
  }
  if (($logInterface ne "") && ($ifc{"ip address"} ne '0.0.0.0' && $ifc{"ip address"} ne '127.0.0.1')) {
    DB_writeInterface( $rt_id, $ph_int_id, \%ifc );
    @old_ifcs = grep {!/^$ifc{"interface"}$/} @old_ifcs;
  }

  DB_dropPhInterfaces($rt_id, \@old_ph_ifcs);
  DB_dropInterfaces($rt_id, \@old_ifcs);

  close(F_RCF);
  return "ok";
}

1;

__END__