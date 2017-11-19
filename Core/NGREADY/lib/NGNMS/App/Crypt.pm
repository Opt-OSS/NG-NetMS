package NGNMS::App::Crypt;

use strict;
use warnings FATAL => 'all';
use Moo;
use Emsgd qw(diag);
with "NGNMS::Log4Role";

#@returns NGNMS::DB
has DB => (is=>'ro', required=>1);
has username => (is => 'rw');
has password => (is => 'rw');
has privileged_password => (is => 'rw');
has transport => (is => 'rw');
has community => (is => 'rw');
sub decode_snmp_community {
    my $self = shift;
    my ($host, $community, ) = @_;
    my ($r_id, $t_arr, $last);
    #    $self->set_logger(ref($self).'.'.$host);
    $self->logger->warn("No default community provided") unless $community;

    $r_id = $self->DB->getRouterId($host);

    $self->logger->debug ("no SNMP community, router not found") && return $community unless defined $r_id;

    $t_arr = $self->DB->getCommunity($r_id);
    my $criptokey = $self->DB->getCriptoKey();
    # sa.community_ro,sa.community_rw
    if (@$t_arr) {
        #we get commounty in DB for this router, use it
        #use latest row if we have more then one
        #use sa.community_ro or fallback to sa.community_rw if undefined
        $last = @$t_arr[- 1];
        $community = $self->DB->decryptAttrvalue($criptokey, $last->[0] || $last->[1]);
        $self->logger->debug("Using DB SNMP Community founded by router  ID $r_id");
    }
    else {
        #we dont have individual community in DB for this router_id
        #try to find bu host name
        $t_arr = $self->DB->isDueCommunity($host);

        if (@$t_arr) {
            #count(ra.*) as ammount,r.router_id
            #use r.router_id  from last row
            $last = @$t_arr[- 1];
            $t_arr = $self->DB->getCommunity($last->[1]);
            if (@$t_arr) {
                #we get commounty in DB for that router, use it
                #use latest row if we have more then one
                #use sa.community_ro or fallback to sa.community_rw if undefined
                $last = @$t_arr[- 1];
                $community = $self->DB->decryptAttrvalue($criptokey, $last->[0] || $last->[1]);
                $self->logger->debug ("Using DB SNMP Community  founded by host name");
            }

        }
        else {
            $self->logger->debug ("Using Default SNMP Community");
        }
    }
    return $community;
}
#TODO clean jumhost returned values, remove unused,
sub getHostCredentials {
    my $self = shift;
    my $host = shift;
    #Command line options should override DB
    my $cmd_credentials = {
        username            => $self->username,
        password            => $self->password,
        privileged_password => $self->privileged_password,
        transport           => $self->transport,
        community           => $self->community,
        connect_options => undef, # options aka '-i rsa_key allowe only from DB
    };
    my $credentials = $self->get_default_credentials();
    $credentials = $self->decode_router_access_method($host, $credentials);
    #    diag $credentials;
    $credentials->{community} = $self->decode_snmp_community($host, $credentials->{community});
    #    diag $credentials;
    my $res = $self->credentials_override($credentials, $cmd_credentials);
    if (exists $res->{jumphost}) {
        delete $res->{jumphost}{transport};
        delete $res->{jumphost}{community};
        delete $res->{jumphost}{privileged_password};
    }
    return $res
}

=header2 get_default_credentials()
    retuns default connct credentials
