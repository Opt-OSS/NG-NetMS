#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
#use Rose::DB;
use Job::Machine::Client;
use Emsgd qw (diag);
use NGNMS::App;
use Data::Serializer::Raw;

my $app = NGNMS::App->instance;

my $dbh = $app->get_db()->dbh;

ngnms_log "Starting worker";

sub serialize {
    my $self = shift;
    my $payload = shift;
    diag \@_;
    return $payload;
}
my $cref = \&serialize;
my $client = Job::Machine::Client->new(
    dbh => $dbh,
    queue => 'job.task',
    serialize=> Data::Serializer::Raw->new(serializer => 'JSON')

);
my $id1;
#    $id1 = $client->send({foo => 'bar',die=>1});
    $id1 = $client->send({foo => 'bar'});


my $s = $client->check($id1);
    my $r =  $client->receive($id1);
    diag ($r,$id1);

