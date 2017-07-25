package NGNMS::Net::SNMPSessionRole;
use strict;
use warnings FATAL => 'all';
use Moo::Role;

use Emsgd qw /diag/;
with "NGNMS::Log4Role";

my ($community, $host_ip, $host_name);
sub connect($$$) {
    my $self = shift;
    ($community, $host_ip, $host_name) = @_;
}
sub queryAny($){
    my $self = shift;
    my $params = shift;
    return  $self->queryByIp( $params ) if $host_ip eq $host_name;
    return   $self->queryByHostname($params) || $self->queryByIp($params);
}
sub queryByHostname($) {

    my $self = shift;
    my $params = shift;
    return $self->_query( $host_name, $params );
}

sub queryByIp($) {

    my $self = shift;
    my $params = shift;
    return $self->_query( $host_ip, $params );
}

sub _query($$) {
    my $self = shift;
    my $host = shift;
    $self->logger->warn( "empty community for $host") && return unless $community;
    my $params = shift;
    my $oid = $params->{oid};
    return  unless $oid;
    my $version = $params->{version} || [ '2c', '1' ];
    my $miblist = $params->{miblist} || 'ALL';
    #    diag "($community, $host_ip, $host_name)";
    #    diag $version;
    for my $v (@$version) {
        my $cmd = "snmpget -v $v -m $miblist -c $community $host $oid";
        #        diag $cmd;
        my $r = $self->_run($cmd);
        return $r if $r;
    }
    return ;
}

sub _run($) {
    my $self = shift;
    my $cmd = shift;
#    diag $cmd;
    return `$cmd`;
}
1;