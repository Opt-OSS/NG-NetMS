#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::MockModule;#for syntax only
use Test::Subroutines;
use Test::Spec ;
use Test::Deep;
use NGNMS::App;

use NGNMS::Plugins::Core::Linux::PollHost;
use Emsgd qw(diag);

=header  Execution flow of PollHOst module
 Check common functions
 Check Physical and logical interfaces functions

=cut


sub test_db_clean($) {
    my NGNMS::DB $db = shift;
    local $db->dbh->{PrintWarn};
    $db->dbh->do( 'truncate table routers cascade ' );
}

my $all_stubs = {
    processModel      => 0,
    processVendor     => 0,
    processHostname   => 0,
    processHardware   => 0,
    processSoftware   => 0,
    processLocation   => 0,
    processInterfaces => 0,
    processIpLayer    => 0,
    processConfig     => 0,
    setHostStatus     => 0,
    getSysObjectID    => sub {('MIB', undef)},
};

describe "Parser Calls all functions:: " => sub {
        my NGNMS::App $app;
        my NGNMS::DB $db;
        my ($rt_id, $stubs);
        before each => sub {
                NGNMS::Plugins::Core::Linux::PollHost->stubs(
                    'checkDeviceSupported' => 1
                );

                $stubs = { %$all_stubs }; #clone all

                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( mode => 'poll-host', dbname => 'ngnms_test', dbhost => 'ngnms-psql',
                    host                          => '10.0.1.1', host_type => 'Linux' );
                $app->stubs(
                    getHostCredentials => sub { { community => 'public' } },
                );
                $db = $app->get_db;
                $app->SessionClass( 'NGNMS::Net::Emulator::Session' );
                test_db_clean($db);
                $rt_id = $db->addRouter( 'hostname-10.0.1.1', '10.0.1.1', 1 );
            };
        it "processModel" => sub {
                delete $stubs->{'processModel'};
                $app->stubs( $stubs );
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'getModel' )->returns( 'Red Hat Enterprise Linux Server release 6.7 (Santiago)' )->once;
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select eq_type from routers where router_id=$rt_id" );
                is_deeply $r, [ 'Red Hat Enterprise Linux Server release 6.7 (Sant' ];
            };
        it "processVendor" => sub {
                delete $stubs->{'processVendor'};
                $app->stubs( $stubs );
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'getVendor' )->returns( 'Linux' )->once;
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select eq_vendor from routers where router_id=$rt_id" );
                is_deeply $r, [ 'Linux' ];
            };
        it "processHardware" => sub {
                delete $stubs->{'processHardware'};
                $app->stubs( $stubs );

                my $info = [
                    {
                        hw_item   => 'Memory',
                        hw_name   => 'RAM',
                        hw_ver    => 'N/A',
                        hw_amount => '14336K/2048K bytes',
                    },
                    {
                        hw_item   => 'Memory',
                        hw_name   => 'FLASH',
                        hw_ver    => '0111',
                        hw_amount => '8M',
                    }
                ];
                my $expect = [
                    [
                        $rt_id,
                        'Memory',
                        'RAM',
                        'N/A',
                        '14336K/2048K bytes'
                    ],
                    [
                        $rt_id,
                        'Memory',
                        'FLASH',
                        '0111',
                        '8M'
                    ]
                ];
                $db->expects( 'clearHostHardwareInfo' )->once;
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'getHardware' )->returns( $info )->once;
                my $res = $app->run();
                my $r = $db->dbh->selectall_arrayref( "select * from inv_hw where router_id=$rt_id" );
                #                diag $r;
                is_deeply $r, $expect;
            };
        it "processSoftware" => sub {
                delete $stubs->{'processSoftware'};
                $app->stubs( $stubs );

                my $info = [
                    {
                        sw_item => 'Operating system', #type of software (Operating system, Firmware, Software)
                        sw_name => 'IOS (tm) MC3810 Software (MC3810-I5K9S-M)',
                        sw_ver  => '12.2(29b)'
                    },
                    {
                        sw_item => 'Firmware', #type of software (Operating system, Firmware, Software)
                        sw_name => 'ROM: System Bootstrap',
                        sw_ver  => '11.3(1)MA1'
                    }
                ];
                my $expect = [
                    [
                        $rt_id,
                        'Operating system',
                        'IOS (tm) MC3810 Software (MC3810-I5K9S-M)',
                        '12.2(29b)'
                    ],
                    [
                        $rt_id,
                        'Firmware',
                        'ROM: System Bootstrap',
                        '11.3(1)MA1'
                    ]
                ];
                $db->expects( 'clearHostSoftwareInfo' )->once;
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'getSoftware' )->returns( $info )->once;
                my $res = $app->run();
                my $r = $db->dbh->selectall_arrayref( "select * from inv_sw where router_id=$rt_id" );
                #                diag $r;
                is_deeply $r, $expect;
            };
        it "processLocation" => sub {
                delete $stubs->{'processLocation'};
                $app->stubs( $stubs );
                my $expect = 'Intest suite';
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'getLocation' )->returns( $expect )->once;
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select location from routers where router_id=$rt_id" );
                #                diag $r;
                is_deeply $r, [ $expect ];
            };
        it "processIpLayer" => sub {
                delete $stubs->{'processIpLayer'};
                $app->stubs( $stubs );
                my $expect = 5;
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'getIpLayer' )->returns( $expect )->once;
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select layer from routers where router_id=$rt_id" );
                #                diag $r;
                is_deeply $r, [ $expect ];
            };
        it "processHostname: Renew if hostname differ from host given" => sub {
                delete $stubs->{'processHostname'};
                $app->stubs( $stubs );
                my $expect = 'NewHostName';
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'getHostName' )->returns( $expect )->once;
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select name from routers where router_id=$rt_id" );
                #                diag $r;
                is_deeply $r, [ $expect ];
            };
        it "processHostname: Dont call DB  if hostname undefined" => sub {
                delete $stubs->{'processHostname'};
                $app->stubs( $stubs );
                my $expect = 'hostname-10.0.1.1';
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'getHostName' )->returns( undef )->once;
                $db->expects( 'setHostName' )->never;
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select name from routers where router_id=$rt_id" );
                #                diag $r;
                is_deeply $r, [ $expect ];
            };
        it "processHostname: Dont call DB  if hostname the same as host given" => sub {
                delete $stubs->{'processHostname'};
                $app->stubs( $stubs );

                my $expect = 'hostname-10.0.1.1';
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'getHostName' )->returns( $expect )->once;
                $db->expects( 'setHostName' )->never;
                $app->host( $expect );
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select name from routers where router_id=$rt_id" );
                #                diag $r;
                is_deeply $r, [ $expect ];
            };
        it "processConfig";

    };

