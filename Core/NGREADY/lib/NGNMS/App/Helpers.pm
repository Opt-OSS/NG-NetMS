package NGNMS::App::Helpers;
use strict;
use warnings FATAL => 'all';
use Moo::Role;

use Emsgd qw(diag);
use Net::SNMP;
use Net::DNS::Resolver;
#with "NGNMS::Log4Role";

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $timeout);
@ISA = qw(Exporter);
@EXPORT_OK  = qw(
    ltrim rtrim trim
    getHostPart
    );
=header2
=cut
sub ltrim { my ($self,$s) = @_; $s =~ s/^\s+//;       return $s };
sub rtrim { my ($self,$s) = @_; $s =~ s/\s+$//;       return $s };
sub  trim {
    my ($self,$s) = @_;
    $s =~ s/^\s+|\s+$//g;
    return $s
};


sub getSysObjectID($$) {
    my $self= shift;
    my ($host, $community) = @_;
    my $req = '1.3.6.1.2.1.1.2.0';    # 'sysObjectID.0'
    my $version = '2c';

    my Net::SNMP $sess;
    my $err;
    ($sess, $err) = Net::SNMP->session(
        -hostname  => $host,
        -community => $community,
        -timeout=> 1.0,
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



# return host part of the full host name
sub getHostPart($) {
    my $self= shift;
    my $host = shift;
    return $host if $self->isIP( $host );
    $host =~ /^([^.]*)/;
    return $1;
}

# Do reverse DNS lookup
# Params: ip addr
# Return: host name or IP addr if lookup failed
#
sub reverseDNS {
    my $self= shift;
    my $ip_address = shift;
    my $result;
    my $res = Net::DNS::Resolver->new;
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

sub resolveHostName {
    my $self= shift;
    my $hostname = shift;
    my $result;
    my $res = Net::DNS::Resolver->new;
    my $resp = $res->search( $hostname );
#    diag ($resp);
    if ($resp) {
        foreach my $rr ($resp->answer) {
            next unless $rr->type eq "A";
            $result = $self->getHostPart($rr->address);
        }
    }

    return $result;
}

sub isIP{
    my $self = shift;
    my $host = shift;
    return 1 if  $host =~ /\d+\.\d+\.\d+\.\d+/;
    return 0;
}
1;