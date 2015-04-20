#
# NextGen NMS
#
# NGNMS_DB.pm: database interface
#
# Copyright (C) 2002,2003 OptOSS LLC
#
# Author: M.Golov
#

package NGNMS_DB;
use Data::Dumper;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $data);

# use Data::Dumper;
use NGNMS_util;
use DBI;
use DBD::Pg;
use DBD::Pg qw(:pg_types);

require Exporter;

@ISA = qw(Exporter AutoLoader);

## set the version for version checking; uncomment to use
$VERSION     = 0.01;

@EXPORT      = qw(&DB_open &DB_close &DB_vacuum
		  &DB_getRouterId &DB_getRouterIpAddr
		  &DB_getCommunity &DB_isCommunity
		  &DB_getCriptoKey &DB_addConfigFile
		  &DB_getRouterVendor &DB_isInRouterAccess
		  &DB_addRouter &DB_getRouterAccess
		  &DB_addHostNoWrite &DB_addHostIP &DB_dropHost &DB_replaceHost
		  &DB_addLinkNoWrite &DB_writeHosts &DB_writeLink
		  &DB_startSwInfo &DB_writeSwInfo
		  &DB_startHwInfo &DB_writeHwInfo
		  &DB_writeHostModel &DB_writeHostLocation
		  &DB_getInterfaces &DB_dropInterfaces &DB_writeInterface
		  &DB_writePhInterface &DB_getPhInterfaceId
		  &DB_getPhInterfaces &DB_dropPhInterfaces
		  &DB_writeTopology &DB_getRouters
		  &DB_dropLinks &DB_getSettings &DB_getRouterName
		  &DB_setHostVendor &DB_setHostState
		  &DB_getAllIntefaces &DB_isScanException
		  &DB_replaceRouterName &DB_getInterfaceRouterId
		  &DB_setHostLayer &DB_updateDiscoveryStatus
		  &DB_stopDiscovery &DB_insertDiscoveryStatus
		  &DB_isOpenedDiscovery &DB_lastchangeDiscovery
		  &DB_modeDiscovery &DB_updateDiscoveryStatusOne
		  &DB_percentDiscovery &DB_updateRouterId &DB_isDueCommunity
		  &DB_getDuplicateHostname &DB_getRouterIdDuplicateHostname
		  &DB_dropRouterId &DB_getCountUnion &DB_getCountIntersect
		  &DB_getMinRouterRA &DB_getAllHostname &DB_getBgpRouters
		  &DB_addBgpRouter &DB_getBgpRouterId 
		  &DB_writeTopologyBgp &DB_updateBgpRouterStatus 
		  &DB_updateAllBgpRouterStatus &DB_updateBgpRouterAS &DB_writeBgpLink);

# your exported package globals go here,
# as well as any optionally exported functions
@EXPORT_OK   = qw($data);

# print "loading NGNMS_DB\n";

# data

$data = "my data";

# Preloaded methods


my $dbh;
my $DB_host = 'localhost';
my $DB_name = 'ngnms';
my $DB_user= 'ngnms';
my $DB_passwd = 'ngnms';
my $DB_port = '5432';


sub DB_open {
  $DB_name =$_[0] if defined($_[0]);
  $DB_user = $_[1] if defined($_[1]);
  $DB_passwd = $_[2] if defined($_[2]);
  $DB_port =$_[3] if defined($_[3]);
  $DB_host =$_[4] if defined($_[4]);
  #print "db=".$DB_name.":"."user=".$DB_user.":"."passwd=".$DB_passwd.":"."port=".$DB_port;
  $dbh=DBI->connect("dbi:Pg:dbname=".$DB_name.";host=".$DB_host.";port=".$DB_port,
		    $DB_user, $DB_passwd,
		    { AutoCommit=>1, RaiseError=>1, PrintError=>0 });
}

sub DB_close {
  $dbh->disconnect();
}

sub DB_vacuum {
  my $q = $dbh->prepare("VACUUM ANALYZE");
  $q->execute();
}

# "park" all old recs for this router
# router_id

sub DB_startSwInfo ($) {
  my $rt_id = shift;
  my $SQL = "DELETE FROM inv_sw WHERE router_id = ?";
  my $if_h = $dbh->prepare($SQL);
  my $result = $if_h->execute($rt_id);
}

sub DB_writeSwInfo($*) {
  my $rt_id = shift;
  my $sw_info = shift;
  print Dumper(%$sw_info);
  my $SQL = "INSERT INTO inv_sw (router_id,sw_item,sw_name,sw_version) VALUES (?,?,?,?)";
  my $sw_h = $dbh->prepare($SQL);

  my @SQLARGS = @$sw_info{("sw_item","sw_name","sw_ver")};
  my $result = $sw_h->execute($rt_id,@SQLARGS);
  %$sw_info = (	"sw_item" => undef,
		"sw_name" => undef,
		"sw_ver"  => undef );
}

