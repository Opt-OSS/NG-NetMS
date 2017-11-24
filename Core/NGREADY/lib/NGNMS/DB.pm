package NGNMS::DB;

use strict;
use warnings FATAL => 'all';
use Digest::MD5 qw(md5_hex);

use Moo;
use DBD::Pg;
use Emsgd qw (diag);
with "NGNMS::DB::Base", "NGNMS::DB::Crypt", "NGNMS::App::Helpers";
with "NGNMS::Log4Role";
#TODO Simplify one-value SQL by : As your SQL never returns more than one row with one field, you are probably rather looking for selectrow_array:
# -------------------------------------------------------------------------------------------
#=head2 getSeqNextVal($sequence_name)
#    retuns Postgress nextval for given sequence name
#=cut

sub getSeqNextVal {
    my $self = shift;
    my $sequence_name = shift;
    my $ref = $self->dbh->selectrow_array("select nextval('$sequence_name')");
}


#----------------------------------------  SNMP Community ----------------------------------------------------
#=head2 getCommunity($router_id)
#    retuns ecripted community for router_id
#=cut

sub getRouterCommunity {
    my $self = shift;
    my $rt_id = shift;
    #@inject PGSQL
    my $SQL = "SELECT sa.community_ro,sa.community_rw
        FROM router_snmp_access rs,snmp_access sa
        WHERE rs.router_id= ? AND rs.snmp_access_id = sa.id;";
    return $self->dbh->selectrow_hashref($SQL, { Slice => {} }, ($rt_id));
}
#TODO cover with tests
=method
    get community either host IP or INTERFACE IP
=cut
sub getRouterByInterfaceIp {
    my $self = shift;
    my $ip_addr = shift;
    local $self->dbh->{RaiseError};     # Ignore errors
    my $SQL;
    if ($ip_addr =~ /\d+\.\d+\.\d+\.\d+/) {
        #@inject PGSQL
        $SQL = "SELECT r.router_id FROM router_snmp_access ra ,routers r, interfaces i
            WHERE
            host(i.ip_addr) = ?  AND ra.router_id=i.router_id AND i.router_id = r.router_id  ";
    }
    else {
        return undef;
    }
    return $self->dbh->selectrow_array($SQL, { Slice => {} }, ($ip_addr));
}

#@deprecated => see getCommunityByIP
sub isDueCommunity_OL {
    my $self = shift;
    my $r_n = shift;
    local $self->dbh->{RaiseError};     # Ignore errors
    my $SQL;
    if ($r_n =~ /\d+\.\d+\.\d+\.\d+/) {
        #@inject PGSQL
        $SQL = "SELECT count(ra.*) AS ammount,r.router_id FROM router_snmp_access ra ,routers r, interfaces i
            WHERE ((host(r.ip_addr) = '$r_n'  OR r.name = '$r_n'  ) AND ra.router_id=r.router_id )
            OR (host(i.ip_addr) = '$r_n'  AND ra.router_id=i.router_id AND i.router_id = r.router_id) GROUP BY r.router_id";
    }
    else {
        #somethind default? Host Ip could not be null
        #@inject PGSQL
        $SQL = "SELECT count(ra.*) AS ammount,r.router_id FROM router_snmp_access ra ,routers r, interfaces i
            WHERE ((host(r.ip_addr) = '0.0.0.0'  OR r.name = '0.0.0.0'  ) AND ra.router_id=r.router_id AND i.router_id = r.router_id)
            OR (host(i.ip_addr) = '0.0.0.0'  AND ra.router_id=i.router_id AND i.router_id = r.router_id) GROUP BY r.router_id";
    }
    return $self->dbh->selectall_arrayref($SQL);
}
# -------------------------------------------------------------------------------------------

#TODO Stop using hostname
=method
    get router by IP or hostname
