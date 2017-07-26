#
# NextGen NMS
#
# NGNMS_DB.pm: database interface
#
# Copyright (C) 2002,2003 OptOSS LLC
# Copyright (C) 2014,2015 Opt/Net BV
# Author: M.Golov, T.Matselyukh
#
use warnings;
use Emsgd;

package NGNMS::OLD::DB;

use Data::Dumper;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $data);

use Data::Dumper;
use NGNMS::OLD::Util;
use DBI;
use DBD::Pg;
use DBD::Pg qw(:pg_types);
use File::Slurp;
use Emsgd qw(diag);

require Exporter;

@ISA = qw(Exporter AutoLoader);

## set the version for version checking; uncomment to use
$VERSION = 3.41;

@EXPORT = qw(&DB_open &DB_ping &DB_close &DB_vacuum
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
    &DB_addBgpRouter &DB_getBgpRouterId &DB_getHostVendor
    &DB_writeTopologyBgp &DB_updateBgpRouterStatus &DB_getRoutersWithoutLinks
    &DB_updateAllBgpRouterStatus &DB_updateBgpRouterAS &DB_writeBgpLink
    &DB_updateLinkA &DB_updateLinkB &DB_getRouterVendorById &DB_setHostVendorByIP
    &DB_getInterfacesAll &DB_getMinRouterIdentifier &DB_checkVersion
    &DB_getRoutersWithProtocol &DB_clearRouterPeers
    );

# your exported package globals go here,
# as well as any optionally exported functions
@EXPORT_OK = qw($data);

# print "loading NGNMS_DB\n";

# data

$data = "my data";

my $verbose = $ENV{"NGNMS_DEBUG"} || 0;

# Preloaded methods

my DBI $dbh;
my $DB_host = $ENV{NGNMS_DB_HOST} || 'localhost';
my $DB_name = $ENV{NGNMS_DB} || 'ngnms';
my $DB_user = $ENV{NGNMS_DB_USER} || 'ngnms';
my $DB_passwd = $ENV{NGNMS_DB_PASSWORD} || 'ngnms';
my $DB_port = $ENV{NGNMS_DB_PORT} || '5432';


my $Log = NGNMS::Log4->new();
my $logger = $Log->get_new_category_logger(__PACKAGE__);

# uncomment to enable debug output in this module
#
my $debug = 1;

sub new {
    my ($class, $dbhi) = @_;
    #    Emsgd::diag($class);

    if (defined( $dbhi )) {
        #        Emsgd::diag($dbhi);
        $dbh = $dbhi;
    } else {
        DB_open( $DB_name, $DB_user, $DB_passwd, $DB_port, $DB_host );
    }
    return bless { }, $class;

}
sub getDbh {
    return $dbh;
}
sub test_db_clean() {
    local $dbh->{PrintWarn};
    if ($DB_name ne 'ngnms_test') {
        diag 'tryng to clear NON-TEST DB';
        die;
    }
    $dbh->do( 'truncate table routers cascade ' );
}


sub DB_open {
    $DB_name = $_[0] if defined( $_[0] );
    $DB_user = $_[1] if defined( $_[1] );
    $DB_passwd = $_[2] if defined( $_[2] );
    $DB_port = $_[3] if defined( $_[3] );
    $DB_host = $_[4] if defined( $_[4] );
    #  print "#Debug db=".$DB_name.":"."user=".$DB_user.":"."passwd=".$DB_passwd.":"."port=".$DB_port."\n";
    $dbh = DBI->connect( "dbi:Pg:dbname=".$DB_name.";host=".$DB_host.";port=".$DB_port,
        $DB_user, $DB_passwd,
        { AutoCommit => 1, RaiseError => 0, PrintError => 0,
            HandleError=>sub{$logger->error(shift);}
        } );

}

sub DB_ping{
    return $dbh && $dbh->ping;
}
sub DB_close {
    $dbh->disconnect();
}

sub DB_vacuum {
    my $q = $dbh->prepare( "VACUUM ANALYZE" );
    $q->execute();
}

# "park" all old recs for this router
# router_id

sub DB_startSwInfo ($) {
    my $rt_id = shift;
    my $SQL = "DELETE FROM inv_sw WHERE router_id = ?";
    my $if_h = $dbh->prepare( $SQL );
    my $result = $if_h->execute( $rt_id );
}

sub DB_writeSwInfo($*) {
    my $rt_id = shift;
    my $sw_info = shift;
    print Dumper( %$sw_info ) if $verbose;
    my $SQL = "INSERT INTO inv_sw (router_id,sw_item,sw_name,sw_version) VALUES (?,?,?,?)";
    my $sw_h = $dbh->prepare( $SQL );

    my @SQLARGS = @$sw_info{("sw_item", "sw_name", "sw_ver")};
    my $result = $sw_h->execute( $rt_id, @SQLARGS );
    %$sw_info = (    "sw_item" => undef,
        "sw_name"              => undef,
        "sw_ver"               => undef );
}

sub DB_startHwInfo ($) {
    my $rt_id = shift;
    my $SQL = "DELETE FROM inv_hw WHERE router_id = ?";
    my $if_h = $dbh->prepare( $SQL );
    my $result = $if_h->execute( $rt_id );
}

sub DB_writeHwInfo($*) {
    my $rt_id = shift;
    my $hw_info = shift;
    my $SQL = "INSERT INTO inv_hw (router_id,hw_item,hw_name,hw_version,hw_amount) VALUES (?,?,?,?,?)";
    my $sw_h = $dbh->prepare( $SQL );

    my @SQLARGS = @$hw_info{("hw_item", "hw_name", "hw_ver", "hw_amount")};
    my $result = $sw_h->execute( $rt_id, @SQLARGS );
    #print Dumper(%$hw_info);
    %$hw_info = (    "hw_item" => undef,
        "hw_name"              => undef,
        "hw_ver"               => undef,
        "hw_amount"            => undef );
}

###############################################################
# Logical interfaces
#

# Get list of ifc names by rt_id
sub DB_getInterfaces($) {
    my $rt_id = shift;
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL = "SELECT name FROM interfaces WHERE router_id = $rt_id";
    my $rref = $dbh->selectcol_arrayref( $SQL );
    # print Dumper($rref);
    return $rref;
}

