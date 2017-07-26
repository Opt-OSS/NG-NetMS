#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Emsgd qw(diag ss);
use NGNMS::Worker;
use NGNMS::App;
use Data::Serializer::Raw;
use NGNMS::Log4;
my $jmlog = NGNMS::Log4->new()->get_new_category_logger('JMDaemon');
$jmlog->info("daemon started");

    my $app = NGNMS::App->instance;
#    $jmlog->debug(ss $app->get_db());
    my $dbh = $app->get_db();
    my $audit = NGNMS::Worker->new(
        dbh => $dbh,
        queue => ['audit.runner','audit.control','archive.load','archive.unload'],
        serialize=> Data::Serializer::Raw->new(serializer => 'JSON')
    );
    $audit->receive;