sub DB_startHwInfo ($) {
  my $rt_id = shift;
  my $SQL = "DELETE FROM inv_hw WHERE router_id = ?";
  my $if_h = $dbh->prepare($SQL);
  my $result = $if_h->execute($rt_id);
}

sub DB_writeHwInfo($*) {
  my $rt_id = shift;
  my $hw_info = shift;
  my $SQL = "INSERT INTO inv_hw (router_id,hw_item,hw_name,hw_version,hw_amount) VALUES (?,?,?,?,?)";
  my $sw_h = $dbh->prepare($SQL);

  my @SQLARGS =  @$hw_info{("hw_item","hw_name","hw_ver","hw_amount")};
  my $result = $sw_h->execute($rt_id,@SQLARGS);
  #print Dumper(%$hw_info);
  %$hw_info = (	"hw_item" => undef,
		"hw_name" => undef,
		"hw_ver"  => undef,
		"hw_amount" => undef );
}

###############################################################
# Logical interfaces
#

# Get list of ifc names by rt_id
sub DB_getInterfaces($) {
  my $rt_id = shift;
  local $dbh->{RaiseError};     # Ignore errors
  my $SQL = "SELECT name FROM interfaces WHERE router_id = $rt_id";
  my $rref = $dbh->selectcol_arrayref($SQL);
  # print Dumper($rref);
    return $rref;
}

# Get list of duplicate hostname
sub DB_getDuplicateHostname() {
  local $dbh->{RaiseError};     # Ignore errors
  my $SQL = "SELECT name,eq_vendor,eq_type FROM routers GROUP BY name,eq_vendor,eq_type HAVING(count(*))>1";
  my $rref = $dbh->selectcol_arrayref($SQL);
  # print Dumper($rref);
    return $rref;
}

# Get list of all hostname
sub DB_getAllHostname() {
  local $dbh->{RaiseError};     # Ignore errors
  my $SQL = "SELECT DISTINCT name FROM routers ORDER BY name";
  my $rref = $dbh->selectcol_arrayref($SQL);
  # print Dumper($rref);
    return $rref;
}


# Get list of  router_id for duplicate hostname
sub DB_getRouterIdDuplicateHostname($) {
  my $hname = shift;	
  local $dbh->{RaiseError};     # Ignore errors
  my $SQL = "SELECT router_id FROM routers where name='".$hname."' order by router_id";
  my $rref = $dbh->selectcol_arrayref($SQL);
  # print Dumper($rref);
    return $rref;
}


sub DB_getMinRouterRA($) {
	my $hname = shift;
	local $dbh->{RaiseError};     # Ignore errors
  my $SQL = "select min(ra.id_router) from routers r,router_access ra where r.name='".$hname."' and ra.id_router=r.router_id ";
  my $rref = $dbh->selectcol_arrayref($SQL);
#  print Dumper($rref);
  if (defined($rref)) {
    return $rref->[0];
  }
  return undef;
	}
	
	
# Get ifc id by rt_id and name
sub DB_getInterfaceId($$$$) {
  my $rt_id = shift;
  my $ph_int_id = shift;
  my $ifc_n = shift;
  my $ip_addr = shift;
  local $dbh->{RaiseError};     # Ignore errors
  my $SQL = "SELECT ifc_id FROM interfaces WHERE router_id = $rt_id AND ph_int_id = $ph_int_id AND name = \'$ifc_n\' AND ip_addr = \'$ip_addr\'";
  my $rref = $dbh->selectcol_arrayref($SQL);
#  print Dumper($rref);
  if (defined($rref)) {
    return $rref->[0];
  }
  return undef;
}

# Get ifc id by rt_id and name
sub DB_getInterfaceRouterId($) {
  my $addr= shift;
  
  local $dbh->{RaiseError};     # Ignore errors
  my $SQL = "SELECT router_id FROM interfaces WHERE ip_addr = \'$addr\'";
  my $rref = $dbh->selectcol_arrayref($SQL);
#  print Dumper($rref);
  if (defined($rref)) {
    return $rref->[0];
  }
  return undef;
}

sub DB_writeInterface($$*) {
  my $rt_id = shift;
  my $ph_int_id = shift;
  my $ifc = shift;
  my $ifc_id = DB_getInterfaceId( $rt_id, $ph_int_id, $ifc->{"interface"},$ifc->{"ip address"} );
  if( !defined($ifc_id) ) {
    # easy - insert new ifc
    my $SQL = "INSERT INTO interfaces (router_id,ph_int_id,name,ip_addr,mask,descr) VALUES (?,?,?,?,?,?)";
    my $if_h = $dbh->prepare($SQL);

    my @SQLARGS = @$ifc{("interface","ip address","mask","description")};
    my $result = $if_h->execute($rt_id,$ph_int_id,@SQLARGS);
    return $result;
  }

  # hard - update
  my $SQL = "UPDATE interfaces SET ip_addr = ?, mask = ?, descr = ? WHERE ifc_id = ?";
  my $if_h = $dbh->prepare($SQL);

  my @SQLARGS = @$ifc{("ip address","mask","description")};
  push @SQLARGS, $ifc_id;
  my $result = $if_h->execute(@SQLARGS);
}