sub DB_getInterfacesAll($) {
    my $rt_id = shift;
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL = "SELECT name,ip_addr,mask,ifc_id FROM interfaces WHERE router_id = $rt_id";
    my $rref = $dbh->selectall_arrayref( $SQL );
    ## print Dumper($rref);
    return $rref;
}

# Get list of duplicate hostname
sub DB_getDuplicateHostname() {
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL = "SELECT name,eq_vendor,eq_type FROM routers GROUP BY name,eq_vendor,eq_type HAVING(count(*))>1";
    my $rref = $dbh->selectcol_arrayref( $SQL );
    # print Dumper($rref);
    return $rref;
}

# Get list of all hostname
sub DB_getAllHostname() {
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL = "SELECT DISTINCT name FROM routers ORDER BY name";
    my $rref = $dbh->selectcol_arrayref( $SQL );
    # print Dumper($rref);
    return $rref;
}


# Get list of  router_id for duplicate hostname
sub DB_getRouterIdDuplicateHostname($) {
    my $hname = shift;
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL = "SELECT router_id FROM routers where name='".$hname."' order by router_id";
    my $rref = $dbh->selectcol_arrayref( $SQL );
    # print Dumper($rref);
    return $rref;
}

sub DB_getMinRouterIdentifier($) {
    my $hname = shift;
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL = "select min(router_id) from routers  where name='".$hname."' and is_router_identifier = 1";
    my $rref = $dbh->selectcol_arrayref( $SQL );
    #  print Dumper($rref);
    if (defined( $rref )) {
        return $rref->[0];
    }
    return undef;
}