=cut
sub getRouterId {
    my $self = shift;
    my $router_ip_or_name = shift;
    #    local $self->dbh->{RaiseError};     # Ignore errors
    my $rref;
    if ($router_ip_or_name =~ /^\d+\.\d+\.\d+\.\d+$/) {
        #@inject PGSQL
        $rref = $self->dbh->selectrow_array("SELECT router_id FROM routers WHERE ip_addr = ? OR name = ?", undef,
            ($router_ip_or_name, $router_ip_or_name));
    }
    else {
        #@inject PGSQL
        $rref = $self->dbh->selectrow_array("SELECT router_id FROM routers WHERE name = ?", undef,
            ($router_ip_or_name));
    }
    return  $rref;
}
sub getRouterInfo {
    my $self = shift;
    my $router_ip_or_name = shift;
    #    local $self->dbh->{RaiseError};     # Ignore errors
    my $rref;
    if ($router_ip_or_name =~ /^\d+\.\d+\.\d+\.\d+$/) {
        #@inject PGSQL
        $rref = $self->dbh->selectrow_arrayref(
            "SELECT router_id,name,ip_addr FROM routers WHERE ip_addr = ? OR name = ?", undef,
            ($router_ip_or_name, $router_ip_or_name));
    }
    else {
        #@inject PGSQL
        $rref = $self->dbh->selectrow_arrayref("SELECT router_id,name,ip_addr FROM routers WHERE name = ?", undef,
            ($router_ip_or_name));
    }
    return wantarray ? @{$rref ? $rref : []} : $rref;
}

# -------------------------------------------------------------------------------------------
#=head2 addRouter($hostname,$ip,$status)
#
#adds new router to DB
#
#    if hostname match IP pattern, will try to get host name by reverse DNS lookp
#    returns new router ID
#    no ANY checks if router exists
#
#
#=cut
sub addRouter {
    my ( $self, $hostname, $ip, $stat) = (shift, shift, shift, shift,);

    #    diag "($hostname, $ip, $stat)";
    my $new_id = $self->getSeqNextVal('routers_router_id_seq');
    #@inject PGSQL
    my $SQL = "INSERT INTO routers (router_id,name,ip_addr,status) VALUES (?,?,?,?)";
    my DBI $sw_h = $self->dbh->prepare($SQL);
    #TODO move reverseDNS out of DB
    $hostname = NGNMS::App::Helpers->getHostPart(NGNMS::App::Helpers->reverseDNS($hostname)) if ($hostname =~ /\d+\.\d+\.\d+\.\d+/);
    #  Emsgd::print($ip);
    return $sw_h->execute($new_id, $hostname, $ip, $stat) ? $new_id : undef;
}
# Get router ip addr
# Param:
#  router id
sub getRouterIpAddr {
    my $self = shift;
    my $rt_id = shift;
    #@inject PGSQL
    my $SQL = "SELECT ip_addr FROM routers WHERE router_id = ?";
    return  $self->dbh->selectrow_array($SQL, undef, ($rt_id));
}
# --------------------------------------------------------------------------
sub setHostStatus {
    my $self = shift;
    my $rt_id = shift;
    my $status = shift;

    $self->dbh->do("UPDATE routers SET status = ? WHERE router_id = ?", undef, ($status, $rt_id));
}
# -------------------------------------------------------------------------------------------
sub setHostModel {
    my $self = shift;
    my $rt_id = shift;
    my $model = shift;
    $model = substr($self->trim($model), 0, 49);
    #@inject PGSQL
    $self->dbh->do("UPDATE routers SET eq_type = ? WHERE router_id = ?", undef, ($model, $rt_id));
}
# -------------------------------------------------------------------------------------------
sub setHostName {
    my $self = shift;
    my ($r_id, $name) = @_[0 .. 1];
    #@inject PGSQL
    $self->dbh->do("UPDATE routers SET name = ? WHERE router_id = ?", undef, ($name, $r_id));
}
# -------------------------------------------------------------------------------------------
sub getHostVendor {
    my $self = shift;
    my $host = shift;
    my $rref;
    #    local $self->dbh->{RaiseError};     # Ignore errors
    if ($host =~ /\d+\.\d+\.\d+\.\d+/) {
        #@inject PGSQL
        $rref = $self->dbh->selectcol_arrayref("SELECT eq_vendor FROM routers WHERE ip_addr = ? OR name = ? ", undef,
            ($host, $host));
    }
    else {
        #@inject PGSQL
        $rref = $self->dbh->selectcol_arrayref("SELECT eq_vendor FROM routers WHERE name = ?", undef, ($host));
    }

    return defined($rref) ? $rref->[0] : undef;
}
sub getRouterVendorById {
    my $self = shift;
    my $rid = shift;
    #@inject PGSQL
    return  $self->dbh->selectrow_array("SELECT eq_vendor FROM routers WHERE router_id = ?", undef, ($rid));
}
sub setHostVendor {
    my $self = shift;
    my $rt_id = shift;
    my $vendor = shift;
    $vendor = substr($self->trim($vendor), 0, 49);
    #@inject PGSQL
    $self->dbh->do("UPDATE routers SET eq_vendor = ? WHERE router_id = ?", undef, ($vendor, $rt_id));
}
# -------------------------------------------------------------------------------------------
sub clearHostHardwareInfo {
    my $self = shift;
    my $rt_id = shift;
    #@inject PGSQL
    $self->dbh->do("DELETE FROM inv_hw WHERE router_id = ?", undef, $rt_id);
}
# -------------------------------------------------------------------------------------------
sub setHostHardwareInfo {
    my $self = shift;
    my $rt_id = shift;
    my $hw = shift;
    #@inject PGSQL
    my $SQL = "INSERT INTO inv_hw (router_id,hw_item,hw_name,hw_version,hw_amount) VALUES (?,?,?,?,?)";
    my DBI $sw_h = $self->dbh->prepare($SQL);
    #    diag $hw; diag $rt_id;
    for my $hw_info (@$hw) {
        $sw_h->execute($rt_id, @$hw_info{("hw_item", "hw_name", "hw_ver", "hw_amount")});
    }
}
# -------------------------------------------------------------------------------------------
sub clearHostSoftwareInfo {
    my $self = shift;
    my $rt_id = shift;
    #@inject PGSQL
    $self->dbh->do("DELETE FROM inv_sw WHERE router_id = ?", undef, $rt_id);
}

