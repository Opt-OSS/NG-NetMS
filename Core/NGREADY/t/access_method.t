#!/usr/bin/perl
use strict;
use warnings;
use AutoLoader qw/AUTOLOAD/;
use Emsgd;
use Test::More ; #for syntax only
use Test::MockModule;#for syntax only
use Test::Subroutines;
use Test::Spec ;
use NGNMS::OLD::Util;
use MIME::Base64;

my (@eccrypted, @decoded, @conn_str, $good_router, $not_router, $router_without_access,$criptokey);

 $criptokey = '123412341234123412341234';
########### Mock DB - no real writes #############################
my $mock_db = Test::MockModule->new('NGNMS_DB');
$mock_db->mock('DB_getBgpRouterId', sub {
        my $ip = shift;
        return 123 if $ip eq $good_router;
        undef
    });
#$mock_db->mock('DB_getBGPRouterAccess', sub($){
#        my $r_id = shift;
#        return \@eccrypted if $r_id == 123;
#    });
$mock_db->mock('DB_getCriptoKey', sub(){
        return  $criptokey;
    });


############### test values ############################
@conn_str = qw( user  pass   ena_pass transport);
@decoded = qw( lab   PocLab cisco    Telnet);
$good_router = '20.1.1.1';
$not_router = '1.1.1.1';
$router_without_access = '10.0.0.1';
@eccrypted = (
    [
        'Telnet',
        undef,
        'Login',
        'lUxJzFwE4Yg='
    ],
    [
        'Telnet',
        undef,
        'Password',
        'YEe5NW4OZxQ='
    ],
    [
        'Telnet',
        undef,
        'Port',
        'aliNNFMjX4c='
    ],
    [
        'Telnet',
        undef,
        'Enpassword',
        'mo8Rm+PV3fY='
    ]
);

#describe 'BGP routers ::' => sub {
#        it "decode_val_from_DB decryptAttrvalue"=>sub{
#                my $res = NGNMS_util::decryptAttrvalue($criptokey,'lUxJzFwE4Yg=');
#                diag $res;
#                is $res,'lab';
#            };
#        it 'should return default values if not router exists' => sub {
#                my @res = NGNMS_util::decode_bgp_access_method($not_router, @conn_str);
#                is_deeply(\@res, \@conn_str);
#            };
#        it 'should return default values if not access method defined for host' => sub {
#                my @res = NGNMS_util::decode_bgp_access_method($router_without_access, @conn_str);
#                is_deeply(\@res, \@conn_str);
#            };
#        it 'should decode values' => sub {
#                my @res = NGNMS_util::decode_bgp_access_method($good_router, @conn_str);
#                is_deeply(\@res, \@decoded);
#            };
#        xit 'should return access for host if it defined AND not defined bgp-access';
#    };
runtests unless caller;