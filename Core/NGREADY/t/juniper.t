#!/usr/bin/perl
use strict;
use warnings;
use Test::Spec ;
use NGNMS::Host::SeedHost;
my $FixturesDir = 't/fixtures';
my $conf = { ip_addr => '10.1.1.1', 'host_type' => 'Juniper', 'config_dir' => $FixturesDir.'/lab_full' };

describe 'Juniper::BGP' => sub {
        it 'shouls call right method' => sub {
                my $shost = NGNMS::Host::SeedHost->new( $conf);
                $shost->expects('parse_bgp_juniper')->returns('yes');
                ok $shost->parse_bgp('');
            }
    };
describe 'Juniper::OSPF' => sub {
        it 'shouls call right method' => sub {
                my $shost = NGNMS::Host::SeedHost->new( $conf);
                $shost->expects('parse_ospf_juniper')->returns('yes');
                ok $shost->parse_ospf('');
            }
    };
describe 'Juniper::ISIS' => sub {
        it 'shouls call right method' => sub {
                my $shost = NGNMS::Host::SeedHost->new( $conf);
                $shost->expects('parse_isis_juniper')->returns('yes');
                ok $shost->parse_isis('');
            }
    };
describe 'Juniper::Connect' => sub {
        it 'shouls call right method' => sub {
                my $shost = NGNMS::Host::SeedHost->new( $conf);
                $shost->expects('create_session_juniper')->returns('yes');
                ok $shost->create_session();
            }
    };
runtests unless caller;

