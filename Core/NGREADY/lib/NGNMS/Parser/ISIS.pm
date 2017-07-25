package NGNMS::Parser::ISIS;
use strict;
use warnings FATAL => 'all';
use Moo::Role;
use NGNMS::OLD::DB;
with "NGNMS::Log4Role";



sub parse_isis_juniper {
    my $self = shift;
    my $isis_file = shift;

    my %host_ips;
    my %links;

    open(F_ISISF, "<$isis_file") or
        return "error - ISIS file $isis_file: $!\n";

    #  skip_till(*F_ISISF,"^IS-IS level 2 link-state database:");

    my $host = '';
    my $state = '';
    my $bkst = 0;

    # skip header
    while (<F_ISISF>) {
        chomp;
        if (/^([-.\w]+|\d+\.\d+\.\d+\.\d+)\.(\d+)-(\d\d).*/) {
            $host = $1;
            $bkst = 0;
            if ("$2" ne "00") {
                $bkst = 1;
            }
            $self->logger->debug("Host: $host");
            NGNMS::OLD::DB::DB_addHostNoWrite( \%host_ips, $host);
            $state = 'host';
            last;
        }
    }
    return "Empty ISIS topology" if !length($host);

    my $ip_addr = "";

    while (<F_ISISF>) {
        chomp;            # no newline
        s/\s+$//;            # no trailing white

        #    print "$_\n";

        if (/^\s{1,4}(Hostname):\s+([-.\w]+|\d+\.\d+\.\d+\.\d+)$/) {
            #      print "$1: \"$2\"\n";
            if ($host ne $2) {
                print "Inconsistent ISIS file??? ($host, $2)\n";
            }
            next;
        }
        if (/^\s{1,4}(IP address):\s+(\d+\.\d+\.\d+\.\d+)/) {
            if ($state eq 'TLVs') {
                $ip_addr = $2;
                $self->logger->debug ( "$1: \"$ip_addr\"") ;
                NGNMS::OLD::DB::DB_addHostIP( \%host_ips, $host, $ip_addr );
            }
            next;
        }

        if (/^\s+TLVs:.*/) {
            $state = 'TLVs';
            next;
        }

        if (/^\s+IS neighbor:\s+([-.\w]+|\d+\.\d+\.\d+\.\d+)\.(\d+)\s+Metric:.*/) {
            # print "link $host $1\n";
            if (($state eq "host") and ($host ne $1)) {
                if (( "$2" ne "00") or $bkst) {
                    $self->logger->debug(  "=====>>> Broadcast link $host $2 <<<=====" );
                    NGNMS::OLD::DB::DB_addLinkNoWrite( \%links, $host, $1, "B" );
                } else {
                    NGNMS::OLD::DB::DB_addLinkNoWrite( \%links, $host, $1, "P" );
                }
            }
            next;
        }

        if (/^\s+IS neighbor:\s+([-.\w]+|\d+\.\d+\.\d+\.\d+)\.\d+,.*/) {
            $state = 'Neighbor' if $state eq 'TLVs';
            next;
        }

        # end of this record
        if (/^([-.\w]+|\d+\.\d+\.\d+\.\d+)\.(\d+)-\d\d.*/) {
            $host = $1;
            $self->logger->debug(  "Host: $host" );
            $bkst = 0;
            if ("$2" ne "00") {
                $bkst = 1;
            }
            NGNMS::OLD::DB::DB_addHostNoWrite( \%host_ips, $host);
            $state = 'host';
        }
    }
    close(F_ISISF);

    NGNMS::OLD::DB::DB_writeTopology( \%host_ips, \%links );
    return "ok";
}
sub parse_isis_cisco {
    my $self = shift;
    my $isis_file = shift;

    my %host_ips;
    my %links;
    my $host = '';
    my $bkst = 0;

    open( F_ISISF, "<$isis_file" ) or return "error - ISIS file $isis_file: $!";

    #skip_till(*F_ISISF,"^IS-IS Level-2 Link State Database");

    # skip header
    while (<F_ISISF>) {
        chomp;
        if (/^([-\w\.]+|\d+\.\d+\.\d+\.\d+)\.(\d+)-\d\d.*/) {
            $host = $1;
            $bkst = 0;
            if ("$2" ne "00") {
                $bkst = 1;
            }
            NGNMS::OLD::DB::DB_addHostNoWrite( \%host_ips, $host );
            last;
        }
    }

    return "Empty ISIS topology" if !length( $host );

    $self->logger->info(  "ISIS parser Host: $host");

    while (<F_ISISF>) {
        chomp;            # no newline
        s/\s+$//;            # no trailing white

        #    print "$_\n";

        if (/^\s+(Hostname):\s+(\d+\.\d+\.\d+\.\d+)$/ or
            /^\s+(Hostname):\s+([-\w\.]+)$/) {
            #      print "$1: \"$2\"\n";
            if ($host ne $2) {
                print "Inconsistent ISIS file??? ($host, $2)\n";
            }
            next;
        }
        if (/^\s+(IP Address):\s+(\d+\.\d+\.\d+\.\d+)/) {
            #      print "$1: \"$2\"\n";
            NGNMS::OLD::DB::DB_addHostIP( \%host_ips, $host, $2 );
            next;
        }

        # First match the case with IP address
        if (/^\s+Metric:\s+\d+\s+IS(-Extended)*\s+(\d+\.\d+\.\d+\.\d+)\.(\d+).*/) {
            if ($host ne $2) {
                if (( "$3" ne "00") or $bkst) {
                    $self->logger->debug(  "=====>>> Broadcast link $host $2 <<<=====" );
                    NGNMS::OLD::DB::DB_addLinkNoWrite( \%links, $host, $2, "B" );
                } else {
                    NGNMS::OLD::DB::DB_addLinkNoWrite( \%links, $host, $2, "P" );
                }
            }
            next;
        }

        # Then try the host name
        if (/^\s+Metric:\s+\d+\s+IS(-Extended)*\s+([-\w\.]+)\.(\d+).*/) {
            if ($host ne $2) {
                if (( "$3" ne "00") or $bkst) {
                    $self->logger->debug(  "=====>>> Broadcast link $host $2 <<<=====" );
                    NGNMS::OLD::DB::DB_addLinkNoWrite( \%links, $host, $2, "B" );
                } else {
                    NGNMS::OLD::DB::DB_addLinkNoWrite( \%links, $host, $2, "P" );
                }
            }
            next;
        }

        # end of this record
        if (/^([-\w\.]+|\d+\.\d+\.\d+\.\d+)\.(\d+)-\d\d.*/) {
            $host = $1;
            $bkst = 0;
            if ("$2" ne "00") {
                $bkst = 1;
            }
            $self->logger->debug(  "Host: $host" );
            NGNMS::OLD::DB::DB_addHostNoWrite( \%host_ips, $host );
        }
    }
    close( F_ISISF );

    NGNMS::OLD::DB::DB_writeTopology( \%host_ips, \%links );

    return "ok";
    }
1;