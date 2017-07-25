#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::MockModule;#for syntax only
use Test::Subroutines;
use Test::Spec ;

use NGNMS::App;

use NGNMS::Plugins::Core::Linux::PollHost;
use Emsgd qw(diag);

=header  Execution flow of PollHOst module
 injects routers int DB if --inject flag is set

=cut


sub test_db_clean($) {
    my NGNMS::DB $db = shift;
    local $db->dbh->{PrintWarn};
    $db->dbh->do( 'truncate table routers cascade ' );
}


describe "Inject router if flag --inject" => sub {
        my NGNMS::App $app;
        my NGNMS::DB $db;
        my $rt_id;
        before each => sub {
                NGNMS::Plugins::Core::Linux::PollHost->stubs(
                    'checkDeviceSupported' => 1
                );

                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( mode => 'poll', dbname => 'ngnms_test', dbhost => 'ngnms-psql',
                    host                          => '10.0.1.1', host_type => 'Linux' );
                $app->stubs(
                    getHostCredentials => sub { { community => 'public' } },
                );
                $db = $app->get_db;
                $app->SessionClass( 'NGNMS::Net::Emulator::Session' );
                test_db_clean($db);
                $rt_id = $db->addRouter( 'hostname-10.0.1.1', '10.0.1.1', 1 );
            };
        xit "it should inject router is flag given";
        xit "it should set venodr from --host-type";
        xit "it should stop if --play dir not set";
        xit "it should stop if --host dir not set";
        xit "it should stop if --host-type dir not set";
        xit "it should use exsited router if exists";
        xit "it should use --host only as IP aderess";
        xit "it should use 'NGNMS::Net::Emulator::Session'";
    };



runtests unless caller;;

