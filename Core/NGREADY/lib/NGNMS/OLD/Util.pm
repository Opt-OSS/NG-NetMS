#
# NextGen NMS
#
# NGNMS::OLD::NGNMS_util: miscellaneous utility functions
#
# Copyright (C) 2002,2003 OptOSS LLC
#
# Author: M.Golov
#

package NGNMS::OLD::Util;

use strict;
use warnings;

use Net::SNMP;
use Net::DNS;
use Net::Netmask;
use MIME::Base64;
use Crypt::TripleDES;
use Data::Dumper;
use Nmap::Scanner;
use Emsgd qw(diag);
use Switch;
use NGNMS::Log4

require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $data);

@ISA = qw(Exporter AutoLoader);

## set the version for version checking; uncomment to use
$VERSION = 3.41;

@EXPORT = qw(skip_till getHostType reverseDNS getHostPart  bits2mask  decryptAttrvalue );

# your exported package globals go here,
# as well as any optionally exported functions
#@EXPORT_OK   = qw($data);


my $logger = NGNMS::Log4->new()->get_new_category_logger(__PACKAGE__);

# filehandle, regexp
sub skip_till {
    my $fh = shift;
    my $re = shift;
    #print $re;
    while (<$fh>) {
        chomp;                  # no newline
        #print "$_\n";
        return $_ if $_ =~ $re;
    }
    return undef;
}

# figure out what kind of router we have here...
# Params:
#  host name or ip
# Returns:
#  Cisco/Juniper/unknown/<undef>
#
my $testHostType;

sub getHostType($$) {
    #    my @oids = ('1.3.6.1.2.1.1.3.0');
    return ($testHostType, '') if defined( $testHostType );

    my ($host, $community) = @_;
    my $version = '2c';
    my ($sess, $err) = Net::SNMP->session(
        -hostname  => $host,
        -community => $community,
        -timeout   => 1.0,
    );
    if (!defined( $sess )) {
        if ($err =~ /Unable to resolve destination address.*/) {
            return (undef, "$err");
        }
        return (undef, "SNMP: $err");
    }
    my $req = '1.3.6.1.2.1.1.2.0';    # 'sysObjectID.0'
    my $res = $sess->get_request( -varbindlist => [ $req ] );

    if (!defined( $res )) {

        $sess->close();
        my ($sess, $err) = Net::SNMP->session(
            -hostname  => $host,
            -version   => $version,
            -community => $community,
            -timeout   => 1.0,
        );
        if (!defined( $sess )) {
            if ($err =~ /Unable to resolve destination address.*/) {
                return (undef, "$err");
            }
            return (undef, "SNMP: $err");
        }

        $res = $sess->get_request( -varbindlist => [ $req ] );

        if (!defined( $res )) {
            $err = $sess->error;
            return (undef, "SNMP: $err");
        }
    }

    my $mib = $res->{$req};

    my $hostt = "unknown";
    $hostt = "Juniper" if $mib =~ /1\.3\.6\.1\.4\.1\.2636\..*/;
    $hostt = "Cisco" if $mib =~ /1\.3\.6\.1\.4\.1\.9\..*/;
    $hostt = "Linux" if $mib =~ /1\.3\.6\.1\.4\.1\.8072\..*/;
    $hostt = "HP" if $mib =~ /1\.3\.6\.1\.4\.1\.11\..*/;
    $hostt = "Extreme" if $mib =~ /1\.3\.6\.1\.4\.1\.1916\..*/;
    $hostt = "Netscreen" if $mib =~ /1\.3\.6\.1\.4\.1\.3224\..*/;
    $logger->debug( 'getHostType by mib "'.$mib.', " = '.$hostt);
    return ($hostt, '');
}

# return host part of the full host name
sub getHostPart($) {
    my $host = shift;
    return $host if ( $host =~ /\d+\.\d+\.\d+\.\d+/);
    $host =~ /^([^.]*)/;
    return $1;
}

# Do reverse DNS lookup
# Params: ip addr
# Return: host name or IP addr if lookup failed
#
sub reverseDNS($) {
    my $ip_address = shift;
    my $result;
    my $res = new Net::DNS::Resolver;
    my $resp = $res->search( $ip_address );
    if ($resp) {
        foreach my $rr ($resp->answer) {
            next unless $rr->type eq "PTR";
            $result = $rr->rdatastr;
            $result =~ s/\.$//g;
        }
    } else {
        $result = $ip_address;
    }
    return $result;
}


sub ip2num
{
    my $ip = $_[0];
    my @a = split /\./, $ip;
    my $intip = int($a[0]) * 256 * 256 * 256 + int($a[1]) * 256 * 256 + int($a[2]) * 256 + int($a[3]);

    return $intip;
}
sub num2ip
{
    my $intip = $_[0];
    my $d = $intip % 256;
    $intip -= $d;
    $intip /= 256;
    my $c = $intip % 256;
    $intip -= $c;
    $intip /= 256;
    my $tb = $intip % 256;
    $intip -= $tb;
    $intip /= 256;
    my $ip = "$intip.$tb.$c.$d";
    return $ip;

}
sub tests_print_net {
    my $nets = shift;
    my @d;
    for my Net::Netmask  $net (@$nets) {
        push @d, $net->base().'/'.$net->bits();
    }
    return @d;
}

