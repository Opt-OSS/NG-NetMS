package  NGNMS::SubnetScanner;

use strict;
use warnings FATAL => 'all';
no warnings qw(redefine);  # !!! SUPPRESS Subroutine new redefined at warniongs
use feature qw(say switch);
use Net::Netmask;
use NGNMS::OLD::DB;
use File::Path qw( make_path );
use Sort::Key::IPv4 qw(ripv4keysort);
use NGNMS::OLD::Util;
use  Array::Split;
use Emsgd qw /diag/;
use IO::File;
use Scalar::Util qw(blessed dualvar isdual readonly refaddr reftype
    tainted weaken isweak isvstring looks_like_number
    set_prototype);

use Moo;
use MooX::Types::MooseLike::Base qw(Bool Int Str HashRef InstanceOf);

with "NGNMS::Log4Role";
#@returns NGNMS::DB
has DB => (
        is => 'rw',
    );

has dryrun => (
        is      => 'rw',
        default => sub {0},
    );

has workdir => (
        is      => 'rw',
#        default => sub {$ENV{"NGNMS_DATA"}.'/tmp'},
        builder=>1,
    );
has excludefile => (
        is      => 'rw',
        default => 'scanner_mass_excludes.txt',
    );
has excludewildcard => (
        is      => 'rw',
        default => sub {qr/127.*|128.*/},
    );
has rangefile => (
        is      => 'rw',
        isa     => Str,
        default => 'scanner_mass_ranges.txt',
    );
has hostsfile_raw => (
        is      => 'rw',
        isa     => Str,
        default => 'scanner_hostsfile_raw.txt',
    );
has hostsfile => (
        is      => 'rw',
        isa     => Str,
        default => 'scanner_hostsfile.txt',
    );
has pollfile => (
        is      => 'rw',
        isa     => Str,
        default => 'scanner_poll.txt',
    );
has scan_engine => (
        is      => 'rw',
        isa     => Str,
        default => 'nmap',
    );
has nmap_cmd => (
        is      => 'rw',
        isa     => Str,
        default => '/usr/bin/nmap',
    );
has nmap_rate => (
        is      => 'rw',
        default => 1000,
    );
has masscan_cmd => (
        is      => 'rw',
        isa     => Str,
        default => sub {$ENV{"NGNMS_HOME"}.'/bin/masscan'},
    );
has masscan_rate => (
        is      => 'rw',
        default => 1000,
    );

has verbose_level => (
        is      => 'ro',
        default => "0",
    );

has netBlocks => (
        is      => 'rw',
        default => sub {return { }}
    );
sub _build_workdir {
    my ($self) = @_;
    my $wd = ($ENV{"NGNMS_DATA"} || '.').'/tmp';
    $self->logger->error ("creating ".$wd);
    make_path  $wd;
    $self->logger->logdie ("Cannot create directory $wd: $!\n") unless -d $wd;
    return $wd;};
sub clear_workdir {
    my ($self) = @_;
    $self->logger->debug ("clearing ".$self->workdir."/scanner_*.txt");
    unlink glob "'".$self->workdir."/scanner_*.txt'";
};


sub getNetblockInterfaceIP {
    my ($self, $search_ip) = @_;
    return unless defined $self->netBlocks;
    my $block = Net::Netmask::findNetblock($search_ip, $self->netBlocks);
    return unless defined $block;
    return $block->{interface_ip};
}

sub storeNetBlockInterface {
    my $self = shift;
    my $net_str = shift;
    my $ip = shift || '255.255.255.255';
    my $net = Net::Netmask->new($net_str);
    $self->netBlocks({ }) unless defined $self->netBlocks;
    if (!$net->checkNetblock($self->netBlocks)) {
        $net->{interface_ip} = $ip if $net->match($ip);
        $net->{as_string} = $net_str;
        $net->storeNetblock($self->netBlocks);
        return;
    }
    #    return unless defined $ip ;
    my $block = Net::Netmask::findNetblock($ip, $self->netBlocks); #snallest block ip belongs to
    $block->{interface_ip} = $ip if !defined ($block->{interface_ip}) || (NGNMS::OLD::Util::ip2num($ip) ge NGNMS::OLD::Util::ip2num($block->{interface_ip}));
};
sub aggregate_nets {
    my ($self) = @_;

    my $nets_to_scan = $self->DB->getNetworksToScan();
    my @sane_nets = grep  { !(@$_[0] =~ /^127|^128/) }@$nets_to_scan;
    # [ ['ip/mask','interface_ip, [...], ... ]
    my @ret;
    for (@sane_nets) {

        my $n = Net::Netmask->new(@$_[0]);#create netblock from 'ip/mask'
        $self->storeNetBlockInterface(@$_[0], @$_[1]);#store netblock and interface in networks table
        push @ret, $n if $n->bits() < 32; #skip /32 nets
    }
    return Net::Netmask::cidrs2cidrs (@ret);#return aggregated
}


