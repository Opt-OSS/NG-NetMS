#!/usr/bin/perl

use warnings FATAL => 'all';
use strict;

use Test::More;
use Test::MockModule;#for syntax only
use Test::Subroutines;
use Test::Spec ;

use NGNMS::App;

use NGNMS::Plugins::Core::Linux::PollHost;
use Emsgd qw(diag);




=header  Common test for PollHOst Interface
 checks startup , run arguments and plugin selection
 fro poll-host process

=cut



sub test_db_clean($) {
    my NGNMS::DB $db = shift;
    local $db->dbh->{PrintWarn};
    $db->dbh->do( 'truncate table routers cascade ' );
}

describe "Startup and checks::" => sub {
        my NGNMS::App $app;
        before each => sub {
                $app = NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( mode => 'poll-host', dbname => 'ngnms_test', dbhost => 'ngnms-psql', host => '10.0.1.1' );
            };

        it "starts pollhost" => sub {
                NGNMS::App->expects( 'runPollHost' )->returns()->once();
                $app->run();
                ok 1
            };
    };

describe "Router exists::" => sub {
        my NGNMS::App $app;
        my NGNMS::DB $db;
        before each => sub {
                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( mode => 'poll-host', dbname => 'ngnms_test', dbhost => 'ngnms-psql',
                    host                          => '10.0.1.1' );
                $app->stubs(setHostStatus=>0);
                $db = $app->get_db;
                test_db_clean($db);
                $db->addRouter( '10.0.1.1', '10.0.1.1', 1 );
            };
        it "should return 0 if router not in DB" => sub {
                NGNMS::App->expects( 'start_poll_processing' )->never;
                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( mode => 'poll-host', dbname => 'ngnms_test', dbhost => 'ngnms-psql',
                    host                          => '10.0.1.2' );
                my $res = $app->run();
                not is $res, 0;
            };
        it "should start processing if router exists" => sub {
                NGNMS::App->expects( 'start_poll_processing' )->returns( 1 )->once;
                my $res = $app->run();
                ok 1;
            }

    };

describe "Plugin selection :: " => sub {
        my NGNMS::App $app;
        my NGNMS::DB $db;
        before each => sub {
                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( mode => 'poll-host', dbname => 'ngnms_test', dbhost => 'ngnms-psql',
                    host                          => '10.0.1.1' );
                $app->stubs(
                    getHostCredentials => sub { { community => 'public' } },
                    processPollHost     => 1,
                    getSysObjectID     => sub {('MIB', undef)},
                    setHostStatus=>0,
                );
                $db = $app->get_db;
                test_db_clean($db);
                $db->addRouter( '10.0.1.1', '10.0.1.1', 1 );
            };
        it "should get plugin if host_type in command line, NO SNMP" => sub {
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'checkDeviceSupported' )->returns( 1 )->once;
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'checkSNMPsysObjectID' )->never;
                $app->host_type( 'Linux' );
                $app->run();
                my $res = $app->getPluginModule();
                isa_ok $res, 'NGNMS::Plugins::Core::Linux::PollHost';
            };
        it "should do By SNMP to get plugin" => sub {
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'checkDeviceSupported' )->never;
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'checkSNMPsysObjectID' )->returns( 1 )->once;
                $app->run();
                my $res = $app->getPluginModule();
                isa_ok $res, 'NGNMS::Plugins::Core::Linux::PollHost';
            };
    };
describe "Check SMNP fallback selection::" => sub {
        my NGNMS::App $app;
        my NGNMS::DB $db;
        my $rt_id;
        before each => sub {
                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance(
                    mode   => 'poll-host', host => '10.0.1.1',
                    dbname => 'ngnms_test', dbhost => 'ngnms-psql',
                );
                $app->stubs(
                    getHostCredentials => sub { { community => 'public' } },
#                    prcessPollHost     => 1,
                    getSysObjectID     => sub {(undef, 'some serror')},
                    setHostStatus=>0,
                );
                $db = $app->get_db;
                test_db_clean($db);
                $rt_id = $db->addRouter( '10.0.1.1', '10.0.1.1', 1 );
            };
        it "should try checkDeviceSupported  with HostType form DB if SNMP fails"=>sub{
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'checkDeviceSupported' )->returns(1)->once;
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'checkSNMPsysObjectID' )->never;
                NGNMS::App->expects('processPollHost')->returns(1)->once;
                NGNMS::DB->expects('getHostVendor')->returns('Linux')->once;
                $app->run();
                my $res = $app->getPluginModule();
                isa_ok $res, 'NGNMS::Plugins::Core::Linux::PollHost';
            };
        it "should stop process if no SNMP and no host type in DB"=>sub{
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'checkDeviceSupported' )->never;
                NGNMS::Plugins::Core::Linux::PollHost->expects( 'checkSNMPsysObjectID' )->never;
                NGNMS::App->expects('processPollHost')->never;
                NGNMS::DB->expects('getHostVendor')->returns(undef)->once;
                my $res = $app->run();
                is $res,0 ;
            };

    };

describe "it shold connect to remote host::" => sub {
        my NGNMS::App $app;
        my NGNMS::DB $db;
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
                    processInterfaces  => 0,
                    processLocation    => 0,
                    processHardware    => 0,
                    processSoftware    => 0,
                    processNetworks    => 0,
                    processConfig      => 0,
                    getSysObjectID     => sub {('MIB', undef)},
                    setHostStatus=>0,
                );
                $db = $app->get_db;
                $app->SessionClass( "NGNMS::Net::Emulator::Session" );
                test_db_clean($db);
                $db->addRouter( '10.0.1.1', '10.0.1.1', 1 );
            };
        it "creates instance of plugin" => sub {
                my $res = $app->run();
                my $p = $app->getPluginModule();
                isa_ok $p, 'NGNMS::Plugins::Core::Linux::PollHost';
            };
        it "connects session to host" => sub {
                NGNMS::Net::Emulator::Session->expects( 'connect' )->returns('ok')->once;
                my $res = $app->run();
                ok 1;
            }

    };

describe "it shold connect to remote host via name or IP::" => sub {
            my NGNMS::App $app;
            my NGNMS::DB $db;
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
                            processInterfaces  => 0,
                            processLocation    => 0,
                            processHardware    => 0,
                            processSoftware    => 0,
                            processNetworks    => 0,
                            processConfig      => 0,
                            getSysObjectID     => sub {('MIB', undef)},
                            setHostStatus=>0,
                        );
                        $db = $app->get_db;
                        $app->SessionClass( "NGNMS::Net::Emulator::Session" );
                        test_db_clean($db);
                        $db->addRouter( 'C2', '10.0.1.1', 1 );
                };


            it "connect to host given cmd param(hotname or IP)" => sub {
                        NGNMS::Net::Emulator::Session->expects( 'connect' )->returns('ok')->once;
                        $app->host('C2');
                        my $res = $app->run();
                        is $app->host,'C2';
                };
            it "connect to host by IP in DB if fails by Name" => sub {
                        NGNMS::Net::Emulator::Session->expects( 'connect' )->returns('error')->exactly(2);
                        $app->host('C2');
                        my $res = $app->run();
                        is $app->host,'10.0.1.1';
                }
    };



runtests unless caller;;