#
# Convert mask specified by number of bits to x.x.x.x format
#
sub bits2mask($) {
    my $bits = shift;
    my $res = '';
    my $rest = ".0.0.0";
    my %cvt;
    @cvt{("0", "1", "2", "3", "4", "5", "6", "7")} =
        ("0", "128", "192", "224", "240", "248", "252", "254");
    if ($bits == 32) {
        return "255.255.255.255";
    }
    if ($bits > 23) {
        $res = "255.255.255.";
        $rest = '';
        $bits -= 24;
    }
    if ($bits > 15) {
        $res = "255.255.";
        $rest = '.0';
        $bits -= 16;
    }
    if ($bits > 7) {
        $res = "255.";
        $rest = '.0.0';
        $bits -= 8;
    }
    return $res.$cvt{$bits}.$rest;
}

sub decryptAttrvalue($$)
{
    my $pass = shift;
    my $text = shift;
    my $des = Crypt::TripleDES->new();
    my $plaintext = $des->decrypt3 ( decode_base64( $text ), $pass );
    if (defined( $plaintext ))
    {
        $plaintext =~ s/^\s+//;            # no leading white
        $plaintext =~ s/\s+$//;            # no trailing white
    }
    return $plaintext;
}
#

#TODO use App::Crypt
#@deprecated
sub decode_val_from_DB{
    my $key = shift;
    my $val = NGNMS::OLD::DB::DB_getSettings( $key  );
    return undef unless @$val;

    $val = $val->[0];

    my $criptokey = NGNMS::OLD::DB::DB_getCriptoKey();
    my $p = 48 - length($criptokey);
    my $suffix = ( '0' x $p );
    $criptokey .= $suffix;

    #    print "Decrypt $key \n";
    $val =~ s/^\s+//;            # no leading white
    $val =~ s/\s+$//;            # no trailing white

    return decryptAttrvalue( $criptokey, $val );

}

sub decode_snmp_community{
    my ($host, $community) = @_;
    my ($r_id, $t_arr, $last);
    $r_id = NGNMS::OLD::DB::DB_getRouterId( $host );
    return $community unless defined $r_id;

    $t_arr = NGNMS::OLD::DB::DB_getCommunity( $r_id );
    my $criptokey = NGNMS::OLD::DB::DB_getCriptoKey();
    # sa.community_ro,sa.community_rw
    if (@$t_arr)
    {
        #we get commounty in DB for this router, use it
        #use latest row if we have more then one
        #use sa.community_ro or fallback to sa.community_rw if undefined
        $last = @$t_arr[- 1];
        $community = decryptAttrvalue( $criptokey, $last->[0] || $last->[1] );
        $logger->debug( " use DB SNMP Community  for $host founded by router  ID $r_id");
    }
    else
    {
        #we dont have individual community in DB for this router_id
        #try to find bu host name
        $t_arr = NGNMS::OLD::DB::DB_isDueCommunity( $host );

        if (@$t_arr) {
            #count(ra.*) as ammount,r.router_id
            #use r.router_id  from last row
            $last = @$t_arr[- 1];
            $t_arr = NGNMS::OLD::DB::DB_getCommunity( $last->[1] );
            if (@$t_arr) {
                #we get commounty in DB for that router, use it
                #use latest row if we have more then one
                #use sa.community_ro or fallback to sa.community_rw if undefined
                $last = @$t_arr[- 1];
                $community = decryptAttrvalue( $criptokey, $last->[0] || $last->[1] );
                $logger->debug( " use DB SNMP Community  for $host founded by host name");
            }

        } else {
            $logger->debug( " use Default SNMP Community  for $host");
        }
    }
    return $community;
}
=header2 get_default_credentials()
    retuns default connct credentials