=pod
@params
=cut nets_to_scan array_ref  to  Net::Netmask objects, returned by aggregate_nets
sub split_nets {
    #Split networks on subnets by given bit-maks (24 is /24 etc)
    my $self = shift;
    my ($nets_to_scan, $split_bits) = @_;

    $split_bits = $split_bits || 24;
    my @ret;
    for my Net::Netmask $net (@$nets_to_scan) {

        my $split = int (2 ** ($split_bits - $net->bits())) || 1;
        push @ret, $net->split($split);
    }

    return @ret;
}


sub parse_nework_blocks {
    my ($self, $split_bits) = @_;
    $split_bits = $split_bits || 24;
    my @aggr = $self->aggregate_nets();
    @aggr = $self->split_nets(\@aggr, $split_bits);
    $self->logger->debug( "prepared ".scalar(@aggr)." networks to scan");

    return @aggr;
}

sub create_range_file {
    my ($self, $ranges_ref ) = @_;
    my $fh = IO::File->new($self->workdir.'/'.$self->rangefile, 'w');
    if (defined $fh) {
        print $fh  join "\n", @$ranges_ref;
        undef $fh;
    } else {
        $self->logger->logdie( "Could not create ranges file");
    }
}
sub create_exclude_file {
    #todo move DB query to sub
    my ($self) = @_;
    my $excludes = $self->DB->getScanException();
    #    Emsgd::diag($self->excludefile);
    my $fh = IO::File->new($self->workdir.'/'.$self->excludefile, 'w');
    if (defined $fh) {
        print $fh  join "\n", @$excludes;
        undef $fh;
    } else {
        $self->logger->logdie( "Could not create excludes file ".$self->workdir.'/'.$self->excludefile);
    }
}

sub create_cmd{
    my $self = shift;
    if ($self->scan_engine eq 'masscan') {
        return $self->create_masscan_cmd;
    }
    return $self->create_nmap_cmd;
}
sub create_masscan_cmd {
    my ($self) = @_;
    my $scancmd = $self->masscan_cmd." -p22,23,161 --rate=1000 --wait=5";
    $scancmd .= " -oL ".$self->workdir.'/'.$self->hostsfile_raw."  ";
    $scancmd .= " --excludefile ".$self->workdir.'/'.$self->excludefile."  ";
    $scancmd .= " -iL ".$self->workdir.'/'.$self->rangefile."  ";
    $scancmd .= " --offline" if $self->dryrun;
    $self->logger->debug($scancmd);
    return $scancmd;
}
sub create_nmap_cmd {
    my ($self) = @_;
    my $scancmd;
    if ($self->dryrun) {
        $scancmd = $self->nmap_cmd." -sL -n ";

    } else {
        $scancmd = $self->nmap_cmd." --randomize-hosts --disable-arp-ping -n -sS -Pn -p22,23,161 -T5 --max-rate=".$self->nmap_rate;

    }
    $scancmd .= " -oG ".$self->workdir.'/'.$self->hostsfile_raw."  ";
    $scancmd .= " --excludefile ".$self->workdir.'/'.$self->excludefile."  ";
    $scancmd .= " -iL ".$self->workdir.'/'.$self->rangefile."  ";
    $scancmd .= " --append-output ";
    $scancmd .= " --stats-every=10s ";
    $scancmd .= " -v ".$self->verbose_level;
    #    Emsgd::diag($scancmd);
    $self->logger->debug($scancmd);
    return $scancmd;
}