# -------------------------------------------------------------------------------------------
sub setHostSoftwareInfo {
    my $self = shift;
    my $rt_id = shift;
    my $sw = shift;
    #@inject PGSQL
    my $SQL = "INSERT INTO inv_sw (router_id,sw_item,sw_name,sw_version) VALUES (?,?,?,?)";
    my DBI $sw_h = $self->dbh->prepare($SQL);
    for my $sw_info (@$sw) {
        $sw_h->execute($rt_id, @$sw_info{("sw_item", "sw_name", "sw_ver")});
    }
}
# -------------------------------------------------------------------------------------------
sub setHostLocation {
    my $self = shift;
    my $rt_id = shift;
    my $loc = shift;
    #@inject PGSQL
    $self->dbh->do("UPDATE routers SET location = ? WHERE router_id = ?", undef, ($loc, $rt_id));
}
# -------------------------------------------------------------------------------------------

sub setHostLayer {
    my $self = shift;
    my $rtiId = shift;
    my $layer = shift;
    #@inject PGSQL
    $self->dbh->do("UPDATE routers SET layer = ? WHERE router_id = ?", undef, ($layer, $rtiId));

}
# -------------------------------------------------------------------------------------------
sub addConfig {
    my $self = shift;
    my $rt_id = shift;
    my $data = shift;
    return 0 unless $data;
    my $checksum = md5_hex($data);
    my $last_conf_checksum = $self->dbh->selectrow_arrayref(
        "select id,checksum from router_configuration where router_id=? order by created desc limit 1", undef,
        ($rt_id));
    if ($last_conf_checksum && @$last_conf_checksum[1] eq $checksum) {
        $self->logger->debug("Config is not changed");
        #@inject PGSQL
        $self->dbh->do("UPDATE router_configuration SET created = now() WHERE id = ?", undef,
            (@$last_conf_checksum[0]));
        return 1;
    }
    #@inject PGSQL
    #@type DBI
    my $sth = $self->dbh->prepare("INSERT INTO router_configuration(router_id,data,checksum,created) VALUES (?,?,?,now())");
    $sth->bind_param(1, $rt_id);
    $sth->bind_param(2, $data, { pg_type => DBD::Pg::PG_BYTEA });
    $sth->bind_param(3, $checksum);
    $sth->execute();
    return 1;

}

# -------------------------------------------------------------------------------------------

