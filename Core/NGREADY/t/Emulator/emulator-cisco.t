#!/usr/bin/perl
use strict;
use warnings;
use UNIVERSAL;
use Emsgd;
use Test::More ; #for syntax only
use Test::MockModule;#for syntax only
use Test::Subroutines;
use Test::Spec ;
use File::Slurp;

use  NGNMS::Net::Emulator::Host;
my $FixturesDir = 't/fixtures/Emulator';

describe 'it has session:: ' => sub {
        it 'has good class' => sub {
                can_ok( 'NGNMS::Net::Emulator::Session', 'cmd' );
                can_ok( 'NGNMS::Net::Emulator::Session', 'macro' );
                can_ok( 'NGNMS::Net::Emulator::Session', 'begin_privileged' );
                can_ok ( 'NGNMS::Net::Emulator::Host', 'session' );
            };
        it 'Cisco' => sub {
                my $e = NGNMS::Net::Emulator::Host->new( { 'type' => 'Cisco' } );
                isa_ok $e, 'NGNMS::Net::Emulator::Host';
                isa_ok $e->session, 'NGNMS::Net::Emulator::Session';

            };
        it 'cmd:: return undefined if no reply given' => sub {
                my $e = NGNMS::Net::Emulator::Host->new( { 'type' => 'Cisco' } );
                is $e->session->cmd( 'cmd-no-exist' ), undef;
            };
        it 'cmd:: return echo if reply exists' => sub {
                my $e = NGNMS::Net::Emulator::Host->new( {
                        'type' => 'Cisco',
                        reply  => { 'cmd1' => 'responce_file_name' }
                    } );
                is $e->session->cmd( 'cmd1' ), 'responce_file_name';
            };
        it 'macro:: it respoonds with filen contents if it existws' => sub {
                my $a = 'NGNMS::Net::Emulator::Host';
                my $e = $a->new( {
                        'type'    => 'Cisco',
                        reply_dir => $FixturesDir,
                        reply     => { 'get_echo' => 'simple_echo.txt' }
                    } );
                is $e->session->macro( 'get_echo' ), 'echo';
            };

    };
describe 'it shouul implement Cisco  Role::' => sub {
        it 'echo' => sub {
                my $e = NGNMS::Net::Emulator::Host->new( {
                        'type' => 'Cisco'
                    } );
                is $e->echo_test,'Cisco';
            }
    };
describe 'it shouul implement Juniper  Role::' => sub {
        it 'echo' => sub {
                my $e = NGNMS::Net::Emulator::Host->new( {
                        'type' => 'Juniper'
                    } );
                Emsgd::diag $e;
                is $e->echo_test,'Juniper';
            }
    };
runtests unless caller;