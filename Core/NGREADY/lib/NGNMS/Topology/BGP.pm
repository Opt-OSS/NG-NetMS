package NGNMS::Topology::BGP;
use strict;
use warnings FATAL => 'all';
use Moo;
with "NGNMS::Log4Role";
use Emsgd qw(diag);
sub write_bgp_topology {
    my $self=shift;
    my ($bgp_config, $seedHost) = @_;
    $self->put_debug_key('host',$seedHost);
    $self->logger->debug ( "writing BGP by data from $seedHost" );
#    diag $bgp_config;
    #writing BGP topology
    while (my ($this_id, $conf) = each %$bgp_config) {
        #            add this host as parced
        $self->logger->debug("processing bgp neigbor $this_id from $seedHost");
        NGNMS::OLD::DB::DB_addBgpRouter( $this_id, 'e', $conf->{AS}, $seedHost, 1 ) unless defined NGNMS::OLD::DB::DB_getBgpRouterId( $this_id );
        NGNMS::OLD::DB::DB_updateBgpRouterStatus( $this_id, 1 );
        my $rid_a = NGNMS::OLD::DB::DB_getRouterId( $this_id ) || NGNMS::OLD::DB::DB_addRouter( $this_id, $this_id, 'UP' );
        NGNMS::OLD::DB::DB_updedteRouterIndetifier($rid_a, 1);
        my $neig = $conf->{neighbors};
        while ( my ($remote_id, $remote_conf) = each %$neig){
            #                Emsgd::diag($remote_conf->{AS});
            #add remote as unparsed
            NGNMS::OLD::DB::DB_addBgpRouter( $remote_id, 'e', $remote_conf->{AS}, $seedHost, 0 ) unless defined NGNMS::OLD::DB::DB_getBgpRouterId( $remote_id );
            my $rid_b = NGNMS::OLD::DB::DB_getRouterId( $remote_id ) || NGNMS::OLD::DB::DB_addRouter( $remote_id, $remote_id, 'UNKNOWN' );
            NGNMS::OLD::DB::DB_updedteRouterIndetifier($rid_b, 1);
            my $type = $remote_conf->{type} eq 'external' ? 'e' : 'i'; #external || internal
            my $type_full = $remote_conf->{type} eq 'external' ? 'EBGP' : 'IBGP'; #external || internal
            NGNMS::OLD::DB::DB_writeLink( $rid_a, $rid_b, $type );
            NGNMS::OLD::DB::DB_writeRouterPeers(
                {
                    router_id          => $rid_a,
                        router_peer_id => $rid_b,
                        peer_type      => $type_full,
                        peer_info      => $remote_conf->{AS},
                        description     => 'from configs of '.$seedHost,
                }
            );
        }
        ##            DB_updateBgpRouterStatus($seedHost, 1);
        #            my %neig = $bgp_config{$this_id}{neighbors};
        #            Emsgd::diag(\%neig);
        #            for my $remote_id (keys $bgp_config{$this_id}{neighbors}) {
        ##                my $remote_data = $neighbors->{$remote_id};
        #                Emsgd::diag($bgp_config{$this_id}{neighbors}{$remote_id});
        ##                DB_addBgpRouter($remote_data{neighbor}, 'e', $bgp_config{$this_id}{AS}, $this_id, 1) unless defined DB_getBgpRouterId($seedHost);
        #            }

    }
}
1;