#
# NextGen NMS
#
# NGNMS::OLD::NGNMS_Linux.pm: interfacing with Linux servers
#
# Copyright (C) 2002,2003 OptOSS LLC
# Copyright (C) 2014 Opt/Net BV
#
# Author: T.Matselyukh, A. Jaropud
#

package NGNMS::Host::Linux;

use strict;
use warnings;

no warnings qw(redefine);  # !!! SUPPRESS Subroutine new redefined at warniongs

use Net::Telnet;
use Net::OpenSSH;
use Data::Dumper;
use NGNMS::OLD::DB;
use NGNMS::Log4;
use NGNMS::OLD::Util;
use Try::Tiny;
use JSON::Parse 'json_file_to_perl';
#@depricated
use Net::IPv4Addr; #TODO get read of
use Net::Netmask;
use Emsgd qw(diag);

my $module_version = '3.4.1';
#print "using NGNMS::OLD::NGNMS_Linux.pm, version $module_version\n";

require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $data);

@ISA = qw(Exporter AutoLoader);

## set the version for version checking; uncomment to use
$VERSION = 3.41;

use constant NR_DEFAULT_ROUTE4 => '0.0.0.0/0';
use constant NR_DEFAULT_ROUTE6 => '::/0';
use constant NR_LOCAL_ROUTE4 => '0.0.0.0';
use constant NR_LOCAL_ROUTE6 => '::';

our %EXPORT_TAGS = (
    constants => [ qw(
        NR_DEFAULT_ROUTE4
        NR_DEFAULT_ROUTE6
        NR_LOCAL_ROUTE4
        NR_LOCAL_ROUTE6
        ) ],
);

@EXPORT = qw(
    linux_get_topologies
    );

# your exported package globals go here,
# as well as any optionally exported functions
@EXPORT_OK = qw($data @{$EXPORT_TAGS{constants}});

my $Log = NGNMS::Log4->new();
my $logger = $Log->get_new_category_logger(__PACKAGE__);

$data = "my data";

# Preloaded methods

my $username;
my $password;
my $timeout = 10;                                        # network operations and command timeout
my $cmd2 = 'ls /tmp/mc-ngnms';
my $debug = 0;
my $src_folder_name = '/tmp/mc-ngnms';
my $dst_folder_name = '/var/www/ngnms_perl/test';



my NGNMS::Net::Connect $session;
my $Error;