# Delete logical interfaces
# Params: ref to array of log interfaces to delete
#
sub DB_dropInterfaces($$) {
  my $rt_id = shift;
  my $names = shift;
  my $if_h = $dbh->prepare("DELETE FROM interfaces WHERE router_id = $rt_id AND name = ?");
  foreach (@{$names}) {
    my $result = $if_h->execute($_);
  }
}

###############################################################
# Physical interfaces
#

# Get list of ifc names by rt_id
sub DB_getPhInterfaces($) {
  my $rt_id = shift;
  local $dbh->{RaiseError};     # Ignore errors
  my $SQL = "SELECT name FROM ph_int WHERE router_id = $rt_id";
  my $rref = $dbh->selectcol_arrayref($SQL);
  # print Dumper($rref);
    return $rref;
}

# Get ifc id by rt_id and name
sub DB_getPhInterfaceId($$) {
  my $rt_id = shift;
  my $ifc_n = shift;
  local $dbh->{RaiseError};     # Ignore errors
  my $SQL = "SELECT ph_int_id FROM ph_int WHERE router_id = $rt_id AND name = \'$ifc_n\'";
  my $rref = $dbh->selectcol_arrayref($SQL);
#  print Dumper($rref);
  if (defined($rref)) {
    return $rref->[0];
  }
  return undef;
}

sub DB_writePhInterface($*) {
  my $rt_id = shift;
  my $ifc = shift;
  my $ifc_id = DB_getPhInterfaceId( $rt_id, $ifc->{"interface"} );
  if( !defined($ifc_id) ) {
    # easy - insert new ifc
    my $SQL = "INSERT INTO ph_int (router_id,name,state,condition,speed,descr) VALUES (?,?,?,?,?,?)";
    my $if_h = $dbh->prepare($SQL);

    my @SQLARGS = @$ifc{("interface","state","condition","speed","description")};
    my $result = $if_h->execute($rt_id,@SQLARGS);
    return $result;
  }

  # hard - update
  my $SQL = "UPDATE ph_int SET state = ?, condition = ?, speed = ?, descr = ? WHERE ph_int_id = ?";
  my $if_h = $dbh->prepare($SQL);

  my @SQLARGS = @$ifc{("state","condition","speed","description")};
  push @SQLARGS, $ifc_id;
  my $result = $if_h->execute(@SQLARGS);
}

# Delete physical interfaces
# Params: ref to array of ph interfaces to delete
#
sub DB_dropPhInterfaces($$) {
  my $rt_id = shift;
  my $names = shift;
  my $if_h = $dbh->prepare("DELETE FROM ph_int WHERE router_id = $rt_id AND name = ?");
  foreach (@{$names}) {
    my $result = $if_h->execute($_);
  }
}


###############################################################
# Routers
#

# Get router id
# Param:
#  $hostname or $ipaddr
# TODO: look up by ip addr
sub DB_getRouterId {
  local $dbh->{RaiseError};     # Ignore errors
  my $SQL;
  if( $_[0] =~ /\d+\.\d+\.\d+\.\d+/ ) {
    $SQL = "SELECT router_id FROM routers WHERE ip_addr = \'$_[0]\' OR name = \'$_[0]\'";
  } else {
    $SQL = "SELECT router_id FROM routers WHERE name = \'$_[0]\'";
  }
  my $rref = $dbh->selectcol_arrayref($SQL);
#  print Dumper($rref);
  if (defined($rref)) {
    return $rref->[0];
  }
  return undef;
}


sub DB_getBgpRouterId {
	my $SQL = "SELECT id FROM bgp_routers WHERE ip_addr = \'$_[0]\'";
	my $rref = $dbh->selectcol_arrayref($SQL);
#  print Dumper($rref);
	if (defined($rref)) {
		return $rref->[0];
	}
	return undef;
}
# Get router ip addr
# Param:
#  router id
sub DB_getRouterIpAddr {
  local $dbh->{RaiseError};     # Ignore errors
  my $SQL = "SELECT ip_addr FROM routers WHERE router_id = \'$_[0]\'";
  my $rref = $dbh->selectcol_arrayref($SQL);
#  print Dumper($rref);
  if (defined($rref)) {
    return $rref->[0];
  }
  return undef;
}

