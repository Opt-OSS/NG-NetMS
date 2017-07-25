#!/usr/bin/perl
use strict;
use warnings;

use Test::More ; #for syntax only
use Test::MockModule;#for syntax only
use Test::Subroutines;
use Test::Spec ;
use NGNMS::OLD::Util;
use File::Slurp;
use Emsgd qw(diag);
use NGNMS::App;


use NGNMS::Net::Session;

xdescribe 'Chain of commands::' => sub {
        my NGNMS::App $app;
        before each => sub {
                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( dbname => 'ngnms_test', dbhost => 'ngnms-psql' );
            };
        xit 'should run chained commands ' => sub {
                my @c = qw(A B);
                my $r = $app->host_factory( host_type => 'Cisco', ip_addr => '1.1.1.1' );
                $r->expects( 'execute_remote_command' )
                    ->returns( sub {
                        my $cmd = $_[1];
                        return "\n$cmd";
                    } )
                    ->exactly( 2 )->times;
                my $res = $r->execute_chained_commands( @c );
                is $res, "\nA\nB";
            };

    };
xdescribe 'GET OSPF::' => sub {
        my NGNMS::App $app;
        before each => sub {
                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( SessionClass => "NGNMS::Net::Emulator::Session" );
            };
        xit 'should run commands from get_ospf properties' => sub {
                my @c = qw(A B);
                my NGNMS::Host::RouterHost $r = $app->host_factory( host_type => 'Cisco', ip_addr => '1.1.1.1', ospf_macro => [ @c ] );
                $r->stubs( execute_remote_command => 1 );
                $r->expects( 'execute_chained_commands' )->with_deep( [ @c ] );
                $r->get_ospf();
            };
    };
describe 'Net::Session and RouterHost::connect' => sub {
        my NGNMS::App $app;

        my ($net, $session);
        before each => sub {
                $net = Test::MockModule->new( 'NGNMS::Net::Connect', no_auto => 1 );
                $net->mock( 'new', sub($){bless {},shift} );
#                $net->mock( 'connect' , sub {1} );
                $net->mock( 'begin_privileged' , sub {1} );
                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( );

            };
        it 'Session class should call connect of NGNMS::Net::Connect' => sub {
                $session = NGNMS::Net::Session->new;
                $net->expects('connect')->returns(1)->times(1);
                is $session->create_session, 'ok';
            };
        xit 'should NOT begin_privileged by default' => sub {
                $r = $app->host_factory( host_type => 'Cisco', ip_addr => '1.1.1.1', requires_privileged => 0 );
                $r->session( $session );
                $session->expects( 'connect' )->returns( 1 );
                $session->expects( 'begin_privileged' )->never;
                is $r->connect, 'ok';
            };
        xit 'should begin_privileged if required' => sub {
                $r = $app->host_factory( host_type => 'Cisco', ip_addr => '1.1.1.1', requires_privileged => 1 );
                $r->session( $session );
                $session->expects( 'connect' )->returns( 1 );
                $session->expects( 'begin_privileged' );
                is $r->connect, 'ok';
            };
        xit 'should check priveleged level' => sub {
                $r = $app->host_factory( host_type => 'Cisco', ip_addr => '1.1.1.1' );
                $r->session( $session );
                $session->expects( 'connect' )->returns( 1 );
                $session->expects( 'begin_privileged' )->returns( 1 );
                $session->expects( 'check_is_privileged' )->returns( 'ok' );
                is $r->connect, 'ok';
            };
    };

runtests unless caller;