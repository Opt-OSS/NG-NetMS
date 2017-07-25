#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use Moo;
use MooX::Options;
use NGNMS::Scheduler;
use Try::Tiny qw /try catch/;
use NGNMS::Log4;
use Emsgd qw/diag/;


my $logger = NGNMS::Log4->new()->get_new_category_logger('scheduler');
try{
    $logger->debug("Starting scheduling renewals");
    my NGNMS::Scheduler $app = NGNMS::Scheduler->new_with_options();
    $app->run();
}    catch {
    print $_;
    $logger->error(  $_); # not $@
};
    $logger->debug("Finishing scheduling renewals");