# Get router ip addr
# Param:
#  router id
sub DB_getRouterName {
  local $dbh->{RaiseError};     # Ignore errors
  my $SQL = "SELECT name FROM routers WHERE router_id = \'$_[0]\'";
  my $rref = $dbh->selectcol_arrayref($SQL);
#  print Dumper($rref);
  if (defined($rref)) {
    return $rref->[0];
  }
  return undef;
}

# Get router vendor
# Param:
#  $hostname 
sub DB_getRouterVendor {
  local $dbh->{RaiseError};     # Ignore errors
  my $SQL;
    $SQL = "SELECT eq_vendor FROM routers WHERE name = '".$_[0]."'";
  my $rref = $dbh->selectcol_arrayref($SQL);
#  print Dumper($rref);
  if (defined($rref)) {
    return $rref->[0];
  }
  return undef;
}

# GET data to access router
# Param : router name
# 

sub DB_getRouterAccess($) {
	my $rt_id = shift;
	local $dbh->{RaiseError};     # Ignore errors
	my $SQL = "select at.name as access_type,r.eq_vendor as vendor,ar.name as attr_name ,av.value as attr_value
				from router_access ra,routers r, access a, access_type at ,attr_access aa, attr ar,attr_value av
				where ra.id_router =".$rt_id." 
				AND r.router_id = ra.id_router
				and a.id= ra.id_access
				and at.id = a.id_access_type
				and at.id=aa.id_access_type
				and aa.id_attr = ar.id
				and (av.id_attr_access = aa.id and av.id_access = a.id)";
				
	my $rref = $dbh->selectall_arrayref($SQL);
##	print "data:\n";
##    print Dumper($rref->[0]);
    return $rref;
}

# Get 
#
sub DB_getCommunity($){
	my $rt_id = shift;
	local $dbh->{RaiseError};     # Ignore errors
	my $SQL = "select sa.community_ro,sa.community_rw 
				from router_snmp_access rs,snmp_access sa 
				where rs.router_id=".$rt_id." and rs.snmp_access_id = sa.id;
";
	my $rref = $dbh->selectall_arrayref($SQL);
	 return $rref;
}

sub DB_getCountUnion($$){
	my $rt_id = shift;
	my $rt_id_c = shift;
	local $dbh->{RaiseError};     # Ignore errors
	my $SQL = "SELECT name FROM interfaces WHERE router_id =".$rt_id." UNION(SELECT name FROM interfaces where router_id=".$rt_id_c.")";
	my @query_results = map { $_->[0] } @{ $dbh->selectall_arrayref($SQL) };
	 return scalar(@query_results);
	}
	
sub DB_getCountIntersect($$){
	my $rt_id = shift;
	my $rt_id_c = shift;
	local $dbh->{RaiseError};     # Ignore errors
	my $SQL = "SELECT name FROM interfaces WHERE router_id =".$rt_id." INTERSECT(SELECT name FROM interfaces where router_id=".$rt_id_c.")";
	my @query_results = map { $_->[0] } @{ $dbh->selectall_arrayref($SQL) };
	 return scalar(@query_results);
	}
	
sub DB_getSettings($){
	my $attr_name = shift;
	
	local $dbh->{RaiseError};     # Ignore errors
	my $SQL = "SELECT value FROM general_settings WHERE name='".$attr_name."'"; 
	my $rref = $dbh->selectall_arrayref($SQL);
	
	return $rref->[0];
	}
# Add a router
# Returns router id
# Params:
#  $hostname
#  $ip addr
#  $state
sub DB_addRouter ($$$) {
  my $SQL = "INSERT INTO routers (name,ip_addr,status) VALUES (?,?,?)";
  my $sw_h = $dbh->prepare($SQL);
  my ($hostname, $ip, $stat) = @_[0..2];
  if( $hostname =~ /\d+\.\d+\.\d+\.\d+/ ) {
    $hostname = getHostPart(reverseDNS($hostname));
  }
  my $result = $sw_h->execute($hostname, $ip, $stat);
  return DB_getRouterId $_[0];
}

sub DB_addBgpRouter($$$){
	my $SQL = "INSERT INTO bgp_routers (ip_addr,status,bgp_type,autonomous_system) VALUES (?,?,?,?)";
  my $sw_h = $dbh->prepare($SQL);
  my ($rid, $bgptype,$as1) = @_[0..2];
  my $stat = 0;
  my $result = $sw_h->execute($rid,  $stat, $bgptype,$as1);
  return DB_getBgpRouterId $_[0];
}

