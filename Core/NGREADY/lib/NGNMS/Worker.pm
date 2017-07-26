package NGNMS::Worker;

use strict;
use warnings FATAL => 'all';
use base 'Job::Machine::Worker';

use Emsgd qw (diag ss);
use NGNMS::Log4;


my $logger;
#@type NGNMS::DB
my $DB;
sub new {
    my ($class, %args) = @_;

    $logger = NGNMS::Log4->new()->get_new_category_logger('JMWorker');
    $logger->info('Creating worker');

    # possibly call Parent->new(@args) first
    $DB = $args{dbh};
    $args{dbh}=$DB->dbh;
    my $self = $class->SUPER::new(%args);
    # do something else with @args

    # no need to rebless $self, if the Parent already blessed properly

    return $self;
}
sub _process {
    my ($self, $task) = @_;

    my $data = $task->{data};
    diag($data);

    $self->reply({ dataset => "You've got mail", id => $task->{task_id} }); #if $data->{foo} eq 'bar';
    $logger->logdie ("exit by comment") if (defined $data->{die});
    sleep 10;
    $logger->debug ('resume');
};

sub process {
    my ($self, $task) = @_;
    Log::Log4perl::MDC->put('host', $task->{name});
    $logger->debug("dispatching ".$task->{name}." for task #".$task->{task_id} );
    $self->process_runner($task) if ($task->{name} eq 'audit.runner' );
    $self->process_control($task) if ($task->{name} eq 'audit.control' );
    $self->process_archive_load($task) if ($task->{name} eq 'archive.load' );
    $self->process_archive_load($task) if ($task->{name} eq 'archive.unload' );
    $logger->info ("resuming listening");

};
sub process_control{
    my $self = shift;
    my $task = shift;
    my $data = $task->{data};
    my $command = 'no-commnad';
    $command = $data->{command} if defined $data->{command};
    if ($command eq 'restart') {
        $self->reply({ dataset => "Worker stopped", id => $task->{task_id} });
        $logger->logdie('Stopping worker');
    }
    $self->reply({ dataset => "NO controls given", id => $task->{task_id} });
}
sub process_runner{
    my $self = shift;
    my $task = shift;
    use NGNMS::Scheduler::AuditOnDemand;
    eval {
        $logger->info("Starting on-demand audit");
        NGNMS::Scheduler::AuditOnDemand->new(mode => 'jobmachine')->run;
        $self->reply({ dataset => "Audit finished", id => $task->{task_id} }); #if $data->{foo} eq 'bar';
        $logger->info("On-demand audit finished");

    };
    if ($@) {
        $logger->error ($@);
        $self->reply({ dataset => "Audit failed: $@", id => $task->{task_id} }); #if $data->{foo} eq 'bar';
    };
}
sub process_archive_load{
    my $self = shift;
    my $task = shift;
    use NGNMS::Scheduler::ArchiveLoad;
    eval{
        my $data = $task->{data};
        die("Archive id not given") unless defined $data->{archive_id};
        my $r = NGNMS::Scheduler::ArchiveLoad->new(DB=> $DB,archive_id => $data->{archive_id});
        $r->load if ($task->{name} eq 'archive.load' );
        $r->unload if ($task->{name} eq 'archive.unload' );
        $self->reply({ dataset => "Archived", id => $task->{task_id} });
    };
    if ($@) {
        $logger->error ("Process died :".$@);
        $self->reply({ dataset => "Archive load failed: $@", id => $task->{task_id} }); #if $data->{foo} eq 'bar';
    };
}
1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
