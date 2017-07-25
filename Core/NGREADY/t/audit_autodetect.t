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


my (@eccrypted, @decoded, @conn_str, $good_router, $not_router, $router_without_access);
my $TMP_DIR = 't/tmp';
my $Fixtures_dir = 't/fixtures/autodetect_hosttype';

local $ENV{"NGNMS_DATA"} = $Fixtures_dir;
my ($res, $er);
describe 'Host type by file contents' => sub {

        it 'shold detect juniper by bgp' => sub {
                ($res, $er) = NGNMS::OLD::Util::autodetect_host_type_by_file_content($Fixtures_dir, 'juniper-bgponly');
                is $res, 'Juniper';
            };
        it 'shold detect cisco by bgp' => sub {
                ($res, $er) = NGNMS::OLD::Util::autodetect_host_type_by_file_content($Fixtures_dir, 'cisco-bgponly');
                is $res, 'Cisco';
            };
        it 'shold detect juniper by ospf' => sub {
                ($res, $er) = NGNMS::OLD::Util::autodetect_host_type_by_file_content($Fixtures_dir, 'juniper-ospfonly');
                is $res, 'Juniper';
            };
        it 'shold detect OLD juniper (Jupiter) by ospf' => sub {
                ($res, $er) = NGNMS::OLD::Util::autodetect_host_type_by_file_content($Fixtures_dir, 'juniper_1-ospfonly');
                is $res, 'Juniper';
            };

        it 'shold detect cisco by bgp' => sub {
                ($res, $er) = NGNMS::OLD::Util::autodetect_host_type_by_file_content($Fixtures_dir, 'cisco-ospfonly');
                is $res, 'Cisco';
            };
        it 'shold detect juniper by auto-file' => sub {
                ($res, $er) = NGNMS::OLD::Util::autodetect_host_type_by_file_content($Fixtures_dir, 'juniper');
                is $res, 'Juniper';
            };
        it 'shold detect cisco by auto-file' => sub {
                ($res, $er) = NGNMS::OLD::Util::autodetect_host_type_by_file_content($Fixtures_dir, 'cisco');
                is $res, 'Cisco';
            };
        it 'shold detect unknown if no-file' => sub {
                ($res, $er) = NGNMS::OLD::Util::autodetect_host_type_by_file_content($Fixtures_dir, 'not-exists');
                ($res, $er) = $res, 'unknown';
            };
        it 'shold return error if lile not fond'=> sub {
                ($res, $er) = NGNMS::OLD::Util::autodetect_host_type_by_file_content($Fixtures_dir, 'not-exists');
                isnt $er, '';
            };;

        it 'shold detect unknown if not supported format' => sub {
                ($res, $er) = NGNMS::OLD::Util::autodetect_host_type_by_file_content($Fixtures_dir, 'not-supported');
                is $res, 'unknown';
            };


    };

runtests unless caller;