sub DB_addConfigFile($$)
{
	my $rt_id = DB_getRouterId($_[0]);
	my $timestamp = localtime(time);
	my $filedata;
	die("Usage: $_[1] filename") unless defined($_[1]);
	die("File $_[1] doesn't exist") unless (-e $_[1]);
	my $filename = $_[1];
	open my $FH, $filename or die "Could not open file: $!";
	{
	local $/ = undef;
	$filedata = <$FH>;
	};
close $FH;
	my $sth = $dbh->prepare("INSERT INTO router_configuration(router_id,data,created) VALUES (?,?,?)");
	$sth->bind_param(1,$rt_id);
	$sth->bind_param(2, $filedata, { pg_type => DBD::Pg::PG_BYTEA });
	$sth->bind_param(3,$timestamp);
	$sth->execute();
	undef $filedata;

}

# Get hash of (router => router_id) by mask
#
sub DB_getRouters ($) {
  #local $dbh->{RaiseError};     # Ignore errors
  my $SQL = "SELECT name, router_id FROM routers WHERE name ~ \'$_[0]\'";
  my $aref = $dbh->selectall_hashref($SQL, "name" );
  if (defined($aref)) {
    #print Dumper($aref);
    #print keys %$aref;
    # TODO: optimise this
    my %tmp = map { $_ => $aref->{$_}->{'router_id'} } ( keys %$aref );
    #print Dumper(%tmp);
    return %tmp;
  }
  return undef;
}

# Get hash of (router => router_id) by mask
#
sub DB_getBgpRouters () {
  #local $dbh->{RaiseError};     # Ignore errors
  my $SQL = "SELECT ip_addr FROM bgp_routers WHERE status = 0";
  my $aref = $dbh->selectall_arrayref($SQL);
  
  if (defined($aref)) {
    return $aref;
  }
  return undef;
}

sub DB_setHostVendor($$) {
  my $rtId = shift;
  my $vendor = shift;

  my $SQL = "UPDATE routers SET eq_vendor = ? WHERE router_id = ?";
  my $if_h = $dbh->prepare($SQL);
  my $result = $if_h->execute($vendor,$rtId);
}

sub DB_setHostState($$) {
  my $rtId = shift;
  my $state = shift;

  my $SQL = "UPDATE routers SET status = ? WHERE router_id = ?";
  my $if_h = $dbh->prepare($SQL);
  my $result = $if_h->execute($state,$rtId);
}

sub DB_writeHostModel($$) {
  my $rtId = shift;
  my $model = shift;

  my $SQL = "UPDATE routers SET eq_type = ? WHERE router_id = ?";
  my $if_h = $dbh->prepare($SQL);
  my $result = $if_h->execute($model,$rtId);
}

sub DB_writeHostLocation($$) {
  my $rtId = shift;
  my $loc = shift;

  my $SQL = "UPDATE routers SET location = ? WHERE router_id = ?";
  my $if_h = $dbh->prepare($SQL);
  my $result = $if_h->execute($loc,$rtId);
}

sub DB_setHostLayer($$)
{
	my $rtId = shift;
	my $layer = shift;

  my $SQL = "UPDATE routers SET layer = ? WHERE router_id = ?";
  my $if_h = $dbh->prepare($SQL);
  my $result = $if_h->execute($layer,$rtId);
}

sub DB_updateRouterId($$){
	my $rtId = shift;
    my $ip = shift;

  my $SQL = "UPDATE routers SET ip_addr = ? WHERE router_id = ?";
  my $if_h = $dbh->prepare($SQL);
  my $result = $if_h->execute($ip,$rtId);
}

sub DB_updateAllBgpRouterStatus()
{
	my $SQL = "UPDATE bgp_routers SET status = ? ";
	my $stat = 0;
	my $if_h = $dbh->prepare($SQL);
	my $result = $if_h->execute($stat);
}

sub DB_updateBgpRouterStatus($$){
	my $rtId = shift;
    my $stat = shift;

  my $SQL = "UPDATE bgp_routers SET status = ? WHERE ip_addr = ?";
  my $if_h = $dbh->prepare($SQL);
  my $result = $if_h->execute($stat,$rtId);
}

sub DB_updateBgpRouterAS($$){
	my $id_record = shift;
	my $as1 = shift;
	my $SQL = "UPDATE bgp_routers SET autonomous_system = ? WHERE id = ?";
	my $if_h = $dbh->prepare($SQL);
	my $result = $if_h->execute($as1->[0],$id_record);
	}
###############################################################
# Links
#

# host,host,type
sub DB_writeLink ($$$) {
  my ($idA,$idB,$type) = @_[0..2];
  local $dbh->{RaiseError};     # Ignore errors

  
  # try to update
  # if fails, insert a new rec
  my $rref = $dbh->do(q{
			UPDATE network SET link_type = ?
			WHERE router_id_a = ? AND router_id_b = ?
		       }, undef, ($type, $idA, $idB));

  # print "RRef: $rref\n";
  if( $rref eq "0E0" ) {
    my $SQL = "INSERT INTO network (router_id_a,router_id_b,link_type) VALUES (?,?,?)";
    my $link_h = $dbh->prepare($SQL);
    $link_h->execute($idA,$idB,$type);
  }
}

