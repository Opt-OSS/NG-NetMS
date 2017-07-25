#!/usr/bin/perl
use strict;
use warnings;
use AutoLoader qw/AUTOLOAD/;
use Emsgd;
use Test::More;
use Test::Spec ;
use NGNMS::OLD::Util;
use NGNMS::Parser::BGP;
use NGNMS::Host::SeedHost;


my $Fixtures_dir = 't/fixtures';


########### Mock DB - no real writes #############################
package BGP {
    use Moo;
    with "NGNMS::Parser::BGP";
}
1;




describe 'Cisco BGP ::' => sub {
        it 'should parse BGP file' => sub {
                my $bgp_file = $Fixtures_dir.'/bgp_parser/cisco_bgp.conf';
                my $bgp_parsed = {
                    '10.1.1.1' => {
                        'neighbors' => {
                            '10.2.2.2' => {
                                'type'           => 'external',
                                'AS'             => '500',
                                'bgp_identifier' => '10.2.2.2',
                                'neighbor'       => '20.0.1.2'
                            },
                            '10.3.3.3' => {
                                'type'           => 'external',
                                'bgp_identifier' => '10.3.3.3',
                                'AS'             => '64512',
                                'neighbor'       => '192.168.3.200'
                            },

                        },
                        'AS'        => '100'
                    }
                };
                $ENV{'NGNMS_HOME'} = '../';
                my $obj = BGP->new();
                my %res = $obj->parse_bgp_cisco( $bgp_file );
                is_deeply \%res, $bgp_parsed;
            }
    };
describe 'juniper BGP ::' => sub {

        it 'should parse BGP file' => sub {
                my $bgp_parsed =  {
                    '10.3.3.3' => {
                        'AS' => '64512',
                        'neighbors' => {
                            '10.2.2.2' => {
                                'AS' => '100',
                                'bgp_identifier' => '10.2.2.2',
                                'type' => 'external',
                                'neighbor' => '20.0.1.2'
                            },
                            '10.1.1.1' => {
                                'type' => 'external',
                                'neighbor' => '192.168.3.202',
                                'AS' => '100',
                                'bgp_identifier' => '10.1.1.1'
                            }
                        }
                    }
                };
                my $bgp_file = $Fixtures_dir.'/bgp_parser/juniper_bgp.conf';
                my $obj = BGP->new();
                my %res = $obj->parse_bgp_juniper ( $bgp_file );
                is_deeply \%res, $bgp_parsed;

            }
    };
describe 'It should check for errors in file' => sub{
    it 'regresstesst in fixtures/cisco-bgp-error'
};
runtests unless caller;