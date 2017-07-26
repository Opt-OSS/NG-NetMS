package NGNMS::App::Crypt;

use strict;
use warnings FATAL => 'all';
use Moo::Role;
use Emsgd qw(diag);
with "NGNMS::Log4Role";
requires qw(DB);

with "NGNMS::Log4Role";
sub decode_snmp_community {
    my $self = shift;
    my ($host, $community, ) = @_;
    my ($r_id, $t_arr, $last);
#    $self->set_logger(ref($self).'.'.$host);
    $self->logger->warning("No default community provided") unless  $community;

    $r_id = $self->DB->getRouterId( $host );

    $self->logger->debug ("no SNMP community, router not found") && return $community unless defined $r_id;

    $t_arr = $self->DB->getCommunity( $r_id );
    my $criptokey = $self->DB->getCriptoKey();
    # sa.community_ro,sa.community_rw
    if (@$t_arr)
    {
        #we get commounty in DB for this router, use it
        #use latest row if we have more then one
        #use sa.community_ro or fallback to sa.community_rw if undefined
        $last = @$t_arr[-1];
        $community = $self->DB->decryptAttrvalue( $criptokey, $last->[0] || $last->[1] );
        $self->logger->debug( "Using DB SNMP Community founded by router  ID $r_id");
    }
    else
    {
        #we dont have individual community in DB for this router_id
        #try to find bu host name
        $t_arr = $self->DB->isDueCommunity( $host );

        if (@$t_arr) {
            #count(ra.*) as ammount,r.router_id
            #use r.router_id  from last row
            $last = @$t_arr[-1];
            $t_arr = $self->DB->getCommunity( $last->[1] );
            if (@$t_arr) {
                #we get commounty in DB for that router, use it
                #use latest row if we have more then one
                #use sa.community_ro or fallback to sa.community_rw if undefined
                $last = @$t_arr[-1];
                $community = $self->DB->decryptAttrvalue( $criptokey, $last->[0] || $last->[1] );
                $self->logger->debug ("Using DB SNMP Community  founded by host name");
            }

        } else {
            $self->logger->debug ("Using Default SNMP Community");
        }
    }
    return $community;
}



sub getHostCredentials {
    my $self = shift;
    my $host = shift;
    #Command line options should override DB
    my $cmd_credentials = {
        username                => $self->host_user,
        password            => $self->host_password,
        privileged_password => $self->host_priveleged_password,
        transport           => $self->host_transport,
        community           => $self->host_community,
        connect_options     => undef, # options aka '-i rsa_key allowe only from DB
    };
    my $credentials = $self->get_default_credentials();
    $credentials = $self->decode_router_access_method( $host, $credentials );
#    diag $credentials;
    $credentials->{community} = $self->decode_snmp_community( $host, $credentials->{community} );
#    diag $credentials;
    return $self->credentials_override($credentials,$cmd_credentials);
}

=header2 get_default_credentials()
    retuns default connct credentials
=cut
sub get_default_credentials {
    my $self = shift;
    return  {
        username            => $self->DB->decode_val_from_DB( 'username' ),
        password            => $self->DB->decode_val_from_DB( 'password' ),
        privileged_password => $self->DB->decode_val_from_DB( 'enpassword' ),
        transport           => $self->DB->decode_val_from_DB( 'type access' ),
        community           => $self->DB->decode_val_from_DB( 'community' ),
        connect_options     => $self->DB->decode_val_from_DB( 'cmdoptions' ) || [],
    };

}
#=for credentials_override($credentials, $command_line)
#
#Make priority for command line options
#$credentials, $command_line =: hashref of $access type in decode_router_access_method
#
#
#=cut
sub credentials_override($$) {
    my $self = shift;
    my $credetials = shift; #defaults
    my $cmd_credetials = shift; #command line Should override other
    return  {
        username                => $cmd_credetials->{username} || $credetials->{username},
        password            => $cmd_credetials->{password} || $credetials->{password},
        privileged_password => $cmd_credetials->{privileged_password} || $credetials->{privileged_password},
        transport           => $cmd_credetials->{transport} || $credetials->{transport},
        community           => $cmd_credetials->{community} || $credetials->{community},
        connect_options     => $cmd_credetials->{connect_options} || $credetials->{connect_options},
    };
}

#=for decode_router_access_method($host,$access)
#
#$host = host IP or name
#$access  hash with current connect options
#        {
#            username=>'root',
#            password=>'secret',
#            privileged_password=>'enable',
#            transport=>'SSHv2',
#            community=>'public'
#            connect_options=>[' -i',' ./id_rsa']
#        };
#
#priopity is command_line -> router specific -> defaults
#
#=cut
sub decode_router_access_method($$) {
    my $self = shift;
    my $host = shift;
    my $credetials = shift; #defaults
    $self->logger->debug( "Checking if roter specific access exists");

    my $r_id = $self->DB->getRouterId( $host );

    if (!defined $r_id) {
        $self->logger->debug("Router ID not found, using defauls access");
#        diag $credetials;
        return $credetials;
    }
    #    my $arr_param6 = NGNMS_DB::DB_isInRouterAccess( $host );    # check if special access to router exists
    #    return  ( $user, $passwd, $enpasswd, $access, $path_to_key ) unless @$arr_param6;
    #
    #    #found ruter id in access tables, use last founded (there are could be more then one record for router and interface IP)
    #    #use credentials from DB
    #    my $last = @$arr_param6[-1];
    #    my $r_id = $last->{router_id};

    my $encoded = $self->DB->getRouterAccess( $r_id );
    if (!@$encoded) {

        $self->logger->debug( "Roter specific access not found, router ID $r_id, using default access");
        return $credetials;
    }

    my $criptokey = $self->DB->getCriptoKey();

    foreach my $par (@$encoded) {
        next unless defined $par->[0];

        $credetials->{transport} = $par->[0];
        my $flag = lc( $par->[2] );
        if ($flag eq 'login') {
            $credetials->{username} = $self->DB->decryptAttrvalue( $criptokey, $par->[3] );
        }
        if ($flag eq 'password') {
            $credetials->{password} = $self->DB->decryptAttrvalue( $criptokey, $par->[3] );
        }
        if ($flag eq 'enpassword') {
            $credetials->{privileged_password} = $self->DB->decryptAttrvalue( $criptokey, $par->[3] );
        }

        if ($flag eq 'cmdoptions') {
            my @opts = split(/\s+/,$self->DB->decryptAttrvalue( $criptokey, $par->[3])) ;
            $credetials->{connect_options} = \@opts;
        }
        # TODO connect_options
        #        if ($flag eq 'path_to_key')    #path to key
        #        {
        #            $path_to_key = $self->DB->decryptAttrvalue( $criptokey, $par->[3] );
        #        }
    }
    $self->logger->debug ("Using DB Access method for $host with ID $r_id\n");

    return $credetials;;
}
1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