sub DB_getMinRouterRA($) {
    my $hname = shift;
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL = "select min(ra.id_router) from routers r,router_access ra where r.name='".$hname."' and ra.id_router=r.router_id ";
    my $rref = $dbh->selectcol_arrayref( $SQL );
    #  print Dumper($rref);
    if (defined( $rref )) {
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
    my $rref = $dbh->selectcol_arrayref( $SQL );
    #  print Dumper($rref);
    if (defined( $rref )) {
        return $rref->[0];
    }
    return undef;
}

# Get ifc id by rt_id and name
sub DB_getInterfaceRouterId($) {
    my $addr = shift;

    local $dbh->{RaiseError};     # Ignore errors
    my $SQL = "SELECT router_id FROM interfaces WHERE host(ip_addr) = \'$addr\'";
    my $rref = $dbh->selectcol_arrayref( $SQL );
    #  print Dumper($rref);
    if (defined( $rref )) {
        return $rref->[0];
    }
    return undef;
}

sub DB_writeInterface($$*) {
    my $rt_id = shift;
    my $ph_int_id = shift;
    my $ifc = shift;
    my $ifc_id = DB_getInterfaceId( $rt_id, $ph_int_id, $ifc->{"interface"}, $ifc->{"ip address"} );
    if (!defined( $ifc_id )) {
        # easy - insert new ifc
        my $SQL = "INSERT INTO interfaces (router_id,ph_int_id,name,ip_addr,mask,descr) VALUES (?,?,?,?,?,?)";
        my $if_h = $dbh->prepare( $SQL );

        my @SQLARGS = @$ifc{("interface", "ip address", "mask", "description")};
        my $result = $if_h->execute( $rt_id, $ph_int_id, @SQLARGS );
        return $result;
    }

    # hard - update
    my $SQL = "UPDATE interfaces SET ip_addr = ?, mask = ?, descr = ? WHERE ifc_id = ?";
    my $if_h = $dbh->prepare( $SQL );

    my @SQLARGS = @$ifc{("ip address", "mask", "description")};
    push @SQLARGS, $ifc_id;
    my $result = $if_h->execute( @SQLARGS );
}
#=for
#    EXREAME ONLY !! TESTED WITHOUT ROUTING PROTOCOS
#    Mark interfaces (descr = PollNotFound ) by router_id before poll-host;
#    call to DB_writeInterface will update descr field at least to empty state
#    After router polled we could delete logical interfaces with PollNotFound
#
#    THis should be done this way cause IP for same interface could be changed
#    NGNMS_DB::DB_writeInterface do checks by if_name && if_ip so old interace will not be updated
#    (we could have multihomed interfaces, so this is OK for now)
#    and NGNMS_DB::DB_dropInterfaces do deletion by interface name only
#    so we will have in DB 2 interfaces with same name but diffirent IP
#    and we can not delete not-found by name.
#
#    after poll-host prsed interfaces, call to DB_markInterfacesToBePolled
#    to delete interfaces not touched by  NGNMS_DB::DB_writeInterface
#=cut
sub DB_markInterfacesToBePolled($) {
    my $rt_id = shift;
    my $if_h = $dbh->prepare( "update  interfaces set descr='#PollNotFound#' WHERE router_id = $rt_id" );
    $if_h->execute();
}
sub DB_markPhInterfacesToBePolled($) {
    my $rt_id = shift;
    my $if_h = $dbh->prepare( "update  ph_int set descr='#PollNotFound#' WHERE router_id = $rt_id" );
    $if_h->execute();
}
#=for
# see DB_markInterfacesToBePolled for usage
#=cut
sub DB_deleteInterfacesPolledButNotFound($) {
    my $rt_id = shift;
    my $if_h = $dbh->prepare( "delete from interfaces WHERE  descr='#PollNotFound#'  and  router_id = $rt_id" );
    $if_h->execute();
}
sub DB_deletePhInterfacesPolledButNotFound($) {
    my $rt_id = shift;
    my $if_h = $dbh->prepare( "delete from ph_int WHERE  descr='#PollNotFound#'  and  router_id = $rt_id" );
    $if_h->execute();
}
# Delete logical interfaces
# Params: ref to array of log interfaces to delete
#
sub DB_dropInterfaces($$) {
    my $rt_id = shift;
    my $names = shift;
    my $if_h = $dbh->prepare( "DELETE FROM interfaces WHERE router_id = $rt_id AND name = ?" );
    foreach (@{$names}) {
        my $result = $if_h->execute( $_ );
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
    my $rref = $dbh->selectcol_arrayref( $SQL );
    # print Dumper($rref);
    return $rref;
}

# Get ifc id by rt_id and name
sub DB_getPhInterfaceId($$) {
    my $rt_id = shift;
    my $ifc_n = shift;
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL = "SELECT ph_int_id FROM ph_int WHERE router_id = $rt_id AND name = \'$ifc_n\'";
    my $rref = $dbh->selectcol_arrayref( $SQL );
    #  print Dumper($rref);
    if (defined( $rref )) {
        return $rref->[0];
    }
    return undef;
}
#=for
#    inserter new phInt or updates existes
#
#    return ph_int_id on success, undef on error
#=cut
sub DB_writePhInterface($*) {
    my $rt_id = shift;
    my $ifc = shift;
    my $ifc_id = DB_getPhInterfaceId( $rt_id, $ifc->{"interface"} );
    if (!defined( $ifc_id )) {
        # easy - insert new ifc, reserve new_id to be returned for transaction_safe approach
        my $new_ph_in_id = $dbh->selectcol_arrayref( "select nextval('ph_int_ph_int_id_seq')" );
        $new_ph_in_id = @$new_ph_in_id[0];
        my $SQL = "INSERT INTO ph_int (ph_int_id,router_id,name,state,condition,speed,descr) VALUES (".$new_ph_in_id.",?,?,?,?,?,?)";
        my $if_h = $dbh->prepare( $SQL );

        my @SQLARGS = @$ifc{("interface", "state", "condition", "speed", "description")};
        #        print Dumper( @SQLARGS ) if $verbose;;
        my $result = $if_h->execute( $rt_id, @SQLARGS );
        return  $result ? $new_ph_in_id : undef;
    }

    # hard - update
    my $SQL = "UPDATE ph_int SET state = ?, condition = ?, speed = ?, descr = ? WHERE ph_int_id = ?";
    my $if_h = $dbh->prepare( $SQL );

    my @SQLARGS = @$ifc{("state", "condition", "speed", "description")};
    push @SQLARGS, $ifc_id;
    my $result = $if_h->execute( @SQLARGS );
    return $result ? $ifc_id : undef;
}

# Delete physical interfaces
# Params: ref to array of ph interfaces to delete
#
sub DB_dropPhInterfaces($$) {
    my $rt_id = shift;
    my $names = shift;
    my $if_h = $dbh->prepare( "DELETE FROM ph_int WHERE router_id = $rt_id AND name = ?" );
    foreach (@{$names}) {
        my $result = $if_h->execute( $_ );
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
    if ($_[0] =~ /\d+\.\d+\.\d+\.\d+/) {
        $SQL = "SELECT router_id FROM routers WHERE ip_addr = \'$_[0]\' OR name = \'$_[0]\'";
    } else {
        $SQL = "SELECT router_id FROM routers WHERE name = \'$_[0]\'";
    }
    my $rref = $dbh->selectcol_arrayref( $SQL );
    #  print Dumper($rref);
    if (defined( $rref )) {
        return $rref->[0];
    }
    return undef;
}


sub DB_getHostVendor {
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL;
    if ($_[0] =~ /\d+\.\d+\.\d+\.\d+/) {
        $SQL = "SELECT eq_vendor FROM routers WHERE ip_addr = \'$_[0]\' OR name = \'$_[0]\'";
    } else {
        $SQL = "SELECT eq_vendor FROM routers WHERE name = \'$_[0]\'";
    }

    my $rref = $dbh->selectcol_arrayref( $SQL );
    if (defined( $rref )) {
        return $rref->[0];
    }
    return undef;
}

sub DB_getBgpRouterId {
    my $SQL = "SELECT id FROM bgp_routers WHERE ip_addr = \'$_[0]\'";
    my $rref = $dbh->selectcol_arrayref( $SQL );
    #  print Dumper($rref);
    if (defined( $rref )) {
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
    my $rref = $dbh->selectcol_arrayref( $SQL );
    #  print Dumper($rref);
    if (defined( $rref )) {
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
    my $rref = $dbh->selectcol_arrayref( $SQL );
    #  print Dumper($rref);
    if (defined( $rref )) {
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
    my $rref = $dbh->selectcol_arrayref( $SQL );
    #  print Dumper($rref);
    if (defined( $rref )) {
        return $rref->[0];
    }
    return undef;
}

# Get router vendor
# Param:
#  $router_id
sub DB_getRouterVendorById {
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL;
    $SQL = "SELECT eq_vendor FROM routers WHERE router_id = ".$_[0];
    my $rref = $dbh->selectcol_arrayref( $SQL );
    #  print Dumper($rref);
    if (defined( $rref )) {
        return $rref->[0];
    }
    return undef;
}
#=for
#    GET data to access BGP router
#    Param : router name
#=cut
##@deprecated
#sub DB_getBGPRouterAccess($) {
#    my $rt_id = shift;
#    local $dbh->{RaiseError};     # Ignore errors
#    my $SQL = "
#    select
#        at.name as access_type,
#        null as vendor,
#        ar.name as attr_name ,
#        av.value as attr_value
#        from bgp_router_access ra
#        join bgp_routers r on (r.id = ra.id_router)
#        join  access a on (a.id= ra.id_access)
#        join  access_type at on(at.id = a.id_access_type)
#        join attr_access aa on (at.id=aa.id_access_type)
#        join attr ar on (aa.id_attr = ar.id)
#        join attr_value av on (av.id_attr_access = aa.id and av.id_access = a.id)
#        where
#        ra.id_router =".$rt_id."
#    ";
#
#    my $rref = $dbh->selectall_arrayref( $SQL );
#    return $rref;
#}
#=for
#    GET data to access router
#    Param : router name
#=cut
sub DB_getRouterAccess($) {
    my $rt_id = shift;
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL = "
    select
        at.name as access_type,
        r.eq_vendor as vendor,
        ar.name as attr_name ,
        av.value as attr_value
        from router_access ra
        join routers r on (r.router_id = ra.id_router)
        join  access a on (a.id= ra.id_access)
        join  access_type at on(at.id = a.id_access_type)
        join attr_access aa on (at.id=aa.id_access_type)
        join attr ar on (aa.id_attr = ar.id)
        join attr_value av on (av.id_attr_access = aa.id and av.id_access = a.id)
        where
        ra.id_router =".$rt_id."
    ";

    my $rref = $dbh->selectall_arrayref( $SQL );
    ##	print "data:\n";
    ##    print Dumper($rref->[0]);
    return $rref;
}

# Get 
#
sub DB_getCommunity($) {
    my $rt_id = shift;
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL = "select sa.community_ro,sa.community_rw
        from router_snmp_access rs,snmp_access sa
        where rs.router_id=".$rt_id." and rs.snmp_access_id = sa.id;";
    my $rref = $dbh->selectall_arrayref( $SQL );
    return $rref;
}

sub DB_getCountUnion($$) {
    my $rt_id = shift;
    my $rt_id_c = shift;
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL = "SELECT name FROM interfaces WHERE router_id =".$rt_id." UNION(SELECT name FROM interfaces where router_id=".$rt_id_c.")";
    my @query_results = map {
        $_->[0]
    } @{ $dbh->selectall_arrayref( $SQL ) };
    return scalar( @query_results );
}

sub DB_getCountIntersect($$) {
    my $rt_id = shift;
    my $rt_id_c = shift;
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL = "SELECT name FROM interfaces WHERE router_id =".$rt_id." INTERSECT(SELECT name FROM interfaces where router_id=".$rt_id_c.")";
    my @query_results = map {
        $_->[0]
    } @{ $dbh->selectall_arrayref( $SQL ) };
    return scalar( @query_results );
}

sub DB_getSettings($) {
    my $attr_name = shift;

    local $dbh->{RaiseError};     # Ignore errors
    my $SQL = "SELECT value FROM general_settings WHERE name='".$attr_name."'";
    my $rref = $dbh->selectall_arrayref( $SQL );

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
    my $sw_h = $dbh->prepare( $SQL );
    my ($hostname, $ip, $stat) = @_[0 .. 2];
    if ($hostname =~ /\d+\.\d+\.\d+\.\d+/) {
        $hostname = getHostPart( reverseDNS( $hostname ) );
    }
    #  Emsgd::print($ip);
    my $result = $sw_h->execute( $hostname, $ip, $stat );
    return DB_getRouterId $_[0];
}
sub DB_writeRouterPeers($) {
    my $params = shift;
#    diag($params);
    my $ cnt = $dbh->selectrow_array( "
        SELECT count(*) FROM router_peers
         WHERE router_id = ?
         AND router_peer_id = ?
         AND peer_type =?
         AND peer_info =?
    ", undef, ($params->{router_id}, $params->{router_peer_id}, $params->{peer_type}, $params->{peer_info}) );
    return if $cnt;
    $dbh->do( "
     INSERT INTO router_peers
      (router_id,router_peer_id,peer_type,peer_info,description)
      VALUES (?,?,?,?,?)
    ", undef, ($params->{router_id}, $params->{router_peer_id}, $params->{peer_type}, $params->{peer_info}, $params->{description}) );
}
sub DB_addBgpRouter($$$$$) {
    #    Emsgd::diag(\@_);
    my ($rid, $bgptype, $as1, $BGP_roouter_identifier, $stat) = @_[0 .. 4];
    my $SQL = "INSERT INTO bgp_routers (ip_addr,status,bgp_type,autonomous_system,bgp_router_identifier) VALUES (?,?,?,?,?)";
    my $sw_h = $dbh->prepare( $SQL );

    my $st = 0;
    #    my $as = $as1 ne '' && defined $as1->[0] ? $as1->[0] : '';
    my $result = $sw_h->execute( $rid, $st, $bgptype, $as1, $BGP_roouter_identifier );
    return DB_getBgpRouterId $_[0];
}

sub DB_addConfigFile($$)
{
    my $rt_id = DB_getRouterId( $_[0] );
    my $timestamp = localtime( time );
    my $filedata;
    die( "Usage: $_[1] filename" ) unless defined( $_[1] );
    die( "File $_[1] doesn't exist" ) unless (-e $_[1]);
    my $filename = $_[1];
    #    open my $FH, $filename or die "Could not open file: $!";
    #    {
    #        local $/ = undef;
    #        $filedata = < $FH >;
    #    };
    #    close $FH;
    $filedata = read_file $filename or die "Could not open file: $!";
    #    Emsgd::pp('about to write file to DB:'.$filedata);
    my $sth = $dbh->prepare( "INSERT INTO router_configuration(router_id,data,created) VALUES (?,?,?)" );
    $sth->bind_param( 1, $rt_id );
    $sth->bind_param( 2, $filedata, { pg_type => DBD::Pg::PG_BYTEA } );
    $sth->bind_param( 3, $timestamp );
    $sth->execute();
    undef $filedata;

}

# Get hash of (router => router_id) by mask
#
sub DB_getRouters ($) {
    #local $dbh->{RaiseError};     # Ignore errors
    my $SQL = "SELECT name, router_id FROM routers WHERE name ~ \'$_[0]\'";
    my $aref = $dbh->selectall_hashref( $SQL, "name" );
    if (defined( $aref )) {
        #print Dumper($aref);
        #print keys %$aref;
        # TODO: optimise this
        my %tmp = map {
            $_ => $aref->{$_}->{'router_id'}
        } ( keys %$aref );
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
    my @aref = @{$dbh->selectall_arrayref( $SQL )};
    if (@aref > 0) {
        my @flat = map{$_->[0]} @aref;
        return \@flat;
    }
    return undef;
}

# Get routers with OFPF,ISIS, BGP that not in GBP routers stabe
#so they could be audited withon being BGP neigbor to any seed hosts
#this is quick fix
#TODO add is_router function to PollHost, remove BGP-only discovery and audit
#       implement auto-discovery via all Routing protocols
sub DB_getRoutersWithProtocol (){
    #@inject PGSQL
    my $SQL = "
SELECT DISTINCT r.ip_addr
FROM (
       SELECT t.router_id AS rid
       FROM router_peers t
       UNION
       SELECT router_peer_id AS rid
       FROM router_peers

     ) AS t
  join routers r on (r.router_id = t.rid)
WHERE rid NOT IN (
  SELECT r.router_id
  FROM
    routers r
    LEFT OUTER JOIN bgp_routers b ON (r.ip_addr = b.ip_addr)
  WHERE b.id IS NOT NULL
)
    ";
    my @aref = @{$dbh->selectall_arrayref( $SQL )};
    if (@aref > 0) {
        my @flat = map{$_->[0]} @aref;
        return \@flat;
    }
    return undef;
}

sub DB_getRoutersWithoutLinks() {
    my $SQL = "select routers.router_id from routers, network where router_id_a!=router_id and router_id_b!=router_id and status='up'";
    my $aref = $dbh->selectall_arrayref( $SQL );

    if (defined( $aref )) {
        return $aref;
    }
    return undef;
}

sub DB_setHostVendor($$) {
    my $rtId = shift;
    my $vendor = shift;

    my $SQL = "UPDATE routers SET eq_vendor = ? WHERE router_id = ?";
    my $if_h = $dbh->prepare( $SQL );
    my $result = $if_h->execute( $vendor, $rtId );
}

sub DB_setHostVendorByIP($$) {
    my $rtId = shift;
    my $vendor = shift;

    my $SQL = "UPDATE routers SET eq_vendor = ? WHERE ip_addr = ?";
    my $if_h = $dbh->prepare( $SQL );
    my $result = $if_h->execute( $vendor, $rtId );
}

sub DB_setHostState($$) {
    my $rtId = shift;
    my $state = shift;

    my $SQL = "UPDATE routers SET status = ? WHERE router_id = ?";
    my $if_h = $dbh->prepare( $SQL );
    my $result = $if_h->execute( $state, $rtId );
}

sub DB_writeHostModel($$) {
    my $rtId = shift;
    my $model = shift;

    my $SQL = "UPDATE routers SET eq_type = ? WHERE router_id = ?";
    my $if_h = $dbh->prepare( $SQL );
    my $result = $if_h->execute( $model, $rtId );
}

sub DB_writeHostLocation($$) {
    my $rtId = shift;
    my $loc = shift;

    my $SQL = "UPDATE routers SET location = ? WHERE router_id = ?";
    my $if_h = $dbh->prepare( $SQL );
    my $result = $if_h->execute( $loc, $rtId );
}

sub DB_setHostLayer($$)
{
    my $rtId = shift;
    my $layer = shift;

    my $SQL = "UPDATE routers SET layer = ? WHERE router_id = ?";
    my $if_h = $dbh->prepare( $SQL );
    my $result = $if_h->execute( $layer, $rtId );
}
sub DB_updedteRouterIndetifier($$) {
    my $rtId = shift;
    my $is_identifier = shift;

    my $SQL = "UPDATE routers SET is_router_identifier = ? WHERE router_id = ?";
    my $if_h = $dbh->prepare( $SQL );
    my $result = $if_h->execute( $is_identifier, $rtId );
}
sub DB_updateRouterId($$) {
    my $rtId = shift;
    my $ip = shift;

    my $SQL = "UPDATE routers SET ip_addr = ? WHERE router_id = ?";
    my $if_h = $dbh->prepare( $SQL );
    my $result = $if_h->execute( $ip, $rtId );
}
sub DB_clearRouterPeers(){
    my $SQL = "truncate table  router_peers";
    my $if_h = $dbh->prepare( $SQL );
    my $result = $if_h->execute( );
}
sub DB_updateAllBgpRouterStatus()
{
    my $SQL = "UPDATE bgp_routers SET status = ? ";
    my $stat = 0;
    my $if_h = $dbh->prepare( $SQL );
    my $result = $if_h->execute( $stat );
}

sub DB_updateBgpRouterStatus($$) {
    my $rtId = shift;
    my $stat = shift;

    my $SQL = "UPDATE bgp_routers SET status = ? WHERE ip_addr = ?";
    #    Emsgd::diag "UPDATE bgp_routers SET status = $stat WHERE ip_addr = $rtId";
    my $if_h = $dbh->prepare( $SQL );
    my $result = $if_h->execute( $stat, $rtId );
}

sub DB_updateBgpRouterAS($$$) {
    my $id_record = shift;
    my $as1 = shift;
    my $bgp_router_identifier = shift;
    my ($result, $SQL, $if_h);
    if (defined $bgp_router_identifier) {
        $SQL = "UPDATE bgp_routers SET bgp_router_identifier = ?, autonomous_system = ? WHERE id = ?";
        $if_h = $dbh->prepare( $SQL );
        $result = $if_h->execute( $bgp_router_identifier, $as1->[0], $id_record );
    } else {
        $SQL = "UPDATE bgp_routers SET autonomous_system = ? WHERE id = ?";
        $if_h = $dbh->prepare( $SQL );
        $result = $if_h->execute( $as1->[0], $id_record );

    }

    return $result;

}
###############################################################
# Links
#

# host,host,type
sub DB_writeLink ($$$) {
    my ($idA, $idB, $type) = @_[0 .. 2];
    local $dbh->{RaiseError};     # Ignore errors


    # try to update
    # if fails, insert a new rec
    my $rref = $dbh->do( q{
			UPDATE network SET link_type = ?
            WHERE router_id_a = ? AND router_id_b = ?
            }, undef, ($type, $idA, $idB) );

    # print "RRef: $rref\n";
    if ($rref eq "0E0") {
        my $SQL = "INSERT INTO network (router_id_a,router_id_b,link_type) VALUES (?,?,?)";
        my $link_h = $dbh->prepare( $SQL );
        $link_h->execute( $idA, $idB, $type );
    }
}


sub DB_writeBgpLink($$$) {
    my ($idA, $idB, $type) = @_[0 .. 2];
    local $dbh->{RaiseError};     # Ignore errors


    # try to update
    # if fails, insert a new rec
    my $rref = $dbh->do( q{
			UPDATE bgp_links SET link_type = ?
            WHERE (side_a = ? AND side_b = ?) OR (side_b = ? AND side_a = ?)
            }, undef, ($type, $idA, $idB, $idA, $idB) );

    # print "RRef: $rref\n";
    if ($rref eq "0E0") {
        my $SQL = "INSERT INTO bgp_links (side_a,side_b,link_type) VALUES (?,?,?)";
        my $link_h = $dbh->prepare( $SQL );
        $link_h->execute( $idA, $idB, $type );
    }
}


sub DB_replaceRouterName($$) {
    my ($r_id, $name) = @_[0 .. 1];
    my $SQL = "UPDATE routers SET name = ? WHERE router_id = ?";
    my $router_n = $dbh->prepare( $SQL );
    my $result = $router_n->execute( $name, $r_id );
}

sub DB_addLinkNoWrite($$$$) {
    my ($links, $from, $to, $type) = @_[0 .. 3];

    #    Emsgd::diag( \@_ ) unless $from;

    $logger->debug( "Link: $from to $to");
    if ($to ne $from &&
        !grep (/^$to:.*$/, @{${$links->{$from}}}) &&
        !grep (/^$from:.*$/, @{${$links->{$to}}}))
    {
        push @{${$links->{$from}}}, "$to:$type";
    }
}

sub DB_addHostNoWrite($$) {
    my $host_ips = shift;
    $host_ips->{ $_[0] } = '0.0.0.0' unless defined( $host_ips->{ $_[0] } );
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
    #    diag(\@_,'DB_dropHost',1);
    my $host_ips = shift;
    $logger->debug( "Removing host $_[0]");
    delete $host_ips->{ $_[0] } if defined( $host_ips->{ $_[0] } );
}

# Replace host in the list of links
# Params:
# - ref to links hash
# - host to replace
# - new host addr
sub DB_replaceHost($$$) {
    #    diag(\@_,'DB_replaceHost',1);
    my ($links, $src, $dst) = @_[0 .. 2];
    $logger->debug( "Replacing $src with $dst");
    return if ( $src eq $dst );
    if (defined( $links->{$src} )) {
        if (defined( $links->{$dst} )) {
            push  @{${$links->{$dst}}}, @{${$links->{$src}}};
        } else {
            $links->{$dst} = $links->{$src};
        }
        delete $links->{$src};
    }
    @{${$links->{$dst}}} = grep( !/^$src:(.*)$/, @{${$links->{$dst}}});

    foreach my $host (keys %$links) {
        $logger->debug( "links for $host:");
        map {
            s/^$src:(.*)$/$dst:$1/
        } @{${$links->{$host}}};
        foreach (@{${$links->{$host}}}) {
            $logger->debug( " link ", $_);
        }
    }
}

# Delete links to a host
# Params:host id
#
sub DB_dropLinks($) {
    my $rt_id = shift;
    my $if_h = $dbh->prepare( "DELETE FROM network WHERE router_id_a = $rt_id OR router_id_b = $rt_id" );
    my $result = $if_h->execute();
}


sub DB_dropRouterId($) {
    #    diag(\@_,'DB_dropRouterId',1);

    my $rt_id = shift;
    my $if_h = $dbh->prepare( "DELETE FROM routers WHERE router_id = $rt_id " );
    my $result = $if_h->execute();
}

sub DB_updateLinkB($$) {
    my $rt_id = shift;
    my $parent_rt_id = shift;
    my $SQL_UP;
    my $router_n;
    my $result;

    local $dbh->{RaiseError};     # Ignore errors
    my $SQL = "select router_id_a from network where router_id_b=\'$rt_id\' and router_id_a!=\'$parent_rt_id\' EXCEPT(select router_id_a from network where router_id_b=\'$parent_rt_id\' UNION SELECT router_id_b FROM network WHERE router_id_a=\'$parent_rt_id\')";
    my $rref = $dbh->selectcol_arrayref( $SQL );
    foreach my $rt_id_link(@{$rref})
    {
        print "Update Link B $rt_id -> $rt_id_link"."\n" if $verbose;;
        $SQL_UP = "UPDATE network set router_id_b = ?  WHERE where router_id_b= ? AND router_id_a = ? ";
        $router_n = $dbh->prepare( $SQL_UP );
        $result = $router_n->execute( $parent_rt_id, $rt_id, $rt_id_link );
    }
    ##	print "LINK A:".$rt_id."\n";
    ##	print Dumper($rref);
    return $rref;
}

sub DB_updateLinkA($$) {
    my $rt_id = shift;
    my $parent_rt_id = shift;
    my $SQL_UP;
    my $router_n;
    my $result;
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL = "select router_id_b from network where router_id_a=\'$rt_id\' and router_id_b!=\'$parent_rt_id\' EXCEPT(select router_id_a from network where router_id_b=\'$parent_rt_id\' UNION SELECT router_id_b FROM network WHERE router_id_a=\'$parent_rt_id\')";
    my $rref = $dbh->selectcol_arrayref( $SQL );
    foreach my $rt_id_link(@{$rref})
    {
        print "Update Link A $rt_id -> $rt_id_link"."\n" if $verbose;;
        $SQL_UP = "UPDATE network set router_id_a = ? WHERE where router_id_a= ? AND router_id_b = ? ";
        $router_n = $dbh->prepare( $SQL_UP );
        $result = $router_n->execute( $parent_rt_id, $rt_id, $rt_id_link );
    }
    ##	print "LINK B:".$rt_id."\n";
    ##	print Dumper($rref);
    return $rref;
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
        $logger->debug( "Adding host $h ($host_ips->{$h})" );
        $host_ids{$h} = DB_getRouterId( $h );
        if (!defined( $host_ids{$h} )) {
            $host_ids{$h} = DB_addRouter( $h, $host_ips->{$h}, "unknown" );
        }
        else {
            DB_dropLinks( $host_ids{$h} );
        }
    }

    foreach my $hostA (sort keys %$links) {
        foreach my $Brec (sort @{${$links->{$hostA}}}) {
            my ($hostB, $linkT) = split /:/, $Brec;
            $logger->debug( "Adding link: $hostA <-> $hostB ($linkT)");
            # Check link ends
            foreach my $chkH ($hostA, $hostB) {
                if (!defined( $host_ids{$chkH} )) {
                    $logger->debug( "Warning: link to unknown host \'$chkH\'");
                    $host_ids{$chkH} = DB_getRouterId( $chkH );
                    if (!defined( $host_ids{$chkH} )) {
                        $host_ids{$chkH} = DB_addRouter( $chkH, '0.0.0.0', "unknown" );
                    }
                }
            }
            DB_writeLink( $host_ids{$hostA}, $host_ids{$hostB}, $linkT );
            my $type_full = undef;
            my $peer_info = '';
#            diag({
#                router_id          => $host_ids{$hostA},
#                router_peer_id =>  $host_ids{$hostB},
#                peer_type      => $type_full,
#                peer_info      => $peer_info,
#                description     => '',
#                linkT => $linkT,
#            });
            if ($linkT eq 'P') {
                $type_full = 'OSPF';
                $peer_info = 'p2p';
            }
            if ($linkT eq 'B') {
                $type_full = 'OSPF';
                $peer_info = 'broadcast';
            }
            if (defined $type_full) {
                DB_writeRouterPeers(
                    {
                        router_id          => $host_ids{$hostA},
                            router_peer_id =>  $host_ids{$hostB},
                            peer_type      => $type_full,
                            peer_info      => $peer_info,
                            description     => '',
                    }
                );
            }
        }
    }
}


# Write hosts and links
# Params:
#  \%host_ips
#  \%links
#
sub DB_writeTopologyBgp {
    #    Emsgd::diag(\@_);
    my $host_ips = $_[0]; # host name => ip addr
    my $links = $_[1];    # host name => ( host name1, host name2, ...)
    my $autonomous_systems = $_[2];    # host name => ( AS)
    my $BGP_roouter_identifier = $_[3];    # BGP's router  ID

    my %host_ids;         # host name => router_id in database
    my $flag;
    my $bgp_type = 'external';
    foreach my $h (sort keys %$host_ips) {
        print "DB_writeTopologyBgp:: Adding BGP host hostname: $h IP: $host_ips->{$h}\n" if $verbose;;
        $flag = DB_getBgpRouterId( $host_ips->{$h} );
        if (!defined( $flag ))
        {
            print "DB_writeTopologyBgp:: Added BGP router: ".$host_ips->{$h}."\n" if $verbose;;
            DB_addBgpRouter( $host_ips->{$h}, $bgp_type, $autonomous_systems->{$h}, $BGP_roouter_identifier, 0 );
        }
        else {
            print "DB_writeTopologyBgp:: Update BGP router: ".$host_ips->{$h}."\n" if $verbose;;
            DB_updateBgpRouterAS( $flag, $autonomous_systems->{$h}, $BGP_roouter_identifier );
        }
    }

    foreach my $hostA (sort keys %$links) {
        foreach my $Brec (sort @{${$links->{$hostA}}}) {
            my ($hostB, $linkT) = split /:/, $Brec;
            print "DB_writeTopologyBgp:: Checking links: $hostA <-> $hostB ($linkT)\n" if $verbose;;
            # Check link ends
            foreach my $chkH ($hostA, $hostB) {
                if (!defined( $host_ids{$chkH} )) {
                    print "DB_writeTopologyBgp:: Warning: link to not parsed BGP neighbor \'$chkH\'\n" if $verbose;;
                    $host_ids{$chkH} = DB_getBgpRouterId( $chkH );
                    if (!defined( $host_ids{$chkH} )) {
                        print "DB_writeTopologyBgp:: AddING neighbor \'$chkH\' type $bgp_type \n" if $verbose;;
                        $host_ids{$chkH} = DB_addBgpRouter( $chkH, $bgp_type, "", '', 0 );

                    }
                }
            }
            print "DB_writeTopologyBgp:: DB_writeBgpLink( $host_ids{$hostA} , $host_ids{$hostB} , $linkT )\n" if $verbose;;
            DB_writeBgpLink( $host_ids{$hostA}, $host_ids{$hostB}, $linkT );
        }
    }

}

# test get/add router

sub DB_TEST_getAddRouter($$) {
    my ($host, $ip_addr) = @_[0 .. 1];;

    $dbh->trace( 0 );

    my $rt_id = DB_getRouterId( $host );
    if (!defined( $rt_id )) {
        $rt_id = DB_addRouter( $host, $ip_addr, "unknown" );
    }

    print "Router id ($host): $rt_id\n";
}

# exists or no especially access type for router


#=for
#get count of access rules by $host
#    if $host is IP address then
#        search by router_name, router IP and router's interface IP
#    else
#        search by name
#
#
#           SELECT count(ra.*) as ammount,r.router_id
#                FROM router_access ra ,routers r
#                WHERE (
#                    (host(r.ip_addr) = '192.168.3.117'  or r.name = '192.168.3.117')
#                    AND ra.id_router=r.router_id
#                    )
#                GROUP BY r.router_id
#            UNION
#             SELECT count(ra.*) as ammount,r.router_id
#                FROM router_access ra ,routers r, interfaces i
#                WHERE
#                    (host(i.ip_addr) = '192.168.3.117'
#                        and ra.id_router=i.router_id
#                        and i.router_id = r.router_id
#                    )
#            GROUP BY r.router_id;
#
#=cut
sub DB_isInRouterAccess($) {
    my $r_n = $_[0];
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL;
    if ($_[0] =~ /\d+\.\d+\.\d+\.\d+/) {
        $SQL = "
             SELECT count(ra.*) as ammount,r.router_id as router_id
                FROM router_access ra ,routers r
                WHERE (
                    (host(r.ip_addr) = \'$r_n\'  or r.name = \'$r_n\')
                    AND ra.id_router=r.router_id
                    )
                GROUP BY r.router_id
            UNION
             SELECT count(ra.*) as ammount,r.router_id as router_id
                FROM router_access ra ,routers r, interfaces i
                WHERE
                    (host(i.ip_addr) = \'$r_n\'
                        and ra.id_router=i.router_id
                        and i.router_id = r.router_id
                    )
            GROUP BY r.router_id
            ";
    }
    else
    {
        $SQL = " SELECT count(ra.*) as ammount, r.router_id as router_id
                    FROM router_access ra ,routers r
                    WHERE r.name = \'$r_n\'
                        AND ra.id_router=r.router_id
                    GROUP BY 2";
    }
    #    Emsgd::diag($SQL) if ($debug > 0);
    my $sth = $dbh->prepare( $SQL );
    $sth->execute();
    return  $sth->fetchall_arrayref( { } );

}

sub DB_isCommunity($) {
    my $r_n = $_[0];
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL;
    $SQL = "SELECT count(*) as ammount FROM router_snmp_access WHERE router_id=".$r_n;

    my $rref = $dbh->selectcol_arrayref( $SQL );
    ##  print Dumper($rref);

    return $rref->[0];
}

sub DB_isDueCommunity($) {
    my $r_n = $_[0];
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL;
    if ($_[0] =~ /\d+\.\d+\.\d+\.\d+/) {
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
    my $rref = $dbh->selectall_arrayref( $SQL );
    return $rref;
}
sub DB_getScanException() {
    my $SQL;
    $SQL = "select addr from scan_exception where 1=1";
    return $dbh->selectcol_arrayref( $SQL ) || [ ];
}


# returns [ ['ip/mask','interface_ip, [...], ... ]
# array of arrays
sub DB_getNetworksToScan() {
    my $SQL = "SELECT  concat(ip_addr,'/',mask),ip_addr FROM interfaces";
    return $dbh->selectall_arrayref( $SQL ) || [ ];
}

sub DB_isScanException($) {
    my $cur_subnet = $_[0];
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL;
    $SQL = "select count(*) from scan_exception where addr>>='".$cur_subnet."'";
    my $rref = $dbh->selectcol_arrayref( $SQL );
    my $ret_val = 1 - $rref->[0];
    return $ret_val
}

sub DB_getCriptoKey() {
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL;
    $SQL = "SELECT value FROM general_settings WHERE name='chiave'";

    my $rref = $dbh->selectcol_arrayref( $SQL );
    ##  print Dumper($rref);

    return $rref->[0];
}

sub DB_updateDiscoveryStatus ($$) {
    my ($percent, $finish) = @_[0 .. 1];

    my $SQL = "UPDATE discovery_status SET percent = ?,lastchange=now(),ended=? WHERE ended = 0";
    my $link_h = $dbh->prepare( $SQL );
    $link_h->execute( $percent, $finish );
}

sub DB_updateDiscoveryStatusOne ($$) {
    my ($percent, $finish) = @_[0 .. 1];

    my $SQL = "UPDATE discovery_status SET percent = percent+?,lastchange=now(),ended=? WHERE ended = 0";
    my $link_h = $dbh->prepare( $SQL );
    $link_h->execute( $percent, $finish );
}

sub DB_insertDiscoveryStatus ($$) {
    my ($user, $interact) = @_[0 .. 1];
    my $percent = 0;
    my $finish = 0;
    my $SQL = "INSERT INTO discovery_status(start,username,percent,ended,interactive) VALUES (now(),?,?,?,?)";
    my $link_h = $dbh->prepare( $SQL );
    $link_h->execute( $user, $percent, $finish, $interact );
}

sub DB_stopDiscovery  {
    my ($percent, $finish, $mode) = @_[0 .. 2];
    ## mode 1- normal end, 0 - overdue session finishing
    if ($mode)
    {
        my $SQL = "UPDATE discovery_status SET percent = ?,finish=now(),ended=? WHERE ended = 0";
        my $link_h = $dbh->prepare( $SQL );
        $link_h->execute( $percent, $finish );
    }
    else
    {
        my $SQL = "UPDATE discovery_status SET finish=now(),ended=? WHERE ended = 0";
        my $link_h = $dbh->prepare( $SQL );
        $link_h->execute( $finish );
    }

}
#@deprecated
sub DB_isOpenedDiscovery()
{
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL;
    $SQL = "select count(*) from discovery_status WHERE ended = 0";
    my $rref = $dbh->selectcol_arrayref( $SQL );
    my $ret_val = $rref->[0];
    return $ret_val;
}

sub DB_lastchangeDiscovery()
{
    local $dbh->{RaiseError};     # Ignore errors
    my $SQL;
    $SQL = "select
    cast(LEAST(
  extract(epoch from now()) - extract(epoch from lastchange),
    extract(epoch from now()) - extract(epoch from start)
  ) as INT)  as running
    from  discovery_status WHERE ended = 0";
    my $rref = $dbh->selectcol_arrayref( $SQL );
    my $ret_val = $rref->[0];
    return $ret_val;
}

sub DB_modeDiscovery()
{
    ##	local $dbh->{RaiseError};     # Ignore errors
    my $SQL;
    $SQL = "select interactive from discovery_status WHERE ended = 0";
    my $rref = $dbh->selectcol_arrayref( $SQL );
    my $ret_val = $rref->[0];
    return $ret_val;
}

sub DB_percentDiscovery()
{
    ##	local $dbh->{RaiseError};     # Ignore errors
    my $SQL;
    $SQL = "select percent from discovery_status WHERE ended = 0";
    my $rref = $dbh->selectcol_arrayref( $SQL );
    my $ret_val = $rref->[0];
    return $ret_val;
}

sub DB_getAllIntefaces() {
    my $SQL = "SELECT  router_id,ph_int_id,ifc_id,name,ip_addr,mask,descr FROM interfaces ORDER by ifc_id";
    my $aref = $dbh->selectall_hashref( $SQL, "ifc_id" );

    if (defined( $aref )) {
        #	  print Dumper($aref);
        #       my %tmp = map { $_ => $aref->{$_} } ( keys %$aref );
        #    print Dumper(%tmp);
        #    return %tmp;
        return $aref;
    }
    return undef;
}

sub DB_checkVersion($) {
    local $dbh->{RaiseError};
    my $SQL = "SELECT max(version)from ngnms_check_version";
    my $rref = $dbh->selectcol_arrayref( $SQL );
    return undef unless $rref;
}



# END { print "deleting NGNMS_DB\n"; }

1;
# ABSTRACT: This file is part of open source NG-NetMS tool.


__END__
