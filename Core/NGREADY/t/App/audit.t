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

describe 'Audit - gets params from command line' => sub {
        it 'gets run mode from command-line';

    };

runtests unless caller;