package NGNMS::Scheduler;

use strict;
use warnings FATAL => 'all';
use Emsgd qw/diag/;
use Moo;
use MooX::Options;
use NGNMS::Scheduler::Archive;
use NGNMS::Scheduler::Audit;
use NGNMS::Scheduler::AuditOnDemand;

with "NGNMS::DB::CommandLineOptions";
with "NGNMS::App::Database";
with "NGNMS::Log4Role";

sub run{
    my $self=shift;
    $self->setup_database();
    my $options = {
        DB            => $self->get_db,
        dbhost=>$self->DB->host,
        dbport=>$self->DB->port,
        dbname=>$self->DB->database,
        dbuser=>$self->DB->username,
        dbpassword=>$self->DB->password,
        ngnms_user=>'ngnms',
    };
    NGNMS::Scheduler::Archive->new($options)->schedule();
    NGNMS::Scheduler::Audit->new($options)->schedule();
    NGNMS::Scheduler::AuditOnDemand->new()->run();
    return;

}

1;
# ABSTRACT: This file is part of open source NG-NetMS tool.

