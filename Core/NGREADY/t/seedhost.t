#!/usr/bin/perl
use strict;
use warnings;
use Test::Spec;
use Test::More;
use Test::Exception;
use NGNMS::Host::SeedHost;

describe 'host_type:: ' => sub {
        it 'shold be object' => sub {
                can_ok( 'NGNMS::Host::SeedHost', qw/new/ );

            };
        it 'host type is required' => sub {
                dies_ok {NGNMS::Host::SeedHost->new( 'ip_addr' => '' )};
            };
        it 'shold fail for unknown type' => sub {
                dies_ok {NGNMS::Host::SeedHost->new( 'ip_addr' => '', 'host_type' => 'Undefined' )};


            };
        foreach my $q (qw /Cisco  Juniper  Linux HP Extreme/) {
            it 'shold allow '.$q => sub {
                    lives_ok {NGNMS::Host::SeedHost->new( 'ip_addr' => '', 'host_type' => $q ) }
                }
        };
    };
describe 'config file ::' => sub {
        foreach my $q (qw/ospf isis bgp/) {
            my $o = NGNMS::Host::SeedHost->new( 'ip_addr' => '10.0.0.1', 'host_type' => 'Juniper' );
            it 'should return default file '.$q => sub {
                    is( $ENV{"NGNMS_DATA"}.'/topologies/10.0.0.1_'.$q.'.txt', $o->get_topology_filename( $q ) );
                };
        };
        foreach my $q (qw/ospf isis bgp/) {
            my $custom_dir = 'bla/bla/bla';
            my $o = NGNMS::Host::SeedHost->new( 'config_dir' => $custom_dir, 'ip_addr' => '10.0.0.2', 'host_type' => 'Juniper' );
            it 'should return cusom dir file '.$q => sub {
                    is( $custom_dir.'/10.0.0.2_'.$q.'.txt', $o->get_topology_filename( $q ) );
                };
        };
    };
runtests unless caller;

