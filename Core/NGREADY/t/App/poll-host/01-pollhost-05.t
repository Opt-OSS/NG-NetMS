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
 checks for effective config storage
 it shoul only update timestamp if config is not changed from last poll

=cut

#TODO re-check all processing

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
#    processConfig     => 0,
};
my $configA  = "config A \n multiline";
my $configB  = "config B \n multiline";
describe "Check Config:: " => sub {
        my NGNMS::App $app;
        my NGNMS::DB $db;
        my $session_params = { };
        my ($rt_id);
        before each => sub {
                NGNMS::Plugins::Core::Linux::PollHost->stubs(
                    'checkDeviceSupported' => 1
                );

                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( mode => 'poll-host', dbname => 'ngnms_test', dbhost => 'ngnms-psql',
                    host                          => '10.0.1.1', host_type => 'Linux' );
                $app->stubs( $all_stubs );
                $db = $app->get_db;
                $app->SessionClass( "NGNMS::Net::Emulator::Session" );
                NGNMS::Net::Emulator::Session->stubs(
                    connect => sub($){
                        my $self = shift;
                        $session_params = shift;
                        return 'ok';
                    }
                );

                NGNMS::Plugins::Core::Linux::PollHost->expects( 'getConfig' )->returns( $configA )->once;
                test_db_clean($db);
                $rt_id = $db->addRouter(  '10.0.1.1', '10.0.1.1', 1 );
            };
        it "should save new config" => sub {

                $app->run();
#                diag $session_params;
                my $r = $db->dbh->selectrow_array( "select data from router_configuration where router_id=$rt_id" );
#                                diag $r;
                is_deeply $r, $configA;
            };

        it "should not add  config if not changed" => sub {
                $db->addConfig($rt_id,$configA);
                $app->run();
                #                diag $session_params;
                my $r = $db->dbh->selectrow_array( "select count(*) from router_configuration where router_id=$rt_id" );
#                diag $r;
                is $r, 1;
            };
        it "should add  config if changed" => sub {
                $db->addConfig($rt_id,$configB);
                $app->run();
                #                diag $session_params;
                my $r = $db->dbh->selectrow_array( "select count(*) from router_configuration where router_id=$rt_id" );
#                diag $r;
                is $r, 2;
            };
        it "should update config date if not changed" => sub {
                $db->addConfig($rt_id,$configB);
                $db->addConfig($rt_id,$configA);
                my $time1 = $db->dbh->selectrow_array( "select  cast( extract(epoch from created ) as INT)  from router_configuration where router_id=$rt_id order by created DESC limit 1" );
                sleep(1);
                $app->run();
                #                diag $session_params;
                my $r = $db->dbh->selectrow_array( "select created from router_configuration where router_id=$rt_id" );
                my $time2 = $db->dbh->selectrow_array( "select cast( extract(epoch from created ) as INT)  from router_configuration where router_id=$rt_id order by created DESC limit 1" );
#                diag $r;
                is ( $time2 - $time1,1)
            };

    };

runtests unless caller;;

