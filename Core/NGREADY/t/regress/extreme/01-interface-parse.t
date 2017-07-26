#!/usr/bin/perl

=for
    MDN-KPN POC X670V.5 # show ver
    Switch      : 800546-00-08 1547N-42070 Rev 8.0 BootROM: 1.0.2.1    IMG: 15.6.2.12
    PSU-1       : Internal PSU-1 800460-00-07 1545W-80029
    PSU-2       : Internal PSU-2 800460-00-07 1545W-80030

    Image   : ExtremeXOS version 15.6.2.12 v1562b12 by release-manager
              on Mon Jan 26 16:01:43 EST 2015
    BootROM : 1.0.2.1
    Diagnostics : 2.1

ERROR:
    could not parse /24 EUf---MPuRX---------/ at /home/ngnms/NGREADY/lib/NGNMS_Extreme.pm line 414.
    Use of uninitialized value $arr_subarr[1] in pattern match (m//) at /home/ngnms/NGREADY/lib/NGNMS_Extreme.pm line 416, <$info> line 4102.
    Use of uninitialized value $arr_subarr[1] in pattern match (m//) at /home/ngnms/NGREADY/lib/NGNMS_Extreme.pm line 424, <$info> line 4102.
    DBD::Pg::st execute failed: ERROR:  invalid input syntax for type inet: "/24 EUf---MPuRX---------" at /home/ngnms/NGREADY/lib/NGNMS_DB.pm line 290, <$info> line 4102.
=cut
use strict;
use warnings;
use Test::Spec ;
#use NGNMS_Extreme;
use Emsgd qw (diag);
my $FixturesDir = 't/fixtures';

describe 'could not parse /24 EUf---MPuRX---------/ at /home/ngnms/NGREADY/lib/NGNMS_Extreme.pm line 414' => sub {
        it 'shold parce logical interfaces' => sub {
                NGNMS::OLD::DB->expects( 'DB_getInterfaces' )->returns(
                    [
                        'ACCESS',
                        'BACKEND_INT',
                        'MULTICAST',
                        'OAM_EXT',
                        'OAM_INT',
                        'OOB_EXT'
                    ]
                )->at_least_once;
                NGNMS::OLD::DB->expects( 'DB_getPhInterfaces' )->returns(
                    [
                        'Port 21',
                        'Port 35',
                        'Port 63',
                        'Port 12',
                        'Port 13',
                        'Port 1',
                        'Port 6',
                        'Port 8',
                        'Port 46',
                        'Port 50',
                        'Port 51',
                        'Port 52',
                        'Port 54',
                        'Port 55',
                        'Port 56',
                        'Port 64',
                        'Port 9',
                        'Port 23',
                        'Port 26',
                        'Port 14',
                        'Port 17',
                        'Port 27',
                        'Port 59',
                        'Port 28',
                        'Port 30',
                        'Port 36',
                        'Port 2',
                        'Port 3',
                        'Port 31',
                        'Port 32',
                        'Port 37',
                        'Port 38',
                        'Port 40',
                        'Port 18',
                        'Port 15',
                        'Port 16',
                        'Port 10',
                        'Port 4',
                        'Port 19',
                        'Port 20',
                        'Port 24',
                        'Port 41',
                        'Port 42',
                        'Port 44',
                        'Port 45',
                        'Port 60',
                        'Port 47',
                        'Port 25',
                        'Port 48',
                        'Port 49',
                        'Port 53',
                        'Port 57',
                        'Port 61',
                        'Port 62',
                        'ACCESS',
                        'BACKEND_EDGE_INT 192.168.21.1',
                        'Port 29',
                        'Port 5',
                        'Port 11',
                        'Port 33',
                        'Port 34',
                        'Port 39',
                        'BACKEND_INT',
                        'MULTICAST',
                        'OAM_EXT',
                        'OAM_INT',
                        'OOB_EXT',
                        'TRAFFIC_CORE 129.192.45.1',
                        'Port 7',
                        'Port 22',
                        'Port 43',
                        'Port 58'
                    ]
                )->at_least_once;
                NGNMS::OLD::DB->expects('DB_getPhInterfaceId')->returns(sub{
                        my $rt_id = shift;
                        my $phInterface = shift;
                        return 1068 if $rt_id ==1001 &&  $phInterface eq 'ACCESS';
                        return 1146 if $rt_id ==1001 &&  $phInterface eq 'BACKEND_EDGE_INT 192.168.21.1';
                        return undef;
                    })->at_least_once;
                NGNMS::OLD::DB->expects('DB_writePhInterface')->returns(sub {
                        return 1
                    })->any_number;
                NGNMS::OLD::DB->expects('DB_writeInterface')->returns(sub {
                        ################# Should pass good IP ############################
                        my $rt_id = shift;
                        my $ph_int_id = shift;
                        my $ifc = shift;
#                        diag($ifc);
                        ok   $ifc->{'ip address'} =~ m/\d+\.\d+\.\d+\.\d+/, "shold pass IP,got \"".$ifc->{'interface'}."\" ".$ifc->{'ip address'};
                    })->at_least_once;

                NGNMS::OLD::DB->expects('DB_updateRouterId')->returns(100)->any_number;
                NGNMS::OLD::DB->expects('DB_setHostLayer')->returns(100)->any_number;
                NGNMS::OLD::DB->expects('DB_dropPhInterfaces')->returns(100)->any_number;
                NGNMS::OLD::DB->expects('DB_dropInterfaces')->returns(100)->any_number;
                extreme_parse_interfaces(1001,$FixturesDir.'/regress/extreame/1001/20160620-220006_interfaces.txt');
            };
        xit 'shold delete unused logical interfaces' => sub {
                #
                # insert into interfaces (router_id,ph_int_id,ifc_id,name,ip_addr,mask,descr) values (1001,1070,100,'MULTICAST','192.168.0.1','255.255.0.0',null);
                #


                NGNMS::OLD::DB->expects( 'DB_getInterfaces' )->returns(
                    [
                        'TRAFFIC_EXT_CORE',
                        'TRAFFIC_EXT_EDGE',
                        'MULTICAST',
                        'ACCESS',
                        'BACKEND_EDGE_INT',
                        'BACKEND_INT',
                        'MULTICAST',
                        'OAM_EDGE_INT',
                        'OAM_EXT',
                        'OAM_INT',
                        'OOB_EXT',
                        'TRAFFIC_CORE',
                        'TRAFFIC_DMZ',
                        'TRAFFIC_EDGE'
                    ]
                )->at_least_once;
                NGNMS::OLD::DB->expects( 'DB_getPhInterfaces' )->returns(
                    [
                        'Port 33',
                        'Port 49',
                        'Port 4',
                        'Port 25',
                        'Port 26',
                        'Port 15',
                        'Port 20',
                        'Port 21',
                        'Port 57',
                        'Port 62',
                        'BACKEND_EDGE_INT',
                        'BACKEND_INT',
                        'MULTICAST',
                        'OAM_EXT',
                        'OAM_INT',
                        'Port 10',
                        'Port 11',
                        'Port 16',
                        'Port 17',
                        'Port 27',
                        'Port 2',
                        'Port 34',
                        'Port 38',
                        'Port 29',
                        'Port 30',
                        'Port 39',
                        'Port 3',
                        'Port 44',
                        'Port 45',
                        'Port 50',
                        'Port 18',
                        'Port 23',
                        'Port 46',
                        'Port 51',
                        'Port 53',
                        'Port 54',
                        'Port 55',
                        'Port 31',
                        'Port 35',
                        'Port 40',
                        'Port 32',
                        'Port 24',
                        'Port 41',
                        'Port 28',
                        'Port 42',
                        'Port 47',
                        'Port 59',
                        'Port 60',
                        'Port 61',
                        'Port 63',
                        'Port 5',
                        'Port 64',
                        'Port 52',
                        'ACCESS',
                        'Port 6',
                        'Port 8',
                        'Port 12',
                        'Port 13',
                        'Port 14',
                        'Port 56',
                        'Port 36',
                        'Port 48',
                        'TRAFFIC_CORE',
                        'Port 9',
                        'Port 19',
                        'Port 37',
                        'TRAFFIC_DMZ',
                        'TRAFFIC_EDGE',
                        'OAM_EDGE_INT',
                        'OOB_EXT',
                        'TRAFFIC_EXT_CORE',
                        'TRAFFIC_EXT_EDGE',
                        'Port 1',
                        'Port 7',
                        'Port 22',
                        'Port 43',
                        'Port 58'
                    ]
                )->at_least_once;
                NGNMS::OLD::DB->expects('DB_getPhInterfaceId')->returns(sub{
                        my $rt_id = shift;
                        my $phInterface = shift;
                        return 1068 if $rt_id ==1001 &&  $phInterface eq 'ACCESS';
                        return 1146 if $rt_id ==1001 &&  $phInterface eq 'BACKEND_EDGE_INT 192.168.21.1';
                        return undef;
                    })->at_least_once;
                NGNMS::OLD::DB->expects('DB_writePhInterface')->returns(sub {
                        return 1
                    })->any_number;
                NGNMS::OLD::DB->expects('DB_writeInterface')->returns(sub {
                        ################# Should pass good IP ############################
                        my $rt_id = shift;
                        my $ph_int_id = shift;
                        my $ifc = shift;
                        #                        diag($ifc);
                        ok   $ifc->{'ip address'} =~ m/\d+\.\d+\.\d+\.\d+/, "shold pass IP,got \"".$ifc->{'interface'}."\" ".$ifc->{'ip address'};
                    })->at_least_once;

                NGNMS::OLD::DB->expects('DB_updateRouterId')->returns(100)->any_number;
                NGNMS::OLD::DB->expects('DB_setHostLayer')->returns(100)->any_number;
                NGNMS::OLD::DB->expects('DB_dropPhInterfaces')->returns(100)->any_number;
                NGNMS::OLD::DB->expects('DB_dropInterfaces')->returns(100)->any_number;
                extreme_parse_interfaces(1001,$FixturesDir.'/regress/extreame/1001/20160620-220006_interfaces.txt');
            };
    };

runtests unless caller;