sub DB_writeBgpLink($$$) {
	my ($idA,$idB,$type) = @_[0..2];
  local $dbh->{RaiseError};     # Ignore errors

  
  # try to update
  # if fails, insert a new rec
  my $rref = $dbh->do(q{
			UPDATE bgp_links SET link_type = ?
			WHERE (side_a = ? AND side_b = ?) OR (side_b = ? AND side_a = ?)
		       }, undef, ($type, $idA, $idB, $idA, $idB));

  # print "RRef: $rref\n";
  if( $rref eq "0E0" ) {
    my $SQL = "INSERT INTO bgp_links (side_a,side_b,link_type) VALUES (?,?,?)";
    my $link_h = $dbh->prepare($SQL);
    $link_h->execute($idA,$idB,$type);
  }
}


sub DB_replaceRouterName($$){
	my($r_id,$name)=@_[0..1];
	my $SQL = "UPDATE routers SET name = ? WHERE router_id = ?";
	my $router_n = $dbh->prepare($SQL);
	my $result = $router_n->execute($name,$r_id);
	}

sub DB_addLinkNoWrite($$$$) {
  my ($links,$from,$to,$type) = @_[0..3];
  print "Link: $from to $to\n";
  if ( $to ne $from  &&
       ! grep (/^$to:.*$/,@{${$links->{$from}}}) &&
       ! grep (/^$from:.*$/,@{${$links->{$to}}}) )
    {
      push @{${$links->{$from}}}, "$to:$type";
    }
}

sub DB_addHostNoWrite($$) {
  my $host_ips = shift;
  $host_ips->{ $_[0] } = '0.0.0.0' unless defined($host_ips->{ $_[0] });
}

sub DB_addHostIP($$$) {
  my $host_ips = shift;
  $host_ips->{ $_[0] } = $_[1];
}


# Remove host from list of hosts
# Params:
# - ref to host hash
# - host addr
#
sub DB_dropHost($$) {
  my $host_ips = shift;
  print "Removing host $_[0]\n";
  delete $host_ips->{ $_[0] } if defined($host_ips->{ $_[0] });
}

# Replace host in the list of links
# Params:
# - ref to links hash
# - host to replace
# - new host addr
sub DB_replaceHost($$$) {
  my ($links,$src,$dst) = @_[0..2];
  print "Replacing $src with $dst\n";
  return if( $src eq $dst );
  if( defined($links->{$src}) ) {
    if( defined($links->{$dst}) ) {
      push  @{${$links->{$dst}}}, @{${$links->{$src}}};
    } else {
      $links->{$dst} = $links->{$src};
    }
    delete $links->{$src};
  }
  @{${$links->{$dst}}} = grep( !/^$src:(.*)$/, @{${$links->{$dst}}});

  foreach my $host (keys %$links) {
print "$host:\n";
    map { s/^$src:(.*)$/$dst:$1/ } @{${$links->{$host}}};
  foreach (@{${$links->{$host}}}) { print "  ",$_,"\n"; }
  }
}

# Delete links to a host
# Params:host id
#
sub DB_dropLinks($) {
  my $rt_id = shift;
  my $if_h = $dbh->prepare("DELETE FROM network WHERE router_id_a = $rt_id OR router_id_b = $rt_id");
  my $result = $if_h->execute();
}


sub DB_dropRouterId($) {
  my $rt_id = shift;
  my $if_h = $dbh->prepare("DELETE FROM routers WHERE router_id = $rt_id ");
  my $result = $if_h->execute();
}

# Write hosts and links
# Params:
#  \%host_ips
#  \%links
#
sub DB_writeTopology {
  my $host_ips = shift; # host name => ip addr
  my $links = shift;    # host name => ( host name1, host name2, ...)
  my %host_ids;         # host name => router_id in database

  my %old_network;

  foreach my $h (sort keys %$host_ips) {
    print "Adding host $h ($host_ips->{$h})\n";
    $host_ids{$h} = DB_getRouterId($h);
    if (!defined($host_ids{$h})) {
      $host_ids{$h} = DB_addRouter($h, $host_ips->{$h}, "unknown");
    }
    else {
      DB_dropLinks($host_ids{$h});
    }
  }

  foreach my $hostA (sort keys %$links) {
    foreach my $Brec (sort @{${$links->{$hostA}}}) {
      my ($hostB,$linkT) = split /:/,$Brec;
      print "Adding link: $hostA <-> $hostB ($linkT)\n";
      # Check link ends
      foreach my $chkH ($hostA,$hostB) {
	if (!defined($host_ids{$chkH}) ) {
	  print "Warning: link to unknown host \'$chkH\'\n";
	  $host_ids{$chkH} = DB_getRouterId($chkH);
	  if (!defined($host_ids{$chkH})) {
	    $host_ids{$chkH} = DB_addRouter($chkH, '0.0.0.0', "unknown");
	  }
	}
      }
      DB_writeLink( $host_ids{$hostA}, $host_ids{$hostB}, $linkT );
    }
  }
}


