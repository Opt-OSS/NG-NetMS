#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::MockModule;#for syntax only
use Test::Subroutines;
use Test::Spec ;

use NGNMS::App;

use NGNMS::Net::Emulator::Session;
use Emsgd qw(diag);

describe "IT provides App services::" => sub {
        my NGNMS::App $app;
        before each => sub {
                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( dbname => 'ngnms_test', dbhost => 'ngnms-psql' );
            };
        it "is sinleton" => sub {
                is $app, NGNMS::App->instance;
            };
        it "retuns DB sigleton" => sub {
                is $app->get_db(), NGNMS::App->instance->get_db();
            };

    };
xdescribe "Host factory::" => sub {
        my NGNMS::App $app;
        before each => sub {
                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( );
            };
        it "Should require hottype" => sub {
                is $app->host_factory (), undef;
            };

        it "should require IP addr or hostname";

        it "Returns new instance according to host_type" => sub {
                my $c1 = $app->host_factory ( host_type => "Cisco",ip_addr=>'1.1.1.1'  );
                my $c2 = $app->host_factory ( host_type => "Cisco",ip_addr=>'1.1.1.1'  );
                my $j1 = $app->host_factory ( host_type => "Juniper",ip_addr=>'1.1.1.1'  );
                my $j2 = $app->host_factory ( host_type => "Juniper",ip_addr=>'1.1.1.1'  );
                isa_ok  $c1, "NGNMS::Host::RouterCisco";
                isa_ok  $j1, "NGNMS::Host::RouterJuniper";
                isnt $c1, $c2;
                isnt $j1, $j2;
            };
        it "creates instance of class attribute" => sub {
#                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( RouterCiscoClass => "NGNMS::Host::RouterJuniper", RouterJuniperClass => "NGNMS::Host::RouterCisco" );
                isa_ok  $app->host_factory ( host_type => "Juniper",ip_addr=>'1.1.1.1' ), "NGNMS::Host::RouterCisco";
                isa_ok  $app->host_factory ( host_type => "Cisco",ip_addr=>'1.1.1.1'  ), "NGNMS::Host::RouterJuniper";
            };
    };
describe "Session factory::" => sub {
        my NGNMS::App $app;
        before each => sub {
                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance(  );
            };
        it 'should return new instance of Sessiion' => sub {
                my $c1 = $app->session_factory();
                my $c2 = $app->session_factory();
                isa_ok  $c1, "NGNMS::Net::Session";
                isa_ok  $c2, "NGNMS::Net::Session";
                isnt $c1, $c2;
            };
        it "creates instance of class attribute" => sub {
#                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( SessionClass => "NGNMS::Net::Emulator::Session" );
                isa_ok  $app->session_factory (), "NGNMS::Net::Emulator::Session";
            };
    };
describe "Host factory and Session::" => sub {
        my NGNMS::App $app;
        before each => sub {
                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( SessionClass => "NGNMS::Net::Emulator::Session"  );
            };
        xit 'should inject session into host' =>sub{
                my NGNMS::Host::RouterHost $c1  = $app->host_factory ( host_type => "Cisco" ,ip_addr=>'1.1.1.1' );
                my NGNMS::Host::RouterHost $j1  = $app->host_factory ( host_type => "Juniper" ,ip_addr=>'1.1.1.1' );
                isa_ok  $c1->session, "NGNMS::Net::Emulator::Session";
                isa_ok  $j1->session, "NGNMS::Net::Emulator::Session";

            };
    };

runtests unless caller;

