#!/usr/bin/perl

use warnings FATAL => 'all';
use strict;

use Test::More;
use Test::MockModule;#for syntax only
use Test::Subroutines;
use Test::Spec ;

use NGNMS::App;
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
describe "Can searches PollHost plugins::" => sub {
        my NGNMS::App $app;
        before each => sub {
                $app = NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( mode => 'register-plugins' );
            };

        it "find plugin"=>sub{
                $app->run();
                ok 1;
            };
        it "register  plugin";
        it "Disable plugin if removed";
        it "Enables plugin by default";
    };


runtests unless caller;;

