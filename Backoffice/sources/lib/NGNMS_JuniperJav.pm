package NGNMS_JuniperJav;

use strict;

# use Data::Dumper;
use NGNMS_DB;
use NGNMS_util;
use Data::Dumper;
use Net::JuniperJav qw($Error $debug $TIMEOUT);


# $Net::Juniper::debug=1;

if (defined($ENV{"NGNMS_TIMEOUT"})) {
  $Net::JuniperJav::TIMEOUT = $ENV{"NGNMS_TIMEOUT"};
} else {
  $Net::JuniperJav::TIMEOUT = 60;
}

require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $data);

@ISA = qw(Exporter AutoLoader);

## set the version for version checking; uncomment to use
$VERSION     = 0.01;

@EXPORT      = qw(&juniper_parse_isis
		  &juniper_parse_ospf
		  &juniper_parse_version
		  &juniper_parse_config
		  &juniper_parse_interfaces
		  &juniper_get_topologies
		  &juniper_get_configs);

# your exported package globals go here,
# as well as any optionally exported functions
@EXPORT_OK   = qw($data);

# print "loading NGNMS_Juniper\n";

# data

$data = "my data";

# Preloaded methods

my $session;
my $Error;

sub juniper_create_session {
  my ($host, $username) = @_[0..1];
  my @passwds = @_[2..3];
  my $access =@_[6..6];
  my $path_to_key =$_[7];

  $Error = undef;
  if(!defined($access))
  {
	$access = "Telnet";
  }
#  print "access:".$access.";host:".$host."username=".$username.";passwd0=".$passwds[0].";passwd1=".$passwds[1]."\n";
  $session = Net::JuniperJav->new($access,$host, $username, @passwds,$path_to_key);
 

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
    #$session->max_buffer_length(10 * $MB);
  }
}