describe "Phisycal Interface::" => sub {
        my NGNMS::App $app;
        my NGNMS::DB $db;
        my ($rt_id, $stubs);

        my $expect;
        my $info = {
            'eth0' => {
                'state'       => 'enabled', #admin status 'enabled'|'disabled'
                'speed'       => '10000Mb/s', # 10000Mb/s| 1000  .....
                'condition'   => 'up', #physical link state 'up'|'down'|'unknown',
                'description' => '01:02:03::04:05:06', #description|mac(Linux)
                'mtu' => '1500', #Interface MTU in bytes
            },
            'eth1' => {
                'state'       => 'disabled', #admin status 'enabled'|'disabled'
                'speed'       => '10000Mb/s', # 10000Mb/s| 1000  .....
                'condition'   => 'down', #physical link state 'up'|'down'|'unknown',
                'description' => '11:02:03::04:05:06', #description|mac(Linux)
                'mtu' => '1514', #Interface MTU in bytes
            },
        };

        before each => sub {
                NGNMS::Plugins::Core::Linux::PollHost->stubs(
                    'checkDeviceSupported' => 1
                );
                $stubs = { %$all_stubs }; #clone all
                delete $stubs->{processInterfaces};
                $stubs->{getHostCredentials} = sub { { community => 'public' } },

                    NGNMS::App->_clear_instance;

                $app = NGNMS::App->instance( mode => 'poll-host', dbname => 'ngnms_test', dbhost => 'ngnms-psql',
                    host                          => '10.0.1.1', host_type => 'Linux' );
                $app->stubs($stubs);
                $db = $app->get_db;
                $app->SessionClass( 'NGNMS::Net::Emulator::Session' );
                test_db_clean($db);
                $rt_id = $db->addRouter( '10.0.1.1', '10.0.1.1', 1 );
                $expect = [
                    [
                        $rt_id,
                        ignore(), #ignore inteface id
                        'eth0',
                        'enabled',
                        'up',
                        '01:02:03::04:05:06',
                        '10000Mb/s',
                        1500

                    ],
                    [
                        $rt_id,
                        ignore(), #ignore inteface id
                        'eth1',
                        'disabled',
                        'down',
                        '11:02:03::04:05:06',
                        '10000Mb/s',
                        1514

                    ]
                ];

            };
        it "creates interfaces" => sub {

                $db->expects( 'markPhInterfacesToBePolled' )->once;
                $db->expects( 'deletePhInterfacesPolledButNotFound' )->once;
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'getInterfaces' )->returns( ($info, undef) )->once;
                my $res = $app->run();
                my $r = $db->dbh->selectall_arrayref( "select * from ph_int where router_id=$rt_id order by name" );

#                                                                diag $r;
                cmp_deeply $r, $expect;
            };
        it "deletes unused interfaces" => sub {
                $db->setPhInterface( $rt_id, {
                        name      => 'UnusedEth',
                        state     => 'don',
                        condition => 'up',
                        speed     => '100',
                        descr     => 'should be deleted',
                    } );
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'getInterfaces' )->returns( ($info, undef) )->once;
                my $res = $app->run();
                my $r = $db->dbh->selectall_arrayref( "select * from ph_int where router_id=$rt_id order by name" );
                #                diag $r;
                cmp_deeply $r, $expect;

            };
    };

