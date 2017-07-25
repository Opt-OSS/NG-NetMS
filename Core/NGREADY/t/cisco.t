#!/usr/bin/perl
use strict;
use warnings;
use Test::Spec ;
use NGNMS::Host::SeedHost;

my $FixturesDir = 't/fixtures';
my $conf = { ip_addr => '10.1.1.1', 'host_type' => 'Cisco', 'config_dir' => $FixturesDir.'/lab_full' };


describe 'Cisco::BGP' => sub {

        xit 'shold return undef if file not exists';
        it 'should support BGP' => sub {
                my $shost = NGNMS::Host::SeedHost->new( $conf );
                ok $shost->supports_bgp;
            };
        it 'should call right method' => sub {
                my $shost = NGNMS::Host::SeedHost->new( $conf );
                $shost->expects( 'parse_bgp_cisco' )->returns( 'yes' );
                ok $shost->parse_bgp( '' );
            }
    };
describe 'Cisco::OSPF' => sub {
        it 'should support OSFP' => sub {
                my $shost = NGNMS::Host::SeedHost->new( $conf );
                ok $shost->supports_ospf;
            };
        it 'should call right method' => sub {
                my $shost = NGNMS::Host::SeedHost->new( $conf );
                $shost->expects( 'parse_ospf_cisco' )->returns( 'yes' );
                not ok $shost->parse_ospf( '' );
            };
    };
describe 'Cisco::ISIS' => sub {
        it 'should support ISIS' => sub {
                my $shost = NGNMS::Host::SeedHost->new( $conf );
                ok $shost->supports_bgp;
            };
        it 'should call right method' => sub {
                my $shost = NGNMS::Host::SeedHost->new( $conf );
                $shost->expects( 'parse_isis_cisco' )->returns( 'yes' );
                ok $shost->parse_isis( '' );
            };
    };
describe 'Cisco::Connect' => sub {
        it 'should call right method' => sub {
                my $shost = NGNMS::Host::SeedHost->new( $conf );
                $shost->expects( 'create_session_cisco' )->returns( 'yes' );
                ok $shost->create_session();
            };
    };
runtests unless caller;

