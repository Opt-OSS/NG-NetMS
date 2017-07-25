#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::MockModule;#for syntax only
use Test::Subroutines;
use Test::Spec ;
use Crypt::TripleDES;

use NGNMS::App;
use MIME::Base64 qw (encode_base64);
use Emsgd qw(diag);

my (@eccrypted, $decoded_default, $router_access_encrypted, $router_access_decoded, $good_router, $not_router, $router_without_access, $criptokey);
$criptokey = '123412341234123412341234';

sub test_db_clean($) {
    my NGNMS::DB $db = shift;
    local $db->dbh->{PrintWarn};
    $db->dbh->do( 'truncate table routers cascade ' );
    $db->dbh->do( 'truncate table general_settings ' );
}
sub chiper($) {
    my $text = shift;
    my $des = Crypt::TripleDES->new;
    my $r = encode_base64( $des->encrypt3 ( $text, $criptokey ));
    chomp($r);
    return $r;
}
sub init_general_settings($) {
    my NGNMS::DB $db = shift;
    my DBI $dbh = $db->dbh;
    my $st = $dbh->prepare( "insert into general_settings (name,value) values(?,?)" );
    $st->execute( 'chiave', $criptokey );
    $st->execute( 'community', chiper 'public_default' );
    $st->execute( 'type access', chiper 'telnet' );
    $st->execute( 'username', chiper 'lab_default' );
    $st->execute( 'password', chiper 'lab_pass_default' );
    $st->execute( 'enpassword', chiper 'ena_pass_default' );


}


$router_access_encrypted = [
    [ 'Telnet', 'Cisco', 'Login', chiper 'router_username' ],
    [ 'Telnet', 'Cisco', 'Password', chiper 'router_password' ],
    [ 'Telnet', 'Cisco', 'Enpassword', chiper 'router_ena' ],
    [ 'Telnet', 'Cisco', 'Cmdoptions', chiper '-i ./ssh/id_rsa' ],
];
$router_access_decoded = {
    username            => 'router_username',
    password            => 'router_password',
    privileged_password => 'router_ena',
    transport           => 'Telnet',
    community           => 'public_default',
    connect_options     => ['-i','./ssh/id_rsa'],
};
$decoded_default = {
    username            => 'lab_default',
    password            => 'lab_pass_default',
    privileged_password => 'ena_pass_default',
    transport           => 'telnet',
    community           => 'public_default',
    connect_options     => [],
};
$good_router = '10.0.1.1';
$not_router = '1.1.1.1';
$router_without_access = '10.0.0.1';

describe "CRYPT CORE :: " => sub {
        my NGNMS::App $app;
        my NGNMS::DB $db;
        before each => sub {
                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( mode => 'poll', dbname => 'ngnms_test', dbhost => 'ngnms-psql',
                    host                          => '10.0.1.1' );
                $app->setup_database;
                $db = $app->DB;
                test_db_clean($db);
                init_general_settings($db);
            };
        it "selftest chiper func" => sub {
                is   chiper('cisco'), 'mo8Rm+PV3fY=';
            };
        it "decryptAttrvalue" => sub {
                my $res = $db->decryptAttrvalue( $criptokey, 'mo8Rm+PV3fY=' );
                #                diag $res;
                is $res, 'cisco';
            };
        it "decode_val_from_DB" => sub {
                my $res = $db->decode_val_from_DB( 'username' );
                is $res, 'lab_default';
            }
    };
describe "Router Access:: " => sub {
        my NGNMS::App $app;
        my NGNMS::DB $db;
        before each => sub {
                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( mode => 'poll', dbname => 'ngnms_test', dbhost => 'ngnms-psql',
                    host                          => '10.0.1.1' );
                $app->setup_database;
                $db = $app->DB;
                test_db_clean($db);
                init_general_settings($db);
                my $good_rt_id = $db->addRouter( $good_router, $good_router, 1 );
                $db->addRouter( $router_without_access, $router_without_access, 1 );
                $db->stubs(
                    'getRouterAccess' => sub($){
                        my $self = shift;
                        my $r = shift;
                        return $r == $good_rt_id ? $router_access_encrypted : [ ];
                    },
                );
            };
        it "should return default values if not router exists" => sub {

                my $res = $app->getHostCredentials( $not_router );
                #                diag $res;
                is_deeply($res, $decoded_default);
            };
        it "should return router specific values if exists" => sub {
                my $res = $app->getHostCredentials( $good_router );

                is_deeply($res, $router_access_decoded);
            };
        it "should return default password as priveleged if priveleged is not set"



    };
describe "Command line  Access arguments::" => sub {
        it "command line args should override router access" => sub {
                my $expect = {
                    username            => 'host_user',
                        password            => 'host_pass',
                        privileged_password => 'hostena',
                        transport           => 'SSHV2',
                        community           => 'PubLic2',
                        connect_options     => ['-i','./ssh/id_rsa'],
                };
                NGNMS::App->_clear_instance;
                my $app = NGNMS::App->instance( mode => 'poll', dbname => 'ngnms_test', dbhost => 'ngnms-psql',
                    host                          => '10.0.1.1',
                    host_user                     => 'host_user',
                    host_password                 => 'host_pass',
                    host_priveleged_password      => 'hostena',
                    host_transport                => 'SSHV2',
                    host_community                => 'PubLic2'
                );
                $app->setup_database;
                my $db = $app->DB;
                test_db_clean($db);
                init_general_settings($db);
                my $good_rt_id = $db->addRouter( $good_router, $good_router, 1 );
                $db->addRouter( $router_without_access, $router_without_access, 1 );
                $db->stubs(
                    'getRouterAccess' => sub($){
                        my $self = shift;
                        my $r = shift;
                        return $r == $good_rt_id ? $router_access_encrypted : [ ];
                    },
                );

                my $res = $app->getHostCredentials( $good_router );
                is_deeply($res, $expect);
            };
    };

runtests unless caller;