sub execute_scan {
    my ($self, $read_file_handler, $chunk_n) = @_;
    $chunk_n ||= 1;
    $self->logger->debug("Start scan chunk $chunk_n");
    #map 0-100 to 60-80 aka real_percent*0.2
    #    $self->updateDiscoveryStatus(50, 0);
    my $prev_val = - 1;
    while (<$read_file_handler>) {
        #        diag($_);
        /About ([\.\d]+)\% done/;
        #massscan /(\d+)\.\d+\%/;
        #        diag $1;
        if ($1 && $1 != $prev_val) {
            $prev_val = $1;
            $self->logger->debug("nmap progress: ".$1);

        }
        #        $self->updateDiscoveryStatus($1 * 0.2, 0) if $1;
    }
    #    $self->updateDiscoveryStatus(70, 0);
    $self->logger->debug("End scan chunk $chunk_n");
    return 1;
}

sub prepare_result{
    my ($self, $in, $out) = @_;
    if ($self->scan_engine eq 'masscan') {
        return $self->prepare_result_masscan($in, $out);
    }
    return $self->prepare_result_nmap($in, $out);
}
sub prepare_result_nmap{
    my ($self, $in, $out) = @_;
    my $cmd = '/bin/grep '.$self->workdir.'/'.$in.' -e "open" | awk "{print \$2}" | /usr/bin/sort | /usr/bin/uniq > '.$self->workdir.'/'.$out;
    #    Emsgd::diag($cmd);
    $self->logger->debug($cmd);
    system $cmd;
    return 1;

}
sub prepare_result_masscan {
    my ($self, $in, $out) = @_;
    my $cmd = '/usr/bin/awk "{print \$4}" '.$self->workdir.'/'.$in.' | /usr/bin/sort | /bin/grep  -v \'^$\' | /usr/bin/uniq > '.$self->workdir.'/'.$out;
    #    Emsgd::diag($cmd);
    $self->logger->debug($cmd);
    system $cmd;
    return 1;
}
sub createRouter {
    my ($self, $ip) = @_;
    return $self->DB->addRouter($ip, $ip, 'unknown');
}

sub getRouterByIP {
    my ($self, $ip) = @_;
    return $self->DB->getRouterId($ip);
}

sub getInterfaceOwnerId {
    my ($self, $ip) = @_;
    return $self->DB->getInterfaceRouterId($ip);
}
sub updateDiscoveryStatus {
    my ($self, $percent, $finish) = @_;
    #    Emsgd::diag(( int($percent) ,$finish));
    $self->DB->updateDiscoveryStatus ( int($percent), $finish);
    $self->logger->debug("updateDiscoveryStatus to $percent%");
}
sub getNetblockOwnerId {
    my ($self, $ip) = @_;
    my $netblock_interface = $self->getNetblockInterfaceIP($ip);
    return  $self->getInterfaceOwnerId($netblock_interface);
}

sub getRouterVendor {
    my ($self, $id) = @_;
    return $self->DB->getRouterVendorById($id);
}