# Write hosts and links
# Params:
#  \%host_ips
#  \%links
#
sub DB_writeTopologyBgp {
  my $host_ips = shift; # host name => ip addr
   my $links = shift;    # host name => ( host name1, host name2, ...)
  my $autonomous_systems = shift;    # host name => ( AS)
  my %host_ids;         # host name => router_id in database
  my $flag;
  my $bgp_type = 'external';
 
  foreach my $h (sort keys %$host_ips) {
    print "Adding BGP host $h ($host_ips->{$h})\n";
    $flag = DB_getBgpRouterId($host_ips->{$h});
    if(!defined($flag))
    {		
		DB_addBgpRouter($host_ips->{$h},$bgp_type,$autonomous_systems->{$h});
	}
    else {
		DB_updateBgpRouterAS($flag,$autonomous_systems->{$h});
##      DB_dropLinks($host_ids{$h});
    }
  }

  foreach my $hostA (sort keys %$links) {
    foreach my $Brec (sort @{${$links->{$hostA}}}) {
      my ($hostB,$linkT) = split /:/,$Brec;
      print "Adding link: $hostA <-> $hostB ($linkT)\n";
      # Check link ends
      foreach my $chkH ($hostA,$hostB) {
	if (!defined($host_ids{$chkH}) ) {
	  print "Warning: link to unknown host \'$chkH\'\n";
	  $host_ids{$chkH} = DB_getBgpRouterId($chkH);
	  if (!defined($host_ids{$chkH})) {
	    $host_ids{$chkH} = DB_addBgpRouter($chkH, $bgp_type, "");
	  }	  
	}
      }
      DB_writeBgpLink( $host_ids{$hostA}, $host_ids{$hostB}, $linkT );
    }
  }
 
}

# test get/add router

sub DB_TEST_getAddRouter($$) {
  my ($host,$ip_addr) = @_[0..1];;

  $dbh->trace(0);

  my $rt_id = DB_getRouterId($host);
  if (!defined($rt_id)) {
    $rt_id = DB_addRouter($host, $ip_addr, "unknown");
  }

  print "Router id ($host): $rt_id\n";
}

# exists or no especially access type for router