sub linux_create_session {
    my $connect_params = shift;
    $connect_params->{personality}='bash';
    $connect_params->{requires_privileged} = 0;
    $connect_params->{privileged_paging} = 0;
    $connect_params->{wake_up} = 0;
#    $connect_params->{do_paging} = 0;
    $connect_params->{connect_options} = { opts => $connect_params->{connect_options} } ;
    if (exists $connect_params->{jumphost}) {
        push @{ $connect_params->{jumphost}{connect_options} },('-p',$connect_params->{jumphost}{port}) if $connect_params->{jumphost}{port};
        $connect_params->{jumphost} = Net::Appliance::Session->new(
            transport       => 'SSH',
            personality     => 'bash',
            timeout         => $connect_params->{jumphost}{timeout} || 10,
            host            => $connect_params->{jumphost}{host},
            username        => $connect_params->{jumphost}{username},
            password        => $connect_params->{jumphost}{password},
            connect_options => { opts => $connect_params->{jumphost}{connect_options} },

        );
    }
    #        diag $connect_params;
    $Log->put_debug_key('host',$connect_params->{host});

    try {
        $session->close();
    }catch{};
    undef $session;
    $session = NGNMS::Net::Connect->new( $connect_params );

    return try{
        $session->connect();
        return 'ok';
    }catch{
        $Error = $_;
        $logger->error( $Error);
        #last resonce could throw exception if port was not opened :connection refused etc
        try {$Error = $session->last_response();}catch{};
        $Error =  $connect_params->{host}.": ".$Error;
        $logger->error( $Error);
        return $Error;
    };
    return $Error;
}
sub linux_get_topologies{
    my ($connect_params) = shift;

    linux_create_session( $connect_params );
    return $Error if $Error;

    my $host = $connect_params->{'host'} ;
    #    return $sess;
    my @nets = $session->cmd( "netstat -rn" );

    #    Emsgd::diag(\@nets);

    $session->close();

    my @routes = ();
    my %cache = ();
    my %host_ips;
    my %links;
    my $state = '';
    my $DR = '';
    for my $line (@nets) {
        my @toks = split( /\s+/, $line );
        my $route = $toks[0];
        my $gateway = $toks[1];
        my $netmask = $toks[2];
        my $flags = $toks[3];
        my $mss = $toks[4];
        my $window = $toks[5];
        my $irtt = $toks[6];
        my $interface = $toks[7];

        if (defined( $route ) && defined( $gateway ) && defined( $interface )
            && defined( $netmask )) {
            # A first sanity check to help Net::IPv4Addr
            if ($route !~ /^[0-9\.]+$/ || $gateway !~ /^[0-9\.]+$/
                || $netmask !~ /^[0-9\.]+$/) {
                next;
            }

            eval {
                my ($ip1, $cidr1) = Net::IPv4Addr::ipv4_parse( $route );
                my ($ip2, $cidr2) = Net::IPv4Addr::ipv4_parse( $gateway );
                my ($ip3, $cidr3) = Net::IPv4Addr::ipv4_parse( $netmask );
            };
            if ($@ && $debug > 0) {
                chomp( $@ );
                $logger->debug( "*** DEBUG - Not valid line [$@]");
                next;                                                                   # Not a valid line for us.
            }

            # Ok, proceed.
            my %route = (
                route     => $route,
                gateway   => $gateway,
                interface => $interface,
            );

            # Default route
            if ($route eq '0.0.0.0' && $netmask eq '0.0.0.0') {
                $route{default} = 1;
                $route{route} = NR_DEFAULT_ROUTE4();
            }
            else {
                my ($ip, $cidr) = Net::IPv4Addr::ipv4_parse( "$route / $netmask" );
                $route{route} = "$ip/$cidr";
            }

            # Local subnet
            if ($gateway eq '0.0.0.0') {
                $route{local} = 1;
                $route{gateway} = NR_LOCAL_ROUTE4();
            }

            my $id = _to_psv( \%route );
            if (!exists( $cache{$id} )) {
                push @routes, \%route;
                $cache{$id}++;
            }
        }
    }
    #    Emsgd::diag(\@routes);
    NGNMS::OLD::DB::DB_addHostNoWrite( \%host_ips, $host );
    NGNMS::OLD::DB::DB_addHostIP( \%host_ips, $host, $host );
    for my $route(@routes) {
        if ($route->{default} || $route->{gateway} && $route->{gateway} ne '0.0.0.0') {
            my $ip = $route->{gateway};
            $DR = $ip;
            NGNMS::OLD::DB::DB_addHostNoWrite( \%host_ips, $DR );
            NGNMS::OLD::DB::DB_addHostIP( \%host_ips, $DR, $ip );
            NGNMS::OLD::DB::DB_addLinkNoWrite( \%links, $host, $DR, "B" );
        }
    }
    #    Emsgd::diag(\%links);
    #    Emsgd::diag(\%host_ips);
    NGNMS::OLD::DB::DB_writeTopology( \%host_ips, \%links );
    NGNMS::OLD::DB::DB_setHostVendorByIP( $host, 'Linux' );

    return "ok";

}

sub _to_psv {
    my ($route) = @_;

    my $psv = $route->{route}.'|'.$route->{gateway}.'|'.$route->{interface}.'|'.
        (exists( $route->{default} ) ? '1' : '0').'|'.(exists( $route->{local} ) ? '1' : '0');

    return $psv;
}

1;
# ABSTRACT: This file is part of open source NG-NetMS tool.

__END__
