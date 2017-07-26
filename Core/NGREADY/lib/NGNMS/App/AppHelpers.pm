package NGNMS::App::AppHelpers;

use strict;
use warnings FATAL => 'all';
use Moo::Role;
use Emsgd qw(diag);
=header2
=cut
sub getSysObjectID($$) {
    my ($host, $community) = @_;
    my $req = '1.3.6.1.2.1.1.2.0';    # 'sysObjectID.0'
    my $version = '2c';

    my Net::SNMP $sess;
    my $err;
    ($sess, $err) = Net::SNMP->session(
        -hostname  => $host,
        -community => $community
    );
    if (!defined( $sess )) {
        if ($err =~ /Unable to resolve destination address.*/) {
            return (undef, "$err");
        }
        return (undef, "SNMP: $err");
    }

    my $res = $sess->get_request( -varbindlist => [ $req ] );

    if (!defined( $res )) {

        $sess->close();
        ($sess, $err) = Net::SNMP->session(
            -hostname  => $host,
            -version   => $version,
            -community => $community
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

    return  ($res->{$req}, undef);
}

sub getHostCredentials($) {
    my $self = shift;
    my $host = shift;
    my $path_to_key;
    my ( $user, $passwd, $enpasswd, $access, $community ) = NGNMS::OLD::Util::get_default_credentials();
    ( $user, $passwd, $enpasswd, $access, $path_to_key ) = NGNMS::OLD::Util::decode_router_access_method( $host, $user, $passwd, $enpasswd, $access, $path_to_key );
    $community = NGNMS::OLD::Util::decode_snmp_community( $host, $community );
    return ( $user, $passwd, $enpasswd, $access, $path_to_key, $community)
}


1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