=cut
sub get_default_credentials {
    my $self = shift;
    my $default_access_method = $self->DB->decode_val_from_DB('default_access_method');
    my $credetials = {
        username            => undef,
        password            => undef,
        privileged_password => undef,
        transport           => undef,
        connect_options     => [],
        community           => $self->DB->decode_val_from_DB('community'),
    };
    my $criptokey = $self->DB->getCriptoKey();

    my $encrypted = $self->DB->getAccessById($default_access_method);
    $self->logger->warn("Default access method is not set or deleted") && return $credetials unless %{$encrypted};
    $credetials->{transport} = $encrypted->{'transport'};
    $credetials->{username} = $self->DB->decryptAttrvalue($criptokey, $encrypted->{'login'})
        if exists $encrypted->{'login'};
    $credetials->{password} = $self->DB->decryptAttrvalue($criptokey, $encrypted->{'password'})
        if exists $encrypted->{'password'};
    $credetials->{privileged_password} = $self->DB->decryptAttrvalue($criptokey, $encrypted->{'enpassword'})
        if exists $encrypted->{'enpassword'};
    if (exists $encrypted->{'cmdoptions'}) {
        my @opts = split(/\s+/, $self->DB->decryptAttrvalue($criptokey, $encrypted->{cmdoptions}));
        $credetials->{connect_options} = \@opts;
    }
    return  $credetials;

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
    my $res = {
        username            => $cmd_credetials->{username} || $credetials->{username},
        password            => $cmd_credetials->{password} || $credetials->{password},
        privileged_password => $cmd_credetials->{privileged_password} || $credetials->{privileged_password},
        transport           => $cmd_credetials->{transport} || $credetials->{transport},
        community           => $cmd_credetials->{community} || $credetials->{community},
        connect_options     => $cmd_credetials->{connect_options} || $credetials->{connect_options},
    };
    if (exists $credetials->{jumphost}) {
        $res->{jumphost} = $credetials->{jumphost};
    }
    return $res;
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
sub decode_router_access_method {
    my ($self, $host, $credetials) = (shift, shift, shift);
    $self->logger->debug("Checking if roter specific access exists");

    my $r_id = $self->DB->getRouterId($host);

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

    my $encrypted = $self->DB->getRouterAccess($r_id);
    #    diag($encrypted);
    if (!scalar %{ $encrypted }) {

        $self->logger->debug("Roter specific access not found, router ID $r_id, using default access");
        return $credetials;
    }

    my $criptokey = $self->DB->getCriptoKey();

    $credetials->{transport} = $encrypted->{'transport'};
    $credetials->{username} = $self->DB->decryptAttrvalue($criptokey, $encrypted->{'login'})
        if exists $encrypted->{'login'};
    $credetials->{password} = $self->DB->decryptAttrvalue($criptokey, $encrypted->{'password'})
        if exists $encrypted->{'password'};
    $credetials->{privileged_password} = $self->DB->decryptAttrvalue($criptokey, $encrypted->{'enpassword'})
        if exists $encrypted->{'enpassword'};
    if (exists $encrypted->{'cmdoptions'}) {
        my @opts = split(/\s+/, $self->DB->decryptAttrvalue($criptokey, $encrypted->{cmdoptions}));
        $credetials->{connect_options} = \@opts;
    }
    if (exists $encrypted->{'jumphost'}) {
        $self->logger->debug("use JumHost for  router ID $r_id");
        my $defaults = $self->get_default_credentials();

        my $jumphos_enc = $encrypted->{jumphost};
        $self->logger->logdie('JumpHost IP required when use JumpHost') unless exists $jumphos_enc->{jumphost};
        $defaults->{host} = $self->DB->decryptAttrvalue($criptokey, $jumphos_enc->{'jumphost'});
        #        diag $jumphos_enc;
        $defaults->{username} = $self->DB->decryptAttrvalue($criptokey, $jumphos_enc->{'login'})
            if exists $jumphos_enc->{'login'};
        $defaults->{password} = $self->DB->decryptAttrvalue($criptokey, $jumphos_enc->{'password'})
            if exists $jumphos_enc->{'password'};
        if (exists $jumphos_enc->{'cmdoptions'}) {
            my @opts = split(/\s+/, $self->DB->decryptAttrvalue($criptokey, $jumphos_enc->{cmdoptions}));
            $defaults->{connect_options} = \@opts;
        }
        $credetials->{jumphost} = $defaults;

    }
    $self->logger->debug ("Using DB Access method for $host with router_ID $r_id");
    #    diag($credetials);
    return $credetials;
}
1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
