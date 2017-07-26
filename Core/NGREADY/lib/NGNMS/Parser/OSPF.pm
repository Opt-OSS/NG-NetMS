package NGNMS::Parser::OSPF;

use strict;
use warnings FATAL => 'all';
use Moo::Role;
use NGNMS::OLD::DB;


with "NGNMS::Log4Role" ;

sub parse_ospf_cisco {
    my $self = shift;
    my $ospf_file = shift;

    my %host_ips;
    my %links;
    my %areas;      # Map areas to DRs
    my $host = '';
    my $state = '';
    my $DR = '';

    open( F_OSPFF, "<$ospf_file" ) or return "error - OSPF file $ospf_file: $!";

    # skip header
    while (<F_OSPFF>) {
        chomp;
        #print $_;
        if (/^\s+Link State ID:\s+(\d+\.\d+\.\d+\.\d+).*/) {
            my $ip = $1;
            $host = $ip;
            $self->logger->info(  "OSPF parser Host:", $host );
            $state = 'host';
            NGNMS::OLD::DB::DB_addHostNoWrite( \%host_ips, $host );
            NGNMS::OLD::DB::DB_addHostIP( \%host_ips, $host, $ip );
            last;
        }
    }

    return "Empty OSPF topology" if !length( $host );

    while (<F_OSPFF>) {
        chomp;            # no newline
        s/\s+$//;            # no trailing white

        $self->logger->debug(  $_ );

        if (/^\s+Link connected to: another Router \(point-to-point\).*/) {
            # print "link $host $1\n";
            if ($state eq "host") {
                $state = 'linkP';
            }
            next;
        }

        if (/^\s+Link connected to: a Transit Network.*/) {
            # print "link $host $1\n";
            if ($state eq "host") {
                $state = 'linkB';
            }
            next;
        }

        if (/^\s+\(Link ID\) Neighboring Router ID:\s+(\d+\.\d+\.\d+\.\d+).*/) {
            # print "link $host $1\n";
            if (($state eq "linkP") and ($host ne $1)) {
                NGNMS::OLD::DB::DB_addLinkNoWrite( \%links, $host, $1, "P" );
            }
            if (($state eq "linkB") and ($host ne $1)) {
                NGNMS::OLD::DB::DB_addLinkNoWrite( \%links, $host, $1, "B" );
            }
            next;
        }

        if (/^\s+\(Link ID\) Designated Router address:\s+(\d+\.\d+\.\d+\.\d+).*/) {
            # print "link $host $1\n";
            if ($state eq "linkB") {
                my $ip = $1;
                $DR = $ip;
                NGNMS::OLD::DB::DB_addHostNoWrite( \%host_ips, $DR );
                NGNMS::OLD::DB::DB_addHostIP( \%host_ips, $DR, $ip );
                NGNMS::OLD::DB::DB_addLinkNoWrite( \%links, $host, $DR, "B" );
            }
            next;
        }

        if (/^\s+\(Link Data\) Router Interface address:\s+(\d+\.\d+\.\d+\.\d+).*/) {
            # print "link $host $1\n";
            if (($state eq "linkB") and ($DR eq $1)) {
                if (!defined( $areas{$DR} )) {
                    $areas{$DR} = $host;
                }
            }
            next;
        }

        # end of this record
        if (/^\s+Link State ID:\s+(\d+\.\d+\.\d+\.\d+).*/) {
            my $ip = $1;
            $host = $ip;
            $self->logger->debug(  "Host: $host" );
            NGNMS::OLD::DB::DB_addHostNoWrite( \%host_ips, $host );
            NGNMS::OLD::DB::DB_addHostIP( \%host_ips, $host, $ip );
            $state = 'host';
        }
    }
    close( F_OSPFF );

    # replace all areas with corresponding Designated routers
    foreach my $area (keys %areas) {
        if ($area ne $areas{$area}) {
            NGNMS::OLD::DB::DB_dropHost( \%host_ips, $area );
            NGNMS::OLD::DB::DB_replaceHost( \%links, $area, $areas{$area} );
        }
    }

    NGNMS::OLD::DB::DB_writeTopology( \%host_ips, \%links );

    return "ok";
}

sub parse_ospf_juniper {
    my $self = shift;
    my $ospf_file = shift;

    my %host_ips;
    my %links;
    my %areas;      # Map areas to DRs

    open(F_OSPFF, "<$ospf_file") or
        return "error - OSPF file $ospf_file: $!\n";

    my $host = '';
    my $network = '';
    my $state = '';

    # skip header
    while (<F_OSPFF>) {
        chomp;
        if (/^Router\s+\**(\d+\.\d+\.\d+\.\d+).*/) {
            my $ip = $1;
            $host = $ip;
            $self->logger->debug(  "Host: $host" );
            NGNMS::OLD::DB::DB_addHostNoWrite( \%host_ips, $host);
            NGNMS::OLD::DB::DB_addHostIP( \%host_ips, $host, $ip);
            $state = 'host';
            last;
        }
    }
    return "Empty OSPF topology" if !length($host);


    while (<F_OSPFF>) {
        chomp;            # no newline
        s/\s+$//;            # no trailing white

        #    print "$_\n";

        if (/^\s+id\s+(\d+\.\d+\.\d+\.\d+),\s+data\s+(\d+\.\d+\.\d+\.\d+),\s+Type\s+PointToPoint\s+.*/) {
            # print "link $host $1\n";
            if (($state eq "host") and ($host ne $1)) {
                NGNMS::OLD::DB::DB_addLinkNoWrite( \%links, $host, $1, "P" );
            }
            next;
        }

        if (/^\s+id\s+(\d+\.\d+\.\d+\.\d+),\s+data\s+(\d+\.\d+\.\d+\.\d+),\s+Type\s+Transit\s+.*/) {
            # print "link $host $1\n";
            if (($state eq "host") and ($host ne $1)) {
                NGNMS::OLD::DB::DB_addLinkNoWrite( \%links, $host, $1, "B" );
            }
            next;
        }

        # end of this record
        if (/^Router\s+\**(\d+\.\d+\.\d+\.\d+).*/) {
            my $ip = $1;
            $host = $ip;
            $self->logger->debug( "Host: $host" );
            NGNMS::OLD::DB::DB_addHostNoWrite( \%host_ips, $host);
            NGNMS::OLD::DB::DB_addHostIP( \%host_ips, $host, $ip);
            $state = 'host';
            next;
        }

        if (/^Network\s+\**(\d+\.\d+\.\d+\.\d+)\s+(\d+\.\d+\.\d+\.\d+).*/) {
            $areas{$1} = $2;
            $self->logger->debug(  "Network: area{$1} $2" );
            $state = 'Network';
            next;
        }

        if (/^(OpaqArea|Summary)\s+.*/) {
            $state = $1;
            next;
        }
    }
    close(F_OSPFF);

    # replace all areas with corresponding Designated routers
    foreach my $area (keys %areas) {
        if ($area ne $areas{$area}) {
            NGNMS::OLD::DB::DB_replaceHost( \%links, $area, $areas{$area});
            NGNMS::OLD::DB::DB_dropHost( \%host_ips, $area);
        }
    }

    NGNMS::OLD::DB::DB_writeTopology( \%host_ips, \%links );
    return "ok";
}
1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