sub writeLink {
    my ($self, $idA, $idB) = @_;
    $self->logger->debug("Write_link $idA -> $idB");
    $self->DB->writeLink($idA, $idB, 'B');
}
sub copyVendor {
    my ($self, $from_id, $to_id) = @_;
    my $vendor_parent = $self->DB->getRouterVendorById($from_id);
    if (defined $vendor_parent)
    {
        $vendor_parent =~ s/^\s+|\s+$//g;
        $self->DB->setHostVendor($to_id, $vendor_parent);
    }
}
sub addHostToPoll {
    my ($self, $ip) = @_;
    my $fh = IO::File->new($self->workdir.'/'.$self->pollfile, '+>>');
    if (defined $fh) {
        print $fh  $ip."\n";
        undef $fh;
        $self->logger->debug("'host $ip added to POLL'");
    } else {
        $self->logger->logdie ( "Could not create poll file ".$self->workdir.'/'.$self->pollfile);
    }
};
sub get_chunks_to_scan {
    my $self = shift;
    my ($nets, $chunks) = @_;
    return Array::Split::split_into($chunks, @$nets);

}
sub process_result {
=pod
 Scan performed by @interfaces subnets
 #subnet_iface =
 @-is prefix for DB table
 # is alias for id of value in DB

 $IP - host IP found in this scan-round
 #subnet_iface = ip_arrr in @interfaces for current scanned subnet

 loop by $IP

     get #router by $IP from @routers
     get #interface_owner by $IP from @interfaces

     if #router NOT  EXISTS

            -- ETAP 1
            #new_router = CREATE new router in @routers

            if #interface_owner NOT EXISTS  --Etap 1

                -- ETAP 1.1
                connect #subnet_iface to #new_router
                   replace into @networs #subnet_iface => #new_router, type='B'
                start poll_host for $IP

            else (#intinterface_owner EXSITS )

                -- ETAP 1.2.1
                set  #new_router::vendor  =   #interface_owner::vendor
                --connect subnet to #interface_owner
                    replace into @networs #subnet_iface => #interface_owner, type='B'

                if $untrust_flag
                    start poll_host for $IP
                else
                    --Etap 1.2.2
                    DELETE #new_router from @routers ?!


     else (#router  EXISTS)
            --ETAP 2
            if #interface_owner EXISTS
                -- Etap 2.1
                if #router IS NOT #interface_owner

                    --ETAP 2.1.1
                    set  #router::vendor  =   #interface_owner::vendor ?!
                    --connect #subnet_iface to #interface_owner
                        replace into @networs  #subnet_iface => #interface_owner, type='B'
                    start poll_host for $IP

                else
                    --ETAP 2.1.2
                    --connect #subnet_iface to #router as type B
                        replace into @networs  #subnet_iface => #router, type='B'
                    start poll_host for $IP IF  untrust_flag=1 -- now untrusted_flug =  0

            else (#interface_owner NOT EXISTS )
                --ETAP 2.2
               --connect #subnet_iface to #router  as type B
                    replace into @networs  #subnet_iface => #router, type='B'
               start poll_host for $IP

=cut
    my ($self, $hosts) = @_;
    # Loop by IP
    for(@$hosts) {
        my $IP = $_;
        #        next;
        next unless NGNMS::OLD::Util::ip2num $IP;
        $self->logger->debug("*** Prepare host cleanup ".$IP);
        my $router_id = $self->getRouterByIP($IP);
        my $interface_owner = $self->getInterfaceOwnerId($IP);
        my $subnet_owner_id = $self->getNetblockOwnerId($IP);
        if (!defined $router_id) {
            #router NOT  EXISTS
            # --------------  ETAP 1 -------------------------
            $self->logger->debug("Etap 1:: No router found");
            if (!defined $interface_owner) {
                #interface_owner NOT EXISTS
                # --------------  ETAP 1.1 -------------------------
                $self->logger->debug("Etap 1.1:: No interface found: create new router,connect it to subnet interface and POLL");
                my $new_router_id = $self->createRouter($IP);
                $self->writeLink($subnet_owner_id, $new_router_id);
                $self->addHostToPoll( $IP);
            } else {
                # --------------  ETAP 1.2 -------------------------
                $self->logger->debug("Etap 1.2:: interface found");
                if ($subnet_owner_id ne $interface_owner) {
                    $self->logger->debug("Etpa 1.2.1 connect interface owner to subnet interface, NO POLL");
                    #                $self->copyVendor($interface_owner, $new_router_id);
                    $self->writeLink($subnet_owner_id, $interface_owner);
                } else {
                    $self->logger->debug("Etpa 1.2.2 interface and subnet owner is same , NO POLL, NO LINK");
                }
                #NO POLL HERE,this is just interface
            }
        } else {
            #router  EXISTS
            # --------------  ETAP 2 -------------------------
            $self->logger->debug("Etap 2:: router alresy exists");
            if (defined $interface_owner) {
                #interface_owner EXISTS
                # --------------  ETAP 2.1 -------------------------
                $self->logger->debug("Etap 2.1:: interface found");
                if ($router_id ne $interface_owner) {
                    #router is NOT #interface_owner
                    # --------------  ETAP 2.1.1 -------------------------
                    $self->logger->debug("Etap 2.1.1:: interface is on other router,connect interface owner to subnet and POLL");
                    $self->copyVendor($interface_owner, $router_id);
                    $self->writeLink($subnet_owner_id, $interface_owner);
                    $self->addHostToPoll( $IP);
                } else {
                    #router IS  #interface_owner
                    # --------------  ETAP 2.1.2 -------------------------
                    $self->logger->debug("Etap 2.1.2:: router is interface owner,connect router to subnet and POLL");
                    $self->writeLink($subnet_owner_id, $router_id);
                    $self->addHostToPoll( $IP);
                }
            } else {
                #interface_owner NOT EXISTS
                # --------------  ETAP 2.2 -------------------------
                $self->logger->debug("Etap 2.1.2:: new interface for router, connect router to subnet and POLL");
                $self->writeLink($subnet_owner_id, $router_id);
                $self->addHostToPoll( $IP);
            }
        }
    }
    return 1;
}


1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
