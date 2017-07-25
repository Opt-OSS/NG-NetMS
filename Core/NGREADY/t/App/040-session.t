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


my $TMP_DIR = $ENV{NGNMS_HOME}.'/t/tmp';
describe "Session:: cache: " => sub{
        my NGNMS::Net::Session $session;
        my NGNMS::DB $db;
        my ($rt_id, $stubs);
        before each => sub {
                $session = NGNMS::Net::Session->new({record_dir=>$TMP_DIR});
                my $conn = mock();
                $session->connection($conn);
            };
        it "should cache macro by name if  params cache=>1"=>sub{
                $session->connection->expects('macro')->returns("Should be cachesd")->once();
                my $r1 = $session->macro('M1',{cache=>1,timeout=>30,param2=>'string'});
                $session->macro('M1',{cache=>1});
                my $r2 = $session->macro('M1',{cache=>1});
                is $r1,$r2;
            };
      it "should cache macro by default"=>sub{
              $session->connection->expects('macro')->returns("Should be cachesd")->once();
              my $r1 = $session->macro('M1');
              my $r2 = $session->macro('M1');
              is $r1,$r2;
          };
        it "should NOT cache macro if called with params and cache=>0"=>sub{
                $session->connection->expects('macro')->returns("Should be cachesd")->exactly(2)->times;
                my $r1 = $session->macro('M1',{});
                my $r2 = $session->macro('M1',{});
                is $r1,$r2;
            };
        it "should  cache given macro"=>sub{
                $session->connection->expects('macro')->returns("Should be cachesd")->exactly(2)->times;
                my $r1 = $session->macro('M1');
                my $r3 = $session->macro('M2');
                my $r2 = $session->macro('M1');
                my $r4 = $session->macro('M2');

                is $r1,$r2;
                is $r3,$r4;
            };
        it "should use different cache-keys for macros with params";
    };
runtests unless caller;;
