#
# NextGen NMS
#
# NGNMS_Cisco.pm: interfacing with Cisco routers
#
# Copyright (C) 2002,2003 OptOSS LLC
#
# Author: M.Golov
#

package NGNMS_Cisco;

use strict;

# use Data::Dumper;
use NGNMS_DB;
use NGNMS_util;
use Net::Telnet::Cisco;

require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $timeout);

@ISA = qw(Exporter AutoLoader);

$VERSION     = 0.01;

# your exported package globals go here,
# as well as any optionally exported functions
@EXPORT_OK   = qw($timeout);

# print "loading NGNMS_Cisco\n";

# $Net::Telnet::Cisco::DEBUG = 1;

# Test
my $getTopReturn;
# $getTopReturn = "ok";

if (defined($ENV{"NGNMS_TIMEOUT"})) {
  $timeout = $ENV{"NGNMS_TIMEOUT"};
} else {
  $timeout = 60;
}


# Preloaded methods

my $community = 'public';

###################################################
# getting stuff from routers

my $session;

sub cisco_connect {

  my ($host, $username, $password, $enablepw) = @_[0..3];

  $session = Net::Telnet::Cisco->new( Host => $host,
					 #Input_Log => $host . "_input.log",
					 #Output_log => $host . "_output.log",
					 #Dump_log => $host . "_dump.log",
					 Timeout => $timeout,
					 Errmode => "return"
				       );

  return "cisco: failed to connect to host" unless $session;
  $session->prompt('/(?m:^[\w.\@-]+\s?(?:\(config[^\)]*\))?\s?[\$#>]\s?(?:\(enable\))?\s*$)/');

  my $ok = $session->login($username, $password);
  #printf "cisco login returned", $ok, "\n";

  if( !$ok ) {
    $session->close;
    return "cisco: login failed";
  }

  $session->enable($enablepw);

  my @output = $session->cmd('show privilege');
  $output[0]=~s/\n//g;
  if ($output[0] ne "Current privilege level is 15") {
    $session->close;
    return "cisco: enable failed";
  }

  $session->cmd("terminal length 0");

  my $MB = 1024 * 1024;
  $session->max_buffer_length(10 * $MB);

  return "ok";
}

my $Error;

sub cisco_get_file($$) {
  my ($cmd, $fname) = @_[0..1];
  $Error = undef;
  my @data = $session->cmd($cmd);
  if (! @data) {
    $Error = "cisco: " . $session->errmsg();
    return undef;
  }
  #    print @data;
  if (!open(F_DATA, ">$fname")) {
    $Error = "Cannot open file $fname for writing: $!";
    return undef;
  }
  print F_DATA @data;
  close (F_DATA);
  1;
}

# get ISIS and OSPF topologies from router
# Params:
#  host name or ip
#  username (may be "")
#  password
#  enable password
#
# Output:
#  creates 2 files:
#  <host>_isis.txt
#  <host>_ospf.txt
#
# Return:
#  "ok" or error text
#

sub cisco_get_topologies ($$$$) {
  return $getTopReturn if defined($getTopReturn);

  my ($host, $username, $password, $enablepw) = @_[0..3];
  my $filename1 = $host."_isis.txt";
  my $filename2 = $host."_ospf.txt";
  my $er = cisco_connect(@_);
  return $er if( $er !~ m/ok/ );

	if (defined($ENV{"NGNMS_CONFIGS"})) {
		$filename1 = $ENV{"NGNMS_CONFIGS"}."/".$filename1;
		$filename2 = $ENV{"NGNMS_CONFIGS"}."/".$filename2;
	}

  print "Getting ISIS topology...\n";
  if( !cisco_get_file('show isis database detail', $filename1)) {
    if( $Error =~ /% Invalid input detected/ ) {
	print "NGNMS: $host: ISIS protocol not supported\n";
    } else {
	$session->close();
      return $Error;
    }
  }

  print "Getting OSPF topology...\n";
  if(!cisco_get_file('show ip ospf database router', $filename2)) {
	$session->close();
      return $Error;
    }

  $session->close;
  print "Done\n";

  return "ok";
}

sub cisco_get_configs {
  my ($host, $user, $password, $enablepw, $configPath) = @_[0..4];
  $community = $_[5];
  print "Getting configs from $host\n";

  my $er = cisco_connect(@_);
  return $er if( $er !~ m/ok/ );

  # get version
  #
  if( !cisco_get_file('show version', $configPath."_version.txt")) {
	$session->close();
      return $Error;
    }

  # Running config
  #
  $Error = undef;
  my @data = $session->cmd('show running-config');
  if (! @data) {
    $session->close;
    return "cisco: " . $session->errmsg();
  }
  # strip out all lines from the beginning until ! is found
  my $i = 0;
  while ($data[$i] !~ m/!/) {
    $data[$i] = '';
    $i++;
  }

  #    print @data;
  my $fname=$configPath."_running_config.txt";
  if (!open(F_DATA, ">$fname")) {
    $session->close;
    return "Cannot open file $fname for writing: $!";
  }
  print F_DATA @data;
  close (F_DATA);

  # Interfaces
  #
  if( !cisco_get_file('show interfaces', $configPath."_interfaces.txt")) {
	$session->close();
      return $Error;
    }

  $session->close;

  return "ok";
}

###################################################
# parsing

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

sub cisco_parse_version {
  my ($rt_id,$host,$version_file) = @_[0..2];
  print "Parsing $version_file\n";

  open(F_VERSF,"<$version_file") or
    return "error - version file $version_file: $!\n";

  skip_till(*F_VERSF,".*Cisco Internetwork Operating System Software\.*");

  DB_startSwInfo($rt_id);
  DB_startHwInfo($rt_id);

  while (<F_VERSF>) {
    chomp;			# no newline
    s/^\s+//;			# no leading white
    s/\s+$//;			# no trailing white

    if (/^(IOS .* Software [^,]*), Version ([^,]*).*/) {
      $sw_info{'sw_item'} = 'Software';
      ( $sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( $1, $2 );
      DB_writeSwInfo($rt_id, \%sw_info);
      next;
    }

    if (/^(ROM: [^,]*), Version ([^,\s]*).*/) {
      $sw_info{'sw_item'} = 'Firmware';
      ( $sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( $1, $2 );
      DB_writeSwInfo($rt_id, \%sw_info);
      next;
    }

    if (/^(BOOTLDR: [^,]*), Version ([^,\s]*).*/) {
      $sw_info{'sw_item'} = 'Firmware';
      ( $sw_info{'sw_name'}, $sw_info{'sw_ver'} ) = ( $1, $2 );
      DB_writeSwInfo($rt_id, \%sw_info);
      next;
    }

    if (/^(cisco .*)processor(.*)with (.*)of memory.*/) {

      %hw_info = (	"hw_item" => 'Processor',
			"hw_name" => $1,
			"hw_ver"  => $2,
			"hw_amount" => '' );
      DB_writeHwInfo($rt_id, \%hw_info);

      %hw_info = (	"hw_item" => 'Memory',
			"hw_name" => 'RAM',
			"hw_ver"  => '',
			"hw_amount" => $3 );
      DB_writeHwInfo($rt_id, \%hw_info);
     next;
    }

    # 507K bytes of non-volatile configuration memory.
    if (/^(\w* bytes) of non-volatile configuration memory.*/) {
      %hw_info = (	"hw_item" => 'Memory',
			"hw_name" => 'NVRAM',
			"hw_ver"  => '',
			"hw_amount" => $1 );
      DB_writeHwInfo($rt_id, \%hw_info);
      next;
    }
#    print "\n";
#    print ;

    if (/^(\w* bytes).*Flash.PCMCIA.*at.(slot \d?).*/) {
      %hw_info = (	"hw_item" => 'Memory',
			"hw_name" => 'Flash PCMCIA',
			"hw_ver"  => $2,
			"hw_amount" => $1 );
      DB_writeHwInfo($rt_id, \%hw_info);
      next;
    }

    if (/^(\w* bytes).*ATA.PCMCIA.*at.(slot \d?).*/) {
      %hw_info = (	"hw_item" => 'Memory',
			"hw_name" => 'ATA PCMCIA',
			"hw_ver"  => $2,
			"hw_amount" => $1 );
      DB_writeHwInfo($rt_id, \%hw_info);
      next;
    }

    if (/^(\w* bytes).*Flash.internal.*(SIMM).*/) {
      %hw_info = (	"hw_item" => 'Memory',
			"hw_name" => 'internal Flash',
			"hw_ver"  => $2,
			"hw_amount" => $1 );
      DB_writeHwInfo($rt_id, \%hw_info);
      next;
    }
  }

  close(F_VERSF);

  # get equipment type - to be used with ucd-snmp version: 4.2.5
##  old command : my $ht = `snmpget -m ALL -c $community $host sysObjectID.0`;

    my $ht = `snmpget -v 2c -m ALL -c $community $host sysObjectID.0`;
	
## parse old command $ht =~/OID:.*\.(.*$)/; 
    my @t_arr = split(/:/,$ht);
	my $ind = $#t_arr;
	my $last_el = $t_arr[$ind];
	print "last_el=".$last_el."\n";
	if(!defined $last_el || $last_el eq '')
	{
		my $ht1 = `snmpget -v 1 -m ALL -c $community $host sysObjectID.0`;
		my @t_arr1 = split(/:/,$ht1);
		my $ind1 = $#t_arr1;
		$last_el = $t_arr1[$ind1];
		print "last_el1=".$last_el."\n";
	}
		
  DB_writeHostModel($rt_id,$last_el);
  return "ok";
}

#
# parse 'show running config' output
#
# Params:
#  router_id
#  run config file

sub cisco_parse_run_config {
  my ($rt_id,$run_config_file) = @_[0..1];
  print "Parsing $run_config_file\n";

  return "ok";

  open(F_RCF,"<$run_config_file") or die "error - run_config file $run_config_file: $!\n";

  while (skip_till(*F_RCF,"^interface .*")) {

    my %phifc;
    my $phInterface = "";
    my $logInterface = "";

    @ifc{("interface","ip address","mask","description")} = 
      ('','','255.255.255.255', '');

    @phifc{("interface","state","condition","speed","description")} =
	($phInterface,'','','','');

    /^(interface)\s+(\S+).*/;
    #print "$1: $2\n";
    $logInterface = $2;
    unless ( $logInterface =~ /\.\d+$/ ) {
      $phInterface = $logInterface;
    }
    $ifc{ 'interface' } = $logInterface;
    $phifc{ 'interface' } = $phInterface;

    print "Log interface: $logInterface\n";
    print "Ph interface: $phInterface\n";

    while (<F_RCF>) {
      chomp;			# no newline
      s/\s+$//;			# no trailing white
      last if /^!.*/;

      #print "$_\n";

      # ip addr and mask
      if (/^\s+(ip address)\s+(\d+\.\d+\.\d+\.\d+)\s+(\d+\.\d+\.\d+\.\d+)/) {
	#print "$1: \"$2\"\n";
	$ifc{ 'ip address' } = $2;
	$ifc{ 'mask' } = $3;
	next;
      }
      if (/^\s+(description)\s+(.*)/) {
	#print "$1: \"$2\"\n";
	$ifc{ 'description' } = $2;
	if ($phInterface ne "") {
	  $phifc{ 'description' } = $2;
	}
	next;
      }
    }
    #print Dumper( %ifc );
    if ($phInterface ne "") {
      DB_writePhInterface($rt_id, \%phifc);
    } else {
      $phInterface = $logInterface;
      for ($phInterface) {  s/\.\d+$//; }
    }
    if ($ifc{ 'ip address' } ne '' && $ifc{"ip address"} ne '127.0.0.1') {
      my $ph_int_id = DB_getPhInterfaceId($rt_id, $phInterface);
      DB_writeInterface( $rt_id, $ph_int_id, \%ifc );
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

sub cisco_parse_isis {
  my $isis_file = shift;

  my %host_ips;
  my %links;
  my $host='';
  my $bkst = 0;

  print "cisco_parse_isis: Parsing '$isis_file'\n";

  open(F_ISISF,"<$isis_file") or return "error - ISIS file $isis_file: $!";

  #skip_till(*F_ISISF,"^IS-IS Level-2 Link State Database");

  # skip header
  while (<F_ISISF>) {
    chomp;
    print $_;
    if (/^([-\w\.]+|\d+\.\d+\.\d+\.\d+)\.(\d+)-\d\d.*/) {
      $host=$1;
      $bkst = 0;
      if( "$2" ne "00" ) {
	$bkst = 1;
      }
      DB_addHostNoWrite( \%host_ips, $host);
      last;
    }
  }

  return "Empty ISIS topology" if !length($host);

  print "Host:", $host, "\n";

  while (<F_ISISF>) {
    chomp;			# no newline
    s/\s+$//;			# no trailing white

#    print "$_\n";

    if (/^\s+(Hostname):\s+(\d+\.\d+\.\d+\.\d+)$/ or
	/^\s+(Hostname):\s+([-\w\.]+)$/) {
#      print "$1: \"$2\"\n";
      if ($host ne $2) {
	print "Inconsistent ISIS file??? ($host, $2)\n";
      }
      next;
    }
    if (/^\s+(IP Address):\s+(\d+\.\d+\.\d+\.\d+)/) {
#      print "$1: \"$2\"\n";
      DB_addHostIP( \%host_ips, $host, $2 );
      next;
    }

    # First match the case with IP address
    if (/^\s+Metric:\s+\d+\s+IS(-Extended)*\s+(\d+\.\d+\.\d+\.\d+)\.(\d+).*/) {
      if ($host ne $2) {
	if (( "$3" ne "00") or $bkst) {
	  print "=====>>> Broadcast link $host $2 <<<=====\n";
	  DB_addLinkNoWrite( \%links, $host, $2, "B" );
	} else {
	  DB_addLinkNoWrite( \%links, $host, $2, "P" );
	}
      }
      next;
    }

    # Then try the host name
    if (/^\s+Metric:\s+\d+\s+IS(-Extended)*\s+([-\w\.]+)\.(\d+).*/) {
      if ($host ne $2) {
	if (( "$3" ne "00") or $bkst) {
	  print "=====>>> Broadcast link $host $2 <<<=====\n";
	  DB_addLinkNoWrite( \%links, $host, $2, "B" );
	} else {
	  DB_addLinkNoWrite( \%links, $host, $2, "P" );
	}
      }
      next;
    }

    # end of this record
    if (/^([-\w\.]+|\d+\.\d+\.\d+\.\d+)\.(\d+)-\d\d.*/) {
      $host=$1;
      $bkst = 0;
      if( "$2" ne "00" ) {
	$bkst = 1;
      }
      print "Host:", $host, "\n";
      DB_addHostNoWrite( \%host_ips, $host);
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

sub cisco_parse_ospf {
  my $ospf_file = shift;

  my %host_ips;
  my %links;
  my %areas;      # Map areas to DRs
  my $host='';
  my $state = '';
  my $DR = '';

  print "cisco_parse_ospf: Parsing '$ospf_file'\n";

  open(F_OSPFF,"<$ospf_file") or return "error - OSPF file $ospf_file: $!";

  # skip header
  while (<F_OSPFF>) {
    chomp;
    #print $_;
    if (/^\s+Link State ID:\s+(\d+\.\d+\.\d+\.\d+).*/) {
      my $ip = $1;
      $host=$ip;
      print "Host:", $host, "\n";
      $state='host';
      DB_addHostNoWrite( \%host_ips, $host);
      DB_addHostIP( \%host_ips, $host, $ip);
      last;
    }
  }

  return "Empty OSPF topology" if !length($host);

  while (<F_OSPFF>) {
    chomp;			# no newline
    s/\s+$//;			# no trailing white

    print "$_\n";

    if (/^\s+Link connected to: another Router \(point-to-point\).*/) {
      # print "link $host $1\n";
      if ($state eq "host") {
	$state='linkP';
      }
      next;
    }

    if (/^\s+Link connected to: a Transit Network.*/) {
      # print "link $host $1\n";
      if ($state eq "host") {
	$state='linkB';
      }
      next;
    }

    if (/^\s+\(Link ID\) Neighboring Router ID:\s+(\d+\.\d+\.\d+\.\d+).*/) {
      # print "link $host $1\n";
      if (($state eq "linkP") and ($host ne $1)) {
	  DB_addLinkNoWrite( \%links, $host, $1, "P" );
      }
      next;
    }

    if (/^\s+\(Link ID\) Designated Router address:\s+(\d+\.\d+\.\d+\.\d+).*/) {
      # print "link $host $1\n";
      if ($state eq "linkB") {
	my $ip = $1;
	$DR=$ip;
	DB_addHostNoWrite( \%host_ips, $DR);
	DB_addHostIP( \%host_ips, $DR, $ip);
	DB_addLinkNoWrite( \%links, $host, $DR, "B" );
      }
      next;
    }

    if (/^\s+\(Link Data\) Router Interface address:\s+(\d+\.\d+\.\d+\.\d+).*/) {
      # print "link $host $1\n";
      if (($state eq "linkB") and ($DR eq $1)) {
	if( !defined($areas{$DR}) ) {
	  $areas{$DR} = $host;
	}
      }
      next;
    }

    # end of this record
    if (/^\s+Link State ID:\s+(\d+\.\d+\.\d+\.\d+).*/) {
      my $ip = $1;
      $host=$ip;
      print "Host:", $host, "\n";
      DB_addHostNoWrite( \%host_ips, $host);
      DB_addHostIP( \%host_ips, $host, $ip);
      $state = 'host';
    }
  }
  close(F_OSPFF);

  # replace all areas with corresponding Designated routers
  foreach my $area (keys %areas) {
	if( $area ne $areas{$area} ) {
      DB_dropHost( \%host_ips, $area);
      DB_replaceHost( \%links, $area, $areas{$area});
	}
  }

  DB_writeTopology( \%host_ips, \%links );

  return "ok";
}

#
# parse 'show interfaces' output
#
# Params:
#  router_id
#  interfaces file

sub cisco_parse_interfaces {
  my ($rt_id,$ifc_file) = @_[0..1];
  print "Parsing $ifc_file\n";

  open(F_RCF,"<$ifc_file") or 
    return "error - interfaces file $ifc_file: $!\n";

  my @old_ifcs = @{DB_getInterfaces($rt_id)};
  my @old_ph_ifcs = @{DB_getPhInterfaces($rt_id)};

  my %phifc;
  my $ph_int_id = '';

  my $phInterface = "";
  my $logInterface = "";
  my $protocol = "";
  $ifc{ 'ip address' } = '';

  while (<F_RCF>) {
    chomp;			# no newline
    s/\s+$//;			# no trailing white

    #print "$_\n";

    if(/^(\S+)\s+is\s+([^,]+),\s+line protocol is\s+(.*)$/) {
      my ($newInt, $newState, $newCond) = ($1, $2, $3);
      $newState = 'enabled' if $newState =~ /up/;
      $newState = 'disabled' if $newState =~ /down/;
      $newCond = 'up' if $newCond =~ /up/;
      $newCond = 'down' if $newCond =~ /down/;
      print "Interface $newInt, state $newState, line $newCond\n";

      if ($phInterface ne "") {
	DB_writePhInterface($rt_id, \%phifc);
	@old_ph_ifcs = grep {!/^$phifc{"interface"}$/} @old_ph_ifcs;
      } else {
	$phInterface = $logInterface;
	for ($phInterface) {  s/\.\d+$//; }
      }
      if ($ifc{ 'ip address' } ne '' && $ifc{"ip address"} ne '127.0.0.1') {
	my $ph_int_id = DB_getPhInterfaceId($rt_id, $phInterface);
	DB_writeInterface( $rt_id, $ph_int_id, \%ifc );
	@old_ifcs = grep {!/^$ifc{"interface"}$/} @old_ifcs;
      }

      $logInterface = $newInt;
      $phInterface = '';
      unless ( $logInterface =~ /\.\d+$/ ) {
	$phInterface = $logInterface;
      }

      @ifc{("interface","ip address","mask","description")} =
	($logInterface,'','255,255,255','');
      @phifc{("interface","state","condition","speed","description")} =
	($phInterface,$newState,$newCond,'','');
      next;
    }

#   MTU 1500 bytes, BW 1000000 Kbit, DLY 10 usec, 

    if (/^  .*\s+BW\s+([^,]*)[,]*.*$/) {
      my $speed = $1;
      if ($speed =~ /^(\d+)\s+Kbit$/) {
	$phifc{"speed"} = $1."000";
      };
      print "Speed: $phifc{'speed'}\n";
      next;
    }

#  Description: vpn_int_cisco_1
    if (/^  Description:\s+(.*)$/) {
      $phifc{"description"} = $1;
      $ifc{"description"} = $1;
      next;
    }
#  Internet address is 13.0.0.2/24
    if (/^  Internet address is\s+(\d+\.\d+\.\d+\.\d+)\/(\d+)$/) {
      $ifc{ 'ip address' } = $1;
      $ifc{ 'mask' } = bits2mask($2);
      print "IP: $ifc{ 'ip address' }, mask: $ifc{ 'mask' }\n";
      next;
    }
  }

  if ($phInterface ne "") {
    DB_writePhInterface($rt_id, \%phifc);
    @old_ph_ifcs = grep {!/^$phifc{"interface"}$/} @old_ph_ifcs;
  } else {
    $phInterface = $logInterface;
    for ($phInterface) {  s/\.\d+$//; }
  }
  if ($ifc{ 'ip address' } ne '' && $ifc{"ip address"} ne '127.0.0.1') {
    my $ph_int_id = DB_getPhInterfaceId($rt_id, $phInterface);
    DB_writeInterface( $rt_id, $ph_int_id, \%ifc );
    @old_ifcs = grep {!/^$ifc{"interface"}$/} @old_ifcs;
  }

  DB_dropPhInterfaces($rt_id, \@old_ph_ifcs);
  DB_dropInterfaces($rt_id, \@old_ifcs);

  close(F_RCF);
  return "ok";
}


# END { print "deleting NGNMS_Cisco\n" };

1;

__END__
