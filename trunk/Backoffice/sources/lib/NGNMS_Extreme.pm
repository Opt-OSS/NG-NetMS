package NGNMS_Extreme;

use strict;

# use Data::Dumper;
use NGNMS_DB;
use NGNMS_util;
use Data::Dumper;
use File::Copy qw(copy);
use Net::Extreme qw($Error $debug $TIMEOUT);


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

@EXPORT      = qw(&extreme_parse_version
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

# Preloaded methods

my $session;
my $Error;

sub extreme_create_session {
  my ($host, $username) = @_[0..1];
  my @passwds = @_[2..3];
  my $access =@_[6..6];
  my $path_to_key =$_[7];

  $Error = undef;
  if(!defined($access))
  {
	$access = "Telnet";
  }
  print "Extreme:access:".$access.";host:".$host."username=".$username.";passwd0=".$passwds[0].";passwd1=".$passwds[1]."\n";
  $session = Net::Extreme->new($access,$host, $username, @passwds,$path_to_key);
 

  if(defined($session->_socket))
  {
	$session->open($access,$host, $username, @passwds);
	}
  else
  {
	  $session->_set_error("Conection with $host via $access was not established")
	  }
  

  if($session->{'error'} || !$session->{'logged_in'}) {
    $Error = $session->errmsg;
  }
  else {  
    my $MB = 1024 * 1024;
  }
}
sub extreme_get_file($$) {
  my ($cmd, $fname) = @_[0..1];
  $Error = undef;
  my @data = $session->cmd($cmd);
  if (! @data) {
    $session->close;
    $Error = "extreme: " . $session->errmsg();
    return undef;
  }
  #    print @data;
  if (!open(F_DATA, ">$fname")) {
    $session->close;
    $Error = "Cannot open file $fname for writing: $!";
    return undef;
  }
  print F_DATA @data;
  close (F_DATA);
  1;
}

sub extreme_get_configs {
  my ($host, $username) = @_[0..1];
  my @passwds = @_[2..3];
  my $configPath = $_[4];
  my $acc = $_[6];
  print "Getting configs from $host\n";
  my @params = ($_[0],$_[1],$_[2],$_[3],'','',$_[6]);
##  juniper_create_session(@_);
  extreme_create_session(@params);
  return $Error if $Error;

  # version
  #
  my $file_vers = $configPath."_version.txt";
  my $file_hard = $configPath."_hardware.txt";
  
  extreme_get_file('sh ver detail', $configPath."_version.txt") or
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

  $session->close;

  return "ok";
}

sub extreme_get_topologies ($$$$$) {

  return "ok";
}

my %sw_info = (	"sw_item" => undef,
		"sw_name" => undef,
		"sw_ver"  => undef );

my %hw_info = (	"hw_item" => undef,
		"hw_name" => undef,
		"hw_ver"  => undef,
		"hw_amount"  => undef );

my %ifc;









#
# parse 'show version' output
#
# Params:
#  router_id
#  vers file

sub extreme_parse_version {

  my ($rt_id,$host,$version_file) = @_[0..2];
  my @word;
  my $img_vers;
  
  open(F_VERSF,"<$version_file") or
    return "error - version file $version_file: $!\n";

  DB_startSwInfo($rt_id);

  while (<F_VERSF>) {
    chomp;			# no newline
    s/^\s+//;			# no leading white
    s/\s+$//;			# no trailing white
=for
    if (/^Model:\s*(\S+)$/) {
      DB_writeHostModel($rt_id,$1);
    }
=cut
    if(m/BootROM:\s(.*)    IMG:\s(.*)\s$/i)
		{
			$sw_info{'sw_item'} = 'Firmware';
           ( $sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( 'BootROM', $1 );
			DB_writeSwInfo($rt_id, \%sw_info);
			$sw_info{'sw_item'} = 'Firmware';
           ( $sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( 'IMG', $2 );
		    DB_writeSwInfo($rt_id, \%sw_info);
            
		}
		elsif(m/Image   :\s(.*) version\s(.*)$/i)
		{
			$img_vers = $2;
			@word = (split /\s/, $img_vers);
			$img_vers = $word[0];
			$sw_info{'sw_item'} = 'Firmware';
           ( $sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( $1, $img_vers );
			DB_writeSwInfo($rt_id, \%sw_info);
		}
		elsif(m/Diagnostics\s:\s(.*)$/i)
		{
			$sw_info{'sw_item'} = 'Firmware';
           ( $sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( 'Diagnostics', $1 );
			DB_writeSwInfo($rt_id, \%sw_info);
		}
  }

  close(F_VERSF);


  return "ok";

}

sub extreme_parse_hardwr {

  my ($rt_id,$hardwr_file) = @_[0..1];

  open(F_HARDWR,"<$hardwr_file") or
    return "error - hardware file $hardwr_file: $!\n";

  DB_startHwInfo($rt_id);

  while (<F_HARDWR>) {
    chomp;			# no newline
    s/^\s+//;			# no leading white
    s/\s+$//;			# no trailing white

if (m/Switch      :\s(.*)\sRev/i) { # Name of switch
			%hw_info = (
			"hw_item" => 'Switch',
			"hw_name" => $1,
			"hw_ver"  =>'',
			"hw_amount" => '' );
			DB_writeHwInfo($rt_id, \%hw_info);
			}
		elsif(m/PSU-1       :\s(.*)$/i)
		{
			%hw_info = (	"hw_item" => 'PSU-1',
			"hw_name" => $1,
			"hw_ver"  =>'',
			"hw_amount" => '' );
			DB_writeHwInfo($rt_id, \%hw_info);
		}
		elsif(m/PSU-2       :\s(.*)$/i)
		{
			%hw_info = (	"hw_item" => 'PSU-1',
			"hw_name" => $1,
			"hw_ver"  =>'',
			"hw_amount" => '' );
			DB_writeHwInfo($rt_id, \%hw_info);
		}
		elsif(m/Switch        (.*)$/i)
		{
			%hw_info = (	"hw_item" => 'Switch',
			"hw_name" => $1,
			"hw_ver"  =>'',
			"hw_amount" => '' );
			DB_writeHwInfo($rt_id, \%hw_info);
		}
		elsif(m/Subsystem     (.*)$/i)
		{
			%hw_info = (	"hw_item" => 'Subsystem',
			"hw_name" => $1,
			"hw_ver"  =>'',
			"hw_amount" => '' );
			DB_writeHwInfo($rt_id, \%hw_info);
		}
  }

  close(F_HARDWR);

  return "ok";
}

#
# parse 'show running config' output
#
# Params:
#  router_id
#  run config file

sub extreme_parse_config {

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

sub extreme_parse_interfaces {
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
