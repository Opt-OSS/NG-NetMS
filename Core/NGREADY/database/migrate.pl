#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use NGNMS::DB::Migration;
use Emsgd qw(diag);
use NGNMS::Log4;

my $logger= NGNMS::Log4->new->get_new_category_logger('mgrations');
my NGNMS::DB::Migration $m = NGNMS::DB::Migration->new_with_options();
if (!$m) {
    $logger->logdie("Could not create migrations");
    return;
}
  # Get current version from database
my $version = $m->version;
if (!defined $version){
    $version= "None";
    print "\n[!]Database is not under version control, run upgrade !\n";
}

$m->migrate;
