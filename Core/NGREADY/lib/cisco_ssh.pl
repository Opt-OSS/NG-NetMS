#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

die "THis is test file";

use Emsgd;
use NGNMS::Net::Connect;
use Try::Tiny;
use NGNMS_Cisco;
use Array::Utils qw(:all);
use File::Slurp;


#
#my $r =  NGNMS_Cisco::cisco_connect('10.1.1.1',
#    'lab',
#    'PocLab',
#    'cisco',
#    'SSH' );
#print "\n\n== $r ==\n\n";

my $Fixtures_dir = '/home/ngnms/NGREADY/t/fixtures';

my $s;
my $login = {
    personality => 'ios',
    transport   => 'SSHv1',
    host        => '10.1.1.1',
    debug       => 'warning',
};
sub __connect {
    $s = NGNMS::Net::Connect->new($login);
    $s->connect();
    $s->begin_privileged();

    my $data;
    $data = $s->macro('bgp_database_summary');
    $data .= $s->macro('bgp_database_neighbors');
    Emsgd::diag $data;

}
sub __parce {
    my $data = '
 BGP router identifier 10.1.1.1, local AS number 100
        BGP table version is 95, main routing table version 95
        8 network entries using 776 bytes of memory
        10 path entries using 360 bytes of memory
        7 BGP path attribute entries using 420 bytes of memory
        2 BGP AS-PATH entries using 48 bytes of memory
        0 BGP route-map cache entries using 0 bytes of memory
        0 BGP filter-list cache entries using 0 bytes of memory
        BGP using 1604 total bytes of memory
        BGP activity 29/21 prefixes, 45/35 paths, scan interval 60 secs

        Neighbor        V    AS MsgRcvd MsgSent   TblVer  InQ OutQ Up/Down  State/PfxRcd
        20.0.1.2        4   500  235045  235106       95    0    0 23w2d           2
        192.168.3.200   4 64512  522321  470109       95    0    0 6d18h           4
        BGP neighbor is 20.0.1.2,  remote AS 500, external link
        BGP version 4, remote router ID 10.2.2.2
        BGP neighbor is 192.168.3.200,  remote AS 64512, external link
        BGP version 4, remote router ID 10.3.3.3
        ';

    #    $data = $s->cmd('show ip bgp summary');
    #    $data .= $s->cmd('show ip bgp neighbors | inc remote');
    #    while($data =~  m/BGP neighbor is (\d+\.\d+\.\d+\.\d+).*?remote router ID (\d+\.\d+\.\d+\.\d+)/sg){
    #        Emsgd::diag $1.'=>'.$2;
    #        }


    my @n = $data =~ m/BGP\s+router\s+identifier\s+(\d+\.\d+\.\d+\.\d+)\,.*?\n/sg;

    my @r = ([ 'a' ], [ 'b' ], [ 'c' ]);
    my @a = map {$_->[0]} @r;

    Emsgd::diag(\@a);

    # proof it works
    #    Emsgd::diag(\@mylist)

}

sub __named_match_cisco {
    my( $bgp_file,$local_ip) = @_;
    my %res;

    my $text = read_file( $bgp_file);

    $text =~ /BGP\s+router\s+identifier\s+(\d+\.\d+\.\d+\.\d+).+local AS number (\d+)\n/s;
    my $locacl_id = $1;
    $res{$locacl_id}{'AS'} = $2;

    for  my $n ($text =~ m/(BGP neighbor.*?remote router ID \d+\.\d+\.\d+\.\d+)/sg) {
        my %h;
        @h{'neighbor', 'AS', 'type', 'bgp_identifier'} =
            $n =~ m/neighbor is (\d+\.\d+\.\d+\.\d+),.+remote AS (\d+).+\s(.*?) link.+remote router ID (\d+\.\d+\.\d+\.\d+)/sg;

        $res{$locacl_id}{'neighbors'}{$h{'bgp_identifier'}}= \%h;
    }

    return %res;
}
sub __named_match_juniper{
    my( $bgp_file,$local_ip) = @_;
    my %res;

    my $text = read_file( $bgp_file);
    for  my $n ($text =~ m/(Peer:\s+\d+\.\d+\.\d+\.\d+\+\d+.*?Peer ID:.*?\n)/sg) {
        my %h;
        my ($neighbor,$AS,$local_AS,$type,$bgp_identifier,$locacl_id)=
            $n =~ m/Peer:\s+(\d+\.\d+\.\d+\.\d+)\+\d+\s+AS\s+(\d+).*?AS\s+(\d+).*?Type:\s+(.*?)\s+.*?Peer ID:\s+(\d+\.\d+\.\d+\.\d+).*?Local ID:\s+(\d+\.\d+\.\d+\.\d+).*?\n/sg;
        #$1 - peer IP,$2 remote AS, $
        $res{$locacl_id}{'AS'} = $local_AS;
        $res{$locacl_id}{'neighbors'}{$bgp_identifier} = {'neighbor'=>$neighbor,'AS'=>$AS,'type'=>lc $type,'bgp_identifier'=>$bgp_identifier};
#        Emsgd::diag(\%h);
    }
    return %res;
}
my %r;
%r = (%r, __named_match_cisco ($Fixtures_dir.'/bgp_parser/192.168.3.202_bgp.txt','192.168.3.202'));
Emsgd::diag (\%r);
%r = (%r, __named_match_juniper ($Fixtures_dir.'/bgp_parser/192.168.3.200_bgp.txt','192.168.3.200'));
Emsgd::diag (\%r);

@_ = ('10.1.1.1', 'lab', 'PocLab', 'cisco', 'SSH');
#__connect;
#__parce;
#    NGNMS_Cisco::cisco_get_topologies('10.1.1.1', 'lab', 'PocLab', 'cisco');
#    print $s->cmd('help');
#    __connect;
#    my @data = $s->get('show privilege');
#    Emsgd::diag(\@data);