describe "Logical Interface::" => sub {
        my NGNMS::App $app;
        my NGNMS::DB $db;
        my $rt_id;
        my $expect;
        my $phys_info = {
            'eth0' => {
                'state'       => 'enabled', #admin status 'enabled'|'disabled'
                'speed'       => '10000Mb/s', # 10000Mb/s| 1000  .....
                'condition'   => 'up', #physical link state 'up'|'down'|'unknown',
                'description' => '01:02:03::04:05:06', #description|mac(Linux)
                'mtu' => '1514', #Interface MTU in bytes
            },
            'eth1' => {
                'state'       => 'disabled', #admin status 'enabled'|'disabled'
                'speed'       => '10000Mb/s', # 10000Mb/s| 1000  .....
                'condition'   => 'down', #physical link state 'up'|'down'|'unknown',
                'description' => '11:02:03::04:05:06', #description|mac(Linux)
                'mtu' => '1514', #Interface MTU in bytes
            },
        };
        my $logic_info = {
            'eth0:1' => {
                'physical_interface_name' => 'eth0', #name of the physical interface this interface is attahed to
                'ip'                      => '192.168.0.1', #ip daress
                'mask'                    => '255.255.255.0', #network mask in  255.255.255.255 form
                'description'             => 'enabled',         #description|Admin state for linux

            },
            'eth0:2' => {
                'physical_interface_name' => 'eth0', #name of the physical interface this interface is attahed to
                'ip'                      => '192.168.2.1', #ip daress
                'mask'                    => '255.255.255.0', #network mask in  255.255.255.255 form
                'description'             => 'enabled',         #description|Admin state for linux
            },
            'eth1'   => {
                'physical_interface_name' => 'eth1', #name of the physical interface this interface is attahed to
                'ip'                      => '192.168.3.1', #ip daress
                'mask'                    => '255.255.255.0', #network mask in  255.255.255.255 form
                'description'             => 'enabled',         #description|Admin state for linux
            }
        };
        before each => sub {
                NGNMS::Plugins::Core::Linux::PollHost->stubs(
                    'checkDeviceSupported' => 1
                );

                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( mode => 'poll-host', dbname => 'ngnms_test', dbhost => 'ngnms-psql',
                    host                          => '10.0.1.1', host_type => 'Linux' );
                $app->stubs(
                    getHostCredentials => sub { { community => 'public' } },
                    processModel       => 0,
                    processVendor      => 0,
                    processHostname    => 0,
                    #                    processInterfaces => 0,
                    processLocation    => 0,
                    processHardware    => 0,
                    processSoftware    => 0,
                    processNetworks    => 0,
                    processConfig      => 0,
                    processIpLayer     => 0,
                );
                $db = $app->get_db;
                $app->SessionClass( 'NGNMS::Net::Emulator::Session' );
                test_db_clean($db);
                $rt_id = $db->addRouter( '10.0.1.1', '10.0.1.1', 1 );
                $expect = [
                    [
                        $rt_id,
                        'eth0:1',
                        '192.168.0.1',
                        '255.255.255.0',
                        'enabled'
                    ],
                    [
                        $rt_id,
                        'eth0:2',
                        '192.168.2.1',
                        '255.255.255.0',
                        'enabled'
                    ],
                    [
                        $rt_id,
                        'eth1',
                        '192.168.3.1',
                        '255.255.255.0',
                        'enabled'
                    ]
                ];

            };
        it "creates interfaces" => sub {

                $db->expects( 'markInterfacesToBePolled' )->once;
                $db->expects( 'deleteInterfacesPolledButNotFound' )->once;
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'getInterfaces' )->returns( ($phys_info,
                    $logic_info) )->once;
                my $res = $app->run();
                my $r = $db->dbh->selectall_arrayref( "select router_id,name,ip_addr,mask, descr from interfaces where router_id=$rt_id order by name" );
                #                 diag $r;
                is_deeply $r, $expect;
            };
        it "deletes unused interfaces" => sub {
                my $phi_int_id = $db->setPhInterface( $rt_id, {
                        name      => 'UnusedEth',
                        state     => 'don',
                        condition => 'up',
                        speed     => '100',
                        descr     => 'should be deleted',
                    } );
                $db->setInterface( $rt_id, {
                        name      => 'UnusedEth:0',
                        ph_int_id => $phi_int_id,
                        ip        => '1.1.1.1',
                        mask      => '255.0.0.0',
                        decr      => 'ddd',
                    } );
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'getInterfaces' )->returns( ($phys_info,
                    $logic_info) )->once;
                my $res = $app->run();
                my $r = $db->dbh->selectall_arrayref( "select router_id,name,ip_addr,mask, descr from interfaces where router_id=$rt_id order by name" );
                #                                diag $r;
                is_deeply $r, $expect;

            };
    };

runtests unless caller;;

