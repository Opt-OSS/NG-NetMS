package NGNMS::App::Crypt;

use strict;
use warnings FATAL => 'all';
use Moo;
use Emsgd qw(diag);
with "NGNMS::Log4Role";

#@returns NGNMS::DB
has DB => (is => 'ro', required => 1);
has username => (is => 'rw');
has password => (is => 'rw');
has privileged_password => (is => 'rw');
has transport => (is => 'rw');
has community => (is => 'rw');
has port => (is => 'rw');
has timeout => (is => 'rw');
has cryiptokey => (
        is      => 'lazy',
        builder => sub {
            my $self = shift;
            return  $self->DB->getCriptoKey()
        }
    );
sub decrypt {
    my ($self, $value) = (shift, shift);
    return undef unless defined $value;
    return  $self->DB->decryptAttrvalue($self->cryiptokey, $value);
}
=var
  maps credentials keys to attributes in DB
  in form cred=>db
=cut

my $attr_map = {
    transport           => 'transport',
    username            => 'login',
    password            => 'password',
    privileged_password => 'enpassword',
    timeout             => 'timeout',
    port                => 'port',
    connect_options          => 'cmdoptions',

};
sub copyTo {
    my $self = shift;
    my $encrypted = shift;
    my $credentials = shift;
    while (my ($cred_key, $enc_key) = each %$attr_map) {
        if ($enc_key eq 'transport'  && exists $encrypted->{'transport'}){
            $credentials->{$cred_key} = $encrypted->{$enc_key};
            next;
        }
        if ($enc_key eq 'cmdoptions' && exists $encrypted->{'cmdoptions'}){
            my @opts = split(/\s+/, $self->decrypt($encrypted->{cmdoptions}));
            $credentials->{connect_options} = \@opts;
        }else{
            $credentials->{$cred_key} = $self->decrypt($encrypted->{$enc_key}) if (exists $encrypted->{$enc_key});
        }
    }
}

sub decode_snmp_community {
    my $self = shift;
    my ($host, $community, ) = @_;
    my ($r_id, $t_arr, $last);
    #    $self->set_logger(ref($self).'.'.$host);
    $self->logger->warn("No default community provided") unless $community;
    #find router by IP or name
    $r_id = $self->DB->getRouterId($host);

    $self->logger->debug ("no SNMP community, router not found") && return $community unless defined $r_id;

    $t_arr = $self->DB->getRouterCommunity($r_id);
    # sa.community_ro,sa.community_rw
    if (exists $t_arr->{community_ro}) {
        #we get commounty in DB for this router, use it
        #use latest row if we have more then one
        #use sa.community_ro or fallback to sa.community_rw if undefined
        $community = $self->decrypt($t_arr->{community_ro});
        $self->logger->debug("Using DB SNMP Community by router  ID $r_id");
    }
    else {
        #we dont have individual community in DB for this router_id
        #try to find by  interface IP
        $r_id = $self->DB->getRouterByInterfaceIp($host);
        if ($r_id) {
            $t_arr = $self->DB->getRouterCommunity($r_id);
            if (exists $t_arr->{community_ro}) {
                #we get commounty in DB for this router, use it
                #use latest row if we have more then one
                #use sa.community_ro or fallback to sa.community_rw if undefined
                $community = $self->decrypt($t_arr->{community_ro});
                $self->logger->debug ("Using DB SNMP Community  by interface IP ");
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
        port                => $self->port,
        timeout             => $self->timeout,
        community           => $self->community,
        connect_options     => undef, # options aka '-i rsa_key allowe only from DB
    };
    my $credentials = $self->get_default_credentials();
    $credentials = $self->decode_router_access_method($host, $credentials);
    $credentials->{community} = $self->decode_snmp_community($host, $credentials->{community});
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
    my $default_access_method_id = $self->DB->decode_val_from_DB('default_access_method');
    my $default_community_id = $self->DB->decode_val_from_DB('default_community');
    my $credentials = {
        username            => undef,
        password            => undef,
        privileged_password => undef,
        transport           => undef,
        connect_options     => [],
        community           => undef,
        port                => undef,
        timeout             => undef,
    };
    my $encrypted;
    if ($default_community_id) {
        $encrypted = $self->DB->getCommunityById($default_community_id);
        if (exists $encrypted->{community_ro}) {
            $credentials->{community} = $self->decrypt($encrypted->{community_ro})
        }
    }

    $encrypted = $self->DB->getAccessById($default_access_method_id);
    $self->logger->warn("Default access method is not set or deleted") && return $credentials unless %{$encrypted};

    $self->copyTo($encrypted, $credentials);

    return  $credentials;

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
    my $credentials = shift; #defaults
    my $cmd_credetials = shift; #command line Should override other
    my $res = {
        community           => $cmd_credetials->{community} || $credentials->{community},
        username            => $cmd_credetials->{username} || $credentials->{username},
        password            => $cmd_credetials->{password} || $credentials->{password},
        privileged_password => $cmd_credetials->{privileged_password} || $credentials->{privileged_password},
        transport           => $cmd_credetials->{transport} || $credentials->{transport},
        connect_options     => $cmd_credetials->{connect_options} || $credentials->{connect_options},
        port                => $cmd_credetials->{port} || $credentials->{port},
        timeout             => $cmd_credetials->{timeout} || $credentials->{timeout},
    };
    if (exists $credentials->{jumphost}) {
        $res->{jumphost} = $credentials->{jumphost};
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
    my ($self, $host, $credentials) = (shift, shift, shift);
    $self->logger->debug("Checking if host-specific access exists");

    my $r_id = $self->DB->getRouterId($host);

    if (!defined $r_id) {
        $self->logger->debug("Router ID not found, using default access");
        #        diag $credentials;
        return $credentials;
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

        $self->logger->debug("Host-specific access not found, router ID $r_id, using default access");
        return $credentials;
    }

    $self->copyTo($encrypted,$credentials);
    if (exists $encrypted->{'jumphost'}) {
        $self->logger->debug("use JumHost for  router ID $r_id");
        my $defaults = $self->get_default_credentials();

        my $jumphos_enc = $encrypted->{jumphost};
        $self->logger->logdie('JumpHost IP required when use JumpHost') unless exists $jumphos_enc->{jumphost};
        $self->copyTo($jumphos_enc,$defaults);
        $defaults->{host} = $self->decrypt($jumphos_enc->{'jumphost'});
        $credentials->{jumphost} = $defaults;

    }
    $self->logger->debug ("Using DB Access method for $host with router_ID $r_id");
    #        diag($credentials);
    return $credentials;
}
1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