sub juniper_get_file($$) {
  my ($cmd, $fname) = @_[0..1];
  $Error = undef;
  my @data = $session->cmd($cmd);
  if (! @data) {
    $session->close;
    $Error = "juniper: " . $session->errmsg();
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

sub juniper_get_configs {
  my ($host, $username) = @_[0..1];
  my @passwds = @_[2..3];
  my $configPath = $_[4];
  my $acc = $_[6];
  print "Getting configs from $host\n";
  my @params = ($_[0],$_[1],$_[2],$_[3],'','',$_[6]);
##  juniper_create_session(@_);
  juniper_create_session(@params);
  return $Error if $Error;

  # version
  #
  juniper_get_file('show version', $configPath."_version.txt") or
    return $Error;

  # hardware inventory
  #
  juniper_get_file('show chass hardw', $configPath."_hardware.txt") or
    return $Error;

  # Running config
  #
  juniper_get_file('show config', $configPath."_config.txt") or
    return $Error;

  # Interfaces
  #
  juniper_get_file('show interface extensive', $configPath."_interfaces.txt") or
    return $Error;

  $session->close;

  return "ok";
}

sub juniper_get_topologies ($$$$$) {
  my ($host, $username) = @_[0..1];
  my @passwds = @_[2..3];
  my $access = @_[4..4];
  my @params = ($_[0],$_[1],$_[2],$_[3],'','',$_[4]);
  my $filename1 = $host."_isis.txt";
  my $filename2 = $host."_ospf.txt";
  
  
  juniper_create_session(@params);
  return $Error if $Error;

  # specific timeout for the topology collection
  $session->timeout(10);

  if (defined($ENV{"NGNMS_CONFIGS"})) {
		$filename1 = $ENV{"NGNMS_CONFIGS"}."/".$filename1;
		$filename2 = $ENV{"NGNMS_CONFIGS"}."/".$filename2;
	}
  
  print "Getting ISIS topology...\n";
  juniper_get_file('show isis database extensive', $filename1) or
    return $Error;

  print "Getting OSPF topology...\n";
  juniper_get_file('show ospf database extensive', $filename2)  or
    return $Error;

  $session->close;
  print "Done with topology collection \n";
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

sub juniper_parse_version {

  my ($rt_id,$host,$version_file) = @_[0..2];

  open(F_VERSF,"<$version_file") or
    return "error - version file $version_file: $!\n";

  DB_startSwInfo($rt_id);

  while (<F_VERSF>) {
    chomp;			# no newline
    s/^\s+//;			# no leading white
    s/\s+$//;			# no trailing white

    if (/^Model:\s*(\S+)$/) {
      DB_writeHostModel($rt_id,$1);
    }

    if (/^(JUNOS.*) \[(.*)\]/) {
      $sw_info{'sw_item'} = 'Software';
      ( $sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( $1, $2 );
      DB_writeSwInfo($rt_id, \%sw_info);
      next;
    }
  }

  close(F_VERSF);


  return "ok";

}

sub juniper_parse_hardwr {

  my ($rt_id,$hardwr_file) = @_[0..1];

  open(F_HARDWR,"<$hardwr_file") or
    return "error - hardware file $hardwr_file: $!\n";

  DB_startHwInfo($rt_id);

  while (<F_HARDWR>) {
    chomp;			# no newline
    s/^\s+//;			# no leading white
    s/\s+$//;			# no trailing white

    my @inventory = split (m'\s{2,}');

    # This works well now - only hardware anomalies cause error messages on the console, which is fine by me

    if ( ! defined $inventory[0]) { next;}
    if ( $inventory[0] eq 'Hardware inventory:') {next;}
    if ( $inventory[0] eq 'Item') { next;}
    if ( $inventory[0] eq 'Chassis') {
      %hw_info = (	"hw_item" => "$inventory[0]",
			"hw_name" => "$inventory[2]",
			"hw_ver"  => "$inventory[1]",
			"hw_amount" => '' );

      DB_writeHwInfo($rt_id, \%hw_info);

      next;
    }

    if ( $inventory[0] eq 'Routing Engine') {
      if( $#inventory == 4 ) {
	%hw_info = (	"hw_item" => "$inventory[0]",
			"hw_name" => "$inventory[4]",
			"hw_ver"  => "$inventory[3]",
			"hw_amount" => "$inventory[2]" );
      }
      elsif( $#inventory == 2 ) {
	%hw_info = (	"hw_item" => "$inventory[0]",
			"hw_name" => "$inventory[2]",
			"hw_ver"  => "$inventory[1]",
			"hw_amount" => '' );
      }
      else {
	# all other cases: WTF?
	%hw_info = (	"hw_item" => "$inventory[0]",
			"hw_name" => '',
			"hw_ver"  => '',
			"hw_amount" => ''  );
      }

      DB_writeHwInfo($rt_id, \%hw_info);

      next;
    }

    if (!defined $inventory[2] ) {
	$inventory[2] = ' ';
    }

    if (!defined $inventory[3] ) {
	$inventory[3] = ' ';
    }

    if (!defined $inventory[4] ) {
	$inventory[4] = ' ';
    }

    %hw_info = (	"hw_item" => "$inventory[0]",
			"hw_name" => "$inventory[4]",
			"hw_ver"  => "$inventory[3]",
			"hw_amount" => "$inventory[2]" );

    DB_writeHwInfo($rt_id, \%hw_info);
    next;

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

sub juniper_parse_config {

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
# parse 'show isis...' output
#
# Params:
#  isis file

sub juniper_parse_isis {
  my $isis_file = shift;

  print "Parsing Juniper topology file $isis_file\n";

  my %host_ips;
  my %links;

  open(F_ISISF,"<$isis_file") or 
    return "error - ISIS file $isis_file: $!\n";

#  skip_till(*F_ISISF,"^IS-IS level 2 link-state database:");

  my $host = '';
  my $state = '';
  my $bkst = 0;

  # skip header
  while (<F_ISISF>) {
    chomp;
    if (/^([-.\w]+|\d+\.\d+\.\d+\.\d+)\.(\d+)-(\d\d).*/) {
      $host=$1;
      $bkst = 0;
      if( "$2" ne "00" ) {
	$bkst = 1;
      }
      print "Host:", $host, "\n";
      DB_addHostNoWrite( \%host_ips, $host);
      $state = 'host';
      last;
    }
  }
  return "Empty ISIS topology" if !length($host);

  my $ip_addr = "";

  while (<F_ISISF>) {
    chomp;			# no newline
    s/\s+$//;			# no trailing white

#    print "$_\n";

    if (/^\s{1,4}(Hostname):\s+([-.\w]+|\d+\.\d+\.\d+\.\d+)$/) {
#      print "$1: \"$2\"\n";
      if ($host ne $2) {
	print "Inconsistent ISIS file??? ($host, $2)\n";
      }
      next;
    }
    if (/^\s{1,4}(IP address):\s+(\d+\.\d+\.\d+\.\d+)/) {
      if ($state eq 'TLVs') {
	$ip_addr = $2;
	print "$1: \"$ip_addr\"\n";
	DB_addHostIP( \%host_ips, $host, $ip_addr );
      }
      next;
    }

    if (/^\s+TLVs:.*/) {
      $state = 'TLVs';
      next;
    }

    if (/^\s+IS neighbor:\s+([-.\w]+|\d+\.\d+\.\d+\.\d+)\.(\d+)\s+Metric:.*/) {
      # print "link $host $1\n";
      if (($state eq "host") and ($host ne $1)) {
	if (( "$2" ne "00") or $bkst) {
	  print "=====>>> Broadcast link $host $2 <<<=====\n";
	  DB_addLinkNoWrite( \%links, $host, $1, "B" );
	} else {
	  DB_addLinkNoWrite( \%links, $host, $1, "P" );
	}
      }
      next;
    }

    if (/^\s+IS neighbor:\s+([-.\w]+|\d+\.\d+\.\d+\.\d+)\.\d+,.*/) {
      $state = 'Neighbor' if $state eq 'TLVs';
      next;
    }

    # end of this record
    if (/^([-.\w]+|\d+\.\d+\.\d+\.\d+)\.(\d+)-\d\d.*/) {
      $host=$1;
      print "Host:", $host, "\n";
      $bkst = 0;
      if( "$2" ne "00" ) {
	$bkst = 1;
      }
      DB_addHostNoWrite( \%host_ips, $host);
      $state = 'host';
    }
  }
  close(F_ISISF);

  DB_writeTopology( \%host_ips, \%links );
  return "ok";
}

#
# parse 'show ospf...' output
#
# Params:
#  ospf file

sub juniper_parse_ospf {
  my $ospf_file = shift;

  print "Parsing Juniper topology file $ospf_file\n";

  my %host_ips;
  my %links;
  my %areas;      # Map areas to DRs

  open(F_OSPFF,"<$ospf_file") or 
    return "error - OSPF file $ospf_file: $!\n";

  my $host = '';
  my $network = '';
  my $state = '';
  my $bkst = 0;

  # skip header
  while (<F_OSPFF>) {
    chomp;
    if (/^Router\s+\**(\d+\.\d+\.\d+\.\d+).*/) {
      my $ip = $1;
      $host=$ip;
      print "Host:", $host, "\n";
      DB_addHostNoWrite( \%host_ips, $host);
      DB_addHostIP( \%host_ips, $host, $ip);
      $state = 'host';
      last;
    }
  }
  return "Empty OSPF topology" if !length($host);

  my $ip_addr = "";

  while (<F_OSPFF>) {
    chomp;			# no newline
    s/\s+$//;			# no trailing white

#    print "$_\n";

    if (/^\s+id\s+(\d+\.\d+\.\d+\.\d+),\s+data\s+(\d+\.\d+\.\d+\.\d+),\s+Type\s+PointToPoint\s+.*/) {
      # print "link $host $1\n";
      if (($state eq "host") and ($host ne $1)) {
	  DB_addLinkNoWrite( \%links, $host, $1, "P" );
      }
      next;
    }

    if (/^\s+id\s+(\d+\.\d+\.\d+\.\d+),\s+data\s+(\d+\.\d+\.\d+\.\d+),\s+Type\s+Transit\s+.*/) {
      # print "link $host $1\n";
      if (($state eq "host") and ($host ne $1)) {
	  DB_addLinkNoWrite( \%links, $host, $1, "B" );
      }
      next;
    }

    # end of this record
    if (/^Router\s+\**(\d+\.\d+\.\d+\.\d+).*/) {
      my $ip = $1;
      $host=$ip;
      print "Host:", $host, "\n";
      DB_addHostNoWrite( \%host_ips, $host);
      DB_addHostIP( \%host_ips, $host, $ip);
      $state = 'host';
      next;
    }

    if (/^Network\s+\**(\d+\.\d+\.\d+\.\d+)\s+(\d+\.\d+\.\d+\.\d+).*/) {
      print "Network:", $network, "\n";
      $areas{$1} = $2;
      $state = 'Network';
      next;
    }

    if (/^(OpaqArea|Summary)\s+.*/) {
      $state = $1;
      next;
    }
  }
  close(F_OSPFF);

  # replace all areas with corresponding Designated routers
  foreach my $area (keys %areas) {
	if ($area ne $areas{$area}) {
      DB_replaceHost( \%links, $area, $areas{$area});
      DB_dropHost( \%host_ips, $area);
}
  }

  DB_writeTopology( \%host_ips, \%links );
  return "ok";
}

#
# Params:
#  router_id
#  interfaces file

sub juniper_parse_interfaces {
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

# END { print "deleting NGNMS_Juniper\n" };

1;

__END__