#=for
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
sub markInterfacesToBePolled {
    my $self = shift;
    my $rt_id = shift;
    #@inject PGSQL
    $self->dbh->do("UPDATE  interfaces SET descr='#PollNotFound#' WHERE router_id = ?", undef, $rt_id);
}
sub markPhInterfacesToBePolled {
    my $self = shift;
    my $rt_id = shift;
    #@inject PGSQL
    $self->dbh->do("UPDATE  ph_int SET descr='#PollNotFound#' WHERE router_id = ?", undef, $rt_id);
}
#=for
# see DB_markInterfacesToBePolled for usage
#
#=cut
sub deleteInterfacesPolledButNotFound {
    my $self = shift;
    my $rt_id = shift;
    #@inject PGSQL
    $self->dbh->do("DELETE FROM interfaces WHERE  descr='#PollNotFound#'  AND  router_id =?", undef, $rt_id);
}
sub deletePhInterfacesPolledButNotFound {
    my $self = shift;
    my $rt_id = shift;
    #@inject PGSQL
    $self->dbh->do("DELETE FROM ph_int WHERE  descr='#PollNotFound#'  AND  router_id = ?", undef, $rt_id);
}
# -------------------------------------------------------------------------------------------
#=for getPhInterfaceId($router_id,$interface_name)
#get the Physical interface ID of the $router_id with given $interface_name
#returns id or undef
#
#=cut
sub getPhInterfaceId {
    my $self = shift;
    my $rt_id = shift;
    my $ifc_n = shift;
    local $self->dbh->{RaiseError};     # Ignore errors
    #@inject PGSQL
    my $SQL = "SELECT ph_int_id FROM ph_int WHERE router_id = ? AND name = ?";
    my $rref = $self->dbh->selectcol_arrayref($SQL, undef, ($rt_id, $ifc_n));
    if (defined($rref)) {
        return $rref->[0];
    }
    return;
}
# -------------------------------------------------------------------------------------------
#=for setPhInterface($router_id, $ifc)
# insert new Physical interfase of the $router_id or update existed with the same name
#
# $ifc = {
#    name => 'eth0', #interface name
#    state => 'enabled,   #admin status
#    condition=>'up',     #link sate
#    speed=> '100Mb/s' ,  #string with human readable speed
#    description => 'Descr' #descriptionn or additional info, for ex. MAC for Linux
# }
#=cut
sub setPhInterface {
    my $self = shift;
    my $rt_id = shift;
    my $ifc = shift;
    my $ifc_id = $self->getPhInterfaceId($rt_id, $ifc->{"name"});
    if (!defined($ifc_id)) {
        # easy - insert new ifc, reserve new_id to be returned for transaction_safe approach
        my $new_ph_in_id = $self->getSeqNextVal('ph_int_ph_int_id_seq');
        #@inject PGSQL
        my $SQL = "INSERT INTO ph_int (ph_int_id,router_id,name,state,condition,speed,descr,mtu) VALUES (?,?,?,?,?,?,?,?)";
        my @params = ($new_ph_in_id, $rt_id, @$ifc{("name", "state", "condition", "speed", "description", "mtu")});
        #                diag $ifc;
        my $if_h = $self->dbh->do($SQL, undef, @params);
        return  $if_h ? $new_ph_in_id : undef;
    }
    # hard - update
    my @params = (@$ifc{("state", "condition", "speed", "description", "mtu")}, $ifc_id);
    #@inject PGSQL
    my $SQL = "UPDATE ph_int SET state = ?, condition = ?, speed = ?, descr = ?, mtu=? WHERE ph_int_id = ?";
    $self->dbh->do($SQL, undef, @params);
    return $ifc_id;
}
# -------------------------------------------------------------------------------------------
#=for getInterfaceId($router_id,$interface_params)
#get Logical interface ID of $router_id with $interface_params
#
#    $interface_params = {
#        ph_int_id => 4,       # phisical interface ID to which logical interface belongs
#        name => 'eth0:1',     # name of  logical interface to search
#        ip => 'eth0:1',  # ip address of logical interface
#    }
#
#=cut

# Get ifc id by rt_id and name
sub getInterfaceId {
    my $self = shift;
    my $rt_id = shift;
    my $if_par = shift;
    local $self->dbh->{RaiseError};     # Ignore errors
    #@inject PGSQL
    my $SQL = "SELECT ifc_id FROM interfaces WHERE router_id = ? AND ph_int_id = ? AND name = ? AND ip_addr = ?";
    my @param = ($rt_id, @$if_par{('ph_int_id', 'name', 'ip')});
    my $rref = $self->dbh->selectcol_arrayref($SQL, undef, @param);
    #  print Dumper($rref);
    return defined($rref) ? $rref->[0] : undef;
}