sub DB_isInRouterAccess($) {
     my $r_n = $_[0];
	 local $dbh->{RaiseError};     # Ignore errors
	my $SQL;
	if( $_[0] =~ /\d+\.\d+\.\d+\.\d+/ ) {
		$SQL = "SELECT count(ra.*) as ammount,r.router_id FROM router_access ra ,routers r, interfaces i 
				WHERE ((host(r.ip_addr) = \'$r_n\'  or r.name = \'$r_n\'  ) AND ra.id_router=r.router_id ) 
				OR (host(i.ip_addr) = \'$r_n\'  and ra.id_router=i.router_id and i.router_id = r.router_id) GROUP BY r.router_id ";
	}
	else
	{
		$SQL = "SELECT count(ra.*) as ammount, r.router_id as rtid FROM router_access ra ,routers r WHERE r.name = \'$r_n\' AND ra.id_router=r.router_id GROUP BY 2";
	}
    
##  print Dumper($rref);
    my $rref = $dbh->selectall_arrayref($SQL);
	return $rref;

}

sub DB_isCommunity($) {
     my $r_n = $_[0];
	 local $dbh->{RaiseError};     # Ignore errors
	my $SQL;
    $SQL = "SELECT count(*) as ammount FROM router_snmp_access WHERE router_id=".$r_n;
	
  my $rref = $dbh->selectcol_arrayref($SQL);
##  print Dumper($rref);
  
    return $rref->[0];
}

sub DB_isDueCommunity($) {
	my $r_n = $_[0];
	 local $dbh->{RaiseError};     # Ignore errors
	 my $SQL;
	 if( $_[0] =~ /\d+\.\d+\.\d+\.\d+/ ) {
		$SQL = "SELECT count(ra.*) as ammount,r.router_id FROM router_snmp_access ra ,routers r, interfaces i 
				WHERE ((host(r.ip_addr) = \'$r_n\'  or r.name = \'$r_n\'  ) AND ra.router_id=r.router_id ) 
				OR (host(i.ip_addr) = \'$r_n\'  and ra.router_id=i.router_id and i.router_id = r.router_id) GROUP BY r.router_id";
	}
	else
	{
		$SQL = "SELECT count(ra.*) as ammount,r.router_id FROM router_snmp_access ra ,routers r, interfaces i 
				WHERE ((host(r.ip_addr) = '0.0.0.0'  or r.name = '0.0.0.0'  ) AND ra.router_id=r.router_id and i.router_id = r.router_id) 
				OR (host(i.ip_addr) = '0.0.0.0'  and ra.router_id=i.router_id and i.router_id = r.router_id) GROUP BY r.router_id";
	}
	my $rref = $dbh->selectall_arrayref($SQL);
	return $rref;
	}

sub DB_isScanException($){
	my $cur_subnet = $_[0];
	local $dbh->{RaiseError};     # Ignore errors
	my $SQL;
	$SQL = "select count(*) from scan_exception where addr>>='".$cur_subnet."'";
	my $rref = $dbh->selectcol_arrayref($SQL);
	my $ret_val = 1- $rref->[0];
	return $ret_val
	}

sub DB_getCriptoKey(){
	local $dbh->{RaiseError};     # Ignore errors
	my $SQL;
    $SQL = "SELECT value FROM general_settings WHERE name='chiave'";
	
  my $rref = $dbh->selectcol_arrayref($SQL);
##  print Dumper($rref);
  
    return $rref->[0];
}

sub DB_updateDiscoveryStatus ($$) {
     my ($percent,$finish) = @_[0..1];
  
        my $SQL = "UPDATE discovery_status SET percent = ?,lastchange=now(),ended=? WHERE ended = 0";
        my $link_h = $dbh->prepare($SQL);
        $link_h->execute($percent,$finish);
}

sub DB_updateDiscoveryStatusOne ($$) {
     my ($percent,$finish) = @_[0..1];
  
        my $SQL = "UPDATE discovery_status SET percent = percent+?,lastchange=now(),ended=? WHERE ended = 0";
        my $link_h = $dbh->prepare($SQL);
        $link_h->execute($percent,$finish);
}

sub DB_insertDiscoveryStatus ($$) {
     my ($user,$interact) = @_[0..1];
	 my $percent = 0;
     my $finish = 0; 
        my $SQL = "INSERT INTO discovery_status(start,username,percent,ended,interactive) VALUES (now(),?,?,?,?)";
        my $link_h = $dbh->prepare($SQL);
        $link_h->execute($user,$percent,$finish,$interact);
}

sub DB_stopDiscovery ($$$) {
     my ($percent,$finish,$mode) = @_[0..2];
## mode 1- normal end, 0 - overdue session finishing  
		if($mode)
		{
			my $SQL = "UPDATE discovery_status SET percent = ?,finish=now(),ended=? WHERE ended = 0";
			my $link_h = $dbh->prepare($SQL);
			$link_h->execute($percent,$finish);
		}
		else
		{
			my $SQL = "UPDATE discovery_status SET finish=now(),ended=? WHERE ended = 0";
			my $link_h = $dbh->prepare($SQL);
			$link_h->execute($finish);
		}
        
}

sub DB_isOpenedDiscovery()
{
	local $dbh->{RaiseError};     # Ignore errors
	my $SQL;
	$SQL = "select count(*) from discovery_status WHERE ended = 0";
	my $rref = $dbh->selectcol_arrayref($SQL);
	my $ret_val = $rref->[0];
	return $ret_val;
}

sub DB_lastchangeDiscovery()
{
	local $dbh->{RaiseError};     # Ignore errors
	my $SQL;
	$SQL = "select lastchange from discovery_status WHERE ended = 0";
	my $rref = $dbh->selectcol_arrayref($SQL);
	my $ret_val = $rref->[0];
	return $ret_val;
}

sub DB_modeDiscovery()
{
##	local $dbh->{RaiseError};     # Ignore errors
	my $SQL;
	$SQL = "select interactive from discovery_status WHERE ended = 0";
	my $rref = $dbh->selectcol_arrayref($SQL);
	my $ret_val = $rref->[0];
	return $ret_val;
}

sub DB_percentDiscovery()
{
##	local $dbh->{RaiseError};     # Ignore errors
	my $SQL;
	$SQL = "select percent from discovery_status WHERE ended = 0";
	my $rref = $dbh->selectcol_arrayref($SQL);
	my $ret_val = $rref->[0];
	return $ret_val;
}

sub DB_getAllIntefaces(){
  my $SQL = "SELECT  router_id,ph_int_id,ifc_id,name,ip_addr,mask,descr FROM interfaces ORDER by ifc_id";
  my $aref = $dbh->selectall_hashref($SQL, "ifc_id" );
  
  if (defined($aref)) {
#	  print Dumper($aref);
#       my %tmp = map { $_ => $aref->{$_} } ( keys %$aref );
#    print Dumper(%tmp);
#    return %tmp;
return $aref;
  }
  return undef;
	}
# END { print "deleting NGNMS_DB\n"; }

1;

__END__