=cut
#@deprecated
sub get_default_credentials{
    my $user = NGNMS::OLD::Util::decode_val_from_DB( 'username' );
    my $passwd = NGNMS::OLD::Util::decode_val_from_DB( 'password' );
    my $enpasswd = NGNMS::OLD::Util::decode_val_from_DB( 'enpassword' );
    my $access = NGNMS::OLD::Util::decode_val_from_DB( 'type access' );
    my $community = NGNMS::OLD::Util::decode_val_from_DB( 'community' );
    return ( $user, $passwd, $enpasswd, $access, $community );
}
#TODO Use App::Crypt
#@deprecated
sub decode_router_access_method {
    my ( $host, $user, $passwd, $enpasswd, $access, $path_to_key ) = @_; #defaults
    $logger->debug( "#decode_router_Access_method checking if special access exists for $host, use fallback values");

    my $r_id = NGNMS::OLD::DB::DB_getRouterId( $host );

    if (!defined $r_id) {
        $logger->debug( "Router ID not found for $host, use defauls access");
        return ( $user, $passwd, $enpasswd, $access, $path_to_key )
    }
    #    my $arr_param6 = NGNMS_DB::DB_isInRouterAccess( $host );    # check if special access to router exists
    #    return  ( $user, $passwd, $enpasswd, $access, $path_to_key ) unless @$arr_param6;
    #
    #    #found ruter id in access tables, use last founded (there are could be more then one record for router and interface IP)
    #    #use credentials from DB
    #    my $last = @$arr_param6[-1];
    #    my $r_id = $last->{router_id};

    my $encoded = NGNMS::OLD::DB::DB_getRouterAccess( $r_id );
    if (!@$encoded) {
        $logger->debug( " Decode access not found for $host, router ID $r_id, use fallback values");
        return ( $user, $passwd, $enpasswd, $access, $path_to_key );
    }

    my $criptokey = NGNMS::OLD::DB::DB_getCriptoKey();

    foreach my $par (@$encoded) {
        next unless defined $par->[0];
        $access = $par->[0];
        my $flag = lc( $par->[2] );
        if ($flag eq 'login') {
            $user = decryptAttrvalue( $criptokey, $par->[3] );
        }
        if ($flag eq 'password') {
            $enpasswd = $passwd = decryptAttrvalue( $criptokey, $par->[3] );
        }
        if ($flag eq 'enpassword') {
            $enpasswd = decryptAttrvalue( $criptokey, $par->[3] );
        }
        if ($flag eq 'path_to_key')    #path to key
        {
            $path_to_key = decryptAttrvalue( $criptokey, $par->[3] );
        }
    }

    $logger->debug( " use DB Access method for $host with ID $r_id");

    return  ( $user, $passwd, $enpasswd, $access, $path_to_key );
}
#sub decode_bgp_access_method {
#    my ( $seedHost, $user, $passwd, $enpasswd, $access) = @_; #defaults
#    my $r_id = NGNMS_DB::DB_getBgpRouterId( $seedHost );
#    return ($user, $passwd, $enpasswd, $access) unless defined $r_id;
#    my $encoded = NGNMS_DB::DB_getBGPRouterAccess( $r_id );
#    return ($user, $passwd, $enpasswd, $access) unless defined $encoded;
#    my $criptokey = NGNMS_DB::DB_getCriptoKey();
#    foreach my $par (@$encoded) {
#        next unless defined $par->[0];
#        $access = $par->[0];
#        my $flag = lc( $par->[2] );
#        if ($flag eq 'login') {
#            $user = decryptAttrvalue( $criptokey, $par->[3] );
#        }
#        if ($flag eq 'password') {
#            $enpasswd = $passwd = decryptAttrvalue( $criptokey, $par->[3] );
#        }
#        if ($flag eq 'enpassword') {
#            $enpasswd = decryptAttrvalue( $criptokey, $par->[3] );
#        }
#
#        #        if ($flag eq 'path_to_key') {
#        #            $path_to_key = decryptAttrvalue($criptokey, $emp->[3]);
#        #            $path_to_key =~ s/\s + $//;
#        #        }
#    }
#    return ($user, $passwd, $enpasswd, $access);
#}

sub autodetect_host_type_by_file_content($$) {
    my $configs_dir = shift;
    my $hostname = shift;

    #try by bgp
    my $filename = $configs_dir.'/'.$hostname.'_bgp.txt';

    my $er = '';
    if (open my $fh, '<', $filename) {
        my $file;
        {
            local $/;
            $file = <$fh>;
        }
        #    print $Fixtures_dir.'/cisco-ospf.txt';


        if ($file =~ m/BGP router identifier/sg) {
            return ("Cisco", '');
        } elsif ($file =~ m/Peer: \d+\.\d+\.\d+\.\d+\+\d+ AS \d+ Local: \d+\.\d+\.\d+\.\d+\+\d+ AS \d+/sg) {
            return ("Juniper", '');
        }
    } else {
        $er .= " $filename not found ";
    }
    #try by ospf
    $filename = $configs_dir.'/'.$hostname.'_ospf.txt';
    if (open my $fh, '<', $filename) {
        my $file;
        {
            local $/;
            $file = <$fh>;
        }
        #    print $Fixtures_dir.'/cisco-ospf.txt';
        #by OSPF
        if ($file =~ m/OSPF Router with ID \(.*?\) \(Process ID \d+\)/sg) {
            return ("Cisco", '');
        } elsif ($file =~ m/OSPF\s+database,\sArea/sg) {
            return ("Juniper", '');
        } elsif ($file =~ m/OSPF link state database, area/sg) {
            return ("Juniper", '');
        }

    } else {
        $er .= " $filename not found ";
    }
    $logger->debug("could not get host-type via config file format for $hostname");
    return ('unknown', $er);

}

1;

__END__