#=for setInterface($router_id, $ifc)
# insert new Logical  interfase or update existed with the same name
# to $router_id
#
# $ifc = {
#    ph_int_id +> 4,         #Physocal interface ID  interface belongs to
#    name => 'eth0:0',       #interface name
#    ip=> '192.168.1.1',     #interface IP
#    mask=>'255.255.255.0'   #Network mask
#    description => 'Descr', #descriptionn or additional info, for ex. MAC for Linux
# }
#
#=cut

sub setInterface {
    my $self = shift;
    my $rt_id = shift;
    my $ifc = shift;
    my $ifc_id = $self->getInterfaceId($rt_id, $ifc);
    if (!defined($ifc_id)) {
        my $new_in_id = $self->getSeqNextVal('interfaces_ifc_id_seq');
        #@inject PGSQL
        my $SQL = "INSERT INTO interfaces (ifc_id,router_id,ph_int_id,name,ip_addr,mask,descr) VALUES (?,?,?,?,?,?,?)";

        my @SQLARGS = ($new_in_id, $rt_id, @$ifc{('ph_int_id', 'name', 'ip', 'mask', 'description')});
        return $self->dbh->do($SQL, undef, @SQLARGS) ? $new_in_id : undef;
    }

    # hard - update
    #@inject PGSQL
    my $SQL = "UPDATE interfaces SET ip_addr = ?, mask = ?, descr = ? WHERE ifc_id = ?";
    my @SQLARGS = (@$ifc{('ip', 'mask', 'description')}, $ifc_id);
    $self->dbh->do($SQL, undef, @SQLARGS);
    return $ifc_id;
}

#--------------------------------- Scanner --------------------
sub getNetworksToScan() {
    my $self = shift;
    #@inject PGSQL
    return $self->dbh->selectall_arrayref("SELECT  concat(ip_addr,'/',mask),ip_addr FROM interfaces") || [];
}
sub getScanException() {
    my $self = shift;
    #@inject PGSQL
    return $self->dbh->selectcol_arrayref("SELECT addr FROM scan_exception WHERE 1=1") || [];
}


sub getInterfaceRouterId {
    my $self = shift;
    my $addr = shift;
    #@inject PGSQL
    return  $self->dbh->selectrow_array("SELECT router_id FROM interfaces WHERE host(ip_addr) =? LIMIT 1", undef,
        ($addr));
}



#------------------------------- Discovery and tasks --------------------
sub updateDiscoveryStatus {
    my $self = shift;
    my ($percent, $finish) = @_;
    #@inject PGSQL
    $self->dbh->do("UPDATE discovery_status SET percent = ?,lastchange=now(),ended=? WHERE ended = 0", undef,
        ($percent, $finish));
}
#---------------------------- ARCHIVE ---------------------------------
sub getArchiveData {
    my $self = shift;
    my ($archive_id) = @_;
    #@inject PGSQL
    return $self->dbh->selectrow_hashref("SELECT * FROM archives WHERE archive_id =?", undef, ($archive_id));

}
sub clearArchiveData {

}

sub markArchiveLoaded {
    my $self = shift;
    my ($archive_id, $mark) = @_;
    my $state = $mark ? 'true' : 'false';
    #@inject PGSQL
    $self->dbh->do("UPDATE archives SET in_db = ? WHERE archive_id= ?", undef, ($state, $archive_id));
}
#---------------------------- TOPOLOGY ---------------------------------

sub writeLink {
    #todo move to upsert syntax
    my $self = shift;
    my ($idA, $idB, $type) = @_;

    # try to update
    # if fails, insert a new rec
    my $rref = $self->dbh->do("
			UPDATE network SET link_type = ?
            WHERE router_id_a = ? AND router_id_b = ?
            ", undef, ($type, $idA, $idB));

    # print "RRef: $rref\n";
    if ($rref eq "0E0") {
        $self->dbh->do("INSERT INTO network (router_id_a,router_id_b,link_type) VALUES (?,?,?)", undef,
            ($idA, $idB, $type));
    }
}
1;

# ABSTRACT: This file is part of open source NG-NetMS tool.
