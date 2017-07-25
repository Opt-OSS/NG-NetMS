#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Emsgd qw(diag);
use NGNMS::Worker;
use NGNMS::App;
use Data::Serializer::Raw;
my $app = NGNMS::App->instance;
my $dbh = $app->get_db()->dbh;
my $audit = NGNMS::Worker->new(
    dbh => $dbh,
    queue => ['audit.runner','audit.control'],
    serialize=> Data::Serializer::Raw->new(serializer => 'JSON')
);
$audit->receive;
