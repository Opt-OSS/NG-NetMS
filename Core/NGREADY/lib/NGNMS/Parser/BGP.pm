package NGNMS::Parser::BGP;

use strict;
use warnings FATAL => 'all';
use File::Slurp qw (read_file);

use Moo::Role;

with "NGNMS::Log4Role";


sub parse_bgp_juniper {
    my $self = shift;
    my ( $bgp_file, $local_ip) = @_;
    my %res;
    my $text = File::Slurp::read_file( $bgp_file);
    for  my $n ($text =~ m/(Peer:\s+\d+\.\d+\.\d+\.\d+\+\d+.*?Peer ID:.*?\n)/sg) {
        my %h;
        my ($neighbor, $AS, $local_AS, $type, $bgp_identifier, $locacl_id) =
            $n =~ m/Peer:\s+(\d+\.\d+\.\d+\.\d+)\+\d+\s+AS\s+(\d+).*?AS\s+(\d+).*?Type:\s+(.*?)\s+.*?Peer ID:\s+(\d+\.\d+\.\d+\.\d+).*?Local ID:\s+(\d+\.\d+\.\d+\.\d+).*?\n/sg;
        #$1 - peer IP,$2 remote AS, $
        $res{$locacl_id}{'AS'} = $local_AS;
        $res{$locacl_id}{'neighbors'}{$bgp_identifier} = { 'neighbor' => $neighbor, 'AS' => $AS, 'type' => lc $type, 'bgp_identifier' => $bgp_identifier };
        #        Emsgd::diag(\%h);
    }
    return \%res;
}
sub parse_bgp_cisco($) {
    my $self = shift;
    my $bgp_file = shift;
    my %res;

    my $text = File::Slurp::read_file( $bgp_file);
    return undef unless $text;
    $text =~ /BGP\s+router\s+identifier\s+(\d+\.\d+\.\d+\.\d+).+local AS number (\d+)\n/s;
    my $locacl_id = $1;
    $res{$locacl_id}{'AS'} = $2;

    for  my $n ($text =~ m/(BGP neighbor.*?remote router ID \d+\.\d+\.\d+\.\d+)/sg) {
        my %h;
        @h{'neighbor', 'AS', 'type', 'bgp_identifier'} =
            $n =~ m/neighbor is (\d+\.\d+\.\d+\.\d+),.+remote AS (\d+).+\s(.*?) link.+remote router ID (\d+\.\d+\.\d+\.\d+)/sg;

        $res{$locacl_id}{'neighbors'}{$h{'bgp_identifier'}} = \%h;
    }

    return \%res;
}

1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
