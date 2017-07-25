package NGNMS::Worker;
use strict;
use warnings FATAL => 'all';
use base 'Job::Machine::Worker';

use Emsgd qw (diag);
use NGNMS::Log4;
use NGNMS::Scheduler::AuditOnDemand;
use Try::Tiny qw /try catch/;

my $logger;
sub new {
    my ($class, %args) = @_;

    $logger =  NGNMS::Log4->new()->get_new_category_logger('JMWorker.audit');
    $logger->info('Creating worker');

    # possibly call Parent->new(@args) first
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
    $logger->debug("dispatching ".$task->{name}." for task #".$task->{task_id} );
    $self->process_runner($task) if ($task->{name} eq 'audit.runner' );
    $self->process_control($task) if ($task->{name} eq 'audit.control' )

};
sub process_control{
    my $self = shift;
    my $task = shift;
    my $data = $task->{data};
    my $command='no-commnad';
    $command = $data->{command} if defined $data->{command};
    if ($command eq 'restart'){
        $self->reply({ dataset => "Worker stopped", id => $task->{task_id} });
        $logger->logdie('Stopping worker');
    }
    $self->reply({ dataset => "NO controls given", id => $task->{task_id} });
}
sub process_runner{
    my $self = shift;
    my $task = shift;
    eval{
        $logger->info("Starting on-demand audit");
        NGNMS::Scheduler::AuditOnDemand->new(mode=>'jobmachine')->run;
        $self->reply({ dataset => "Audit finished", id => $task->{task_id} }); #if $data->{foo} eq 'bar';
        $logger->info("On-demand audit finished");

    };
        if (@!){
        my $e = $_;
        $logger->error ("caught error: $e");
        $self->reply({ dataset => "Audit failed: $e", id => $task->{task_id} }); #if $data->{foo} eq 'bar';
    };
    $logger->info ("resuming listening");

}
1;