#!/usr/bin/perl
use strict;
use warnings;
use AutoLoader qw/AUTOLOAD/;
use Emsgd;
use Test::More ; #for syntax only
use Test::MockModule;#for syntax only
use Test::Spec ;
use Test::Fatal;
use NGNMS::OLD::Util;
use File::Slurp;

use NGNMS::DB;


my $connection = {
    host     => $ENV{NGNMS_DB_HOST},
    port     => $ENV{NGNMS_DB_PORT},
    database => $ENV{NGNMS_DB},
    username => $ENV{NGNMS_DB_USER},
    password => $ENV{NGNMS_DB_PASSWORD},

};
describe 'it should be singeton' => sub {
        before each => sub {
                NGNMS::DB->_clear_instance;
            };
        it 'instance return the same object' => sub {
                my $db = NGNMS::DB->instance( $connection )->dbh;
                my $db2 = NGNMS::DB->instance( $connection )->dbh;
                is $db, $db2;
            };
        it 'it should not use deaults ENV' => sub {
                like( exception { NGNMS::DB->instance( ) },qr/could not connect/, 'expecting to die' );
            };

    };

describe  'Postgress DB' => sub {
        before each => sub {
                NGNMS::DB->_clear_instance;
            };
        it 'shold be hanle to do SQL' => sub {

                my $dbh = NGNMS::DB->instance( $connection )->dbh();
                $dbh->do( "insert into routers (router_id,name) values(1,'rname')" );
                my $SQL = "SELECT * FROM routers where router_id=1";
                my $href = $dbh->selectall_arrayref( $SQL );
                is  scalar( @$href ), 1;
                $dbh->do( "delete from routers where router_id = 1" );
                is_deeply $dbh->selectall_arrayref( $SQL ), [ ];

            }

    };

runtests unless caller;