package Job::Machine::Worker;
$Job::Machine::Worker::VERSION = '0.26';
use strict;
use warnings;

use base 'Job::Machine::Base';

sub reply {
	my ($self,$data,$queue) = @_;
	my $db = $self->db;
	$queue ||= $self->{queue};
	$self->result($data,$queue);
	my $task_id = $db->task_id;
## Payload: Status of result, result id...
	$db->notify(queue => $task_id, reply => 1);
	return $task_id;
}

sub result {
	my ($self,$data,$queue) = @_;
	$queue ||= $self->{queue};
	$self->db->insert_result($data,$queue);
	$self->db->set_task_status(200);
}

sub error_result {
	my ($self,$data,$queue) = @_;
	$queue ||= $self->{queue};
	$self->db->insert_result($data,$queue);
}

sub receive {
	my $self = shift;
	$self->startup;
	my $db = $self->{db};
	$self->_init_chores;
	$self->subscribe($self->{queue});
	$self->_check_queue($self->{queue});
	while ($self->keep_running && (my $notifies = $db->set_listen($self->timeout))) {
		my ($queue,$pid) = @$notifies;
		$self->_do_chores() && next unless $queue;

		$self->_check_queue($self->{queue});
	}
	return;
};

sub _check_queue {
	my $self = shift;
	my $db = $self->{db};
	while (my $task = $self->db->fetch_work_task) {
		## log process call
		$self->process($task);
	}
}


sub _init_chores {
	my $self = shift;
	my $db = $self->{db};
	my @chores = (
		sub {
			my $self = shift;
			my $number = $db->revive_tasks($self->max_runtime) || 0;
			$self->job_log("Revived tasks: $number");
		},
		sub {
			my $self = shift;
			my $number = $db->fail_tasks($self->retries) || 0;
			$self->job_log("Failed tasks: $number");
		},
		sub {
			my $self = shift;
			my $number = $db->remove_tasks($self->remove_after) || 0;
			$self->job_log("Removed tasks: $number");
		},
	);
	push @{ $self->{chores} }, @chores;
}


sub add_chore {
	my ($self, $chore) = @_ ;
	return unless ref $chore eq 'CODE';

	push @{ $self->{chores} }, $chore;
}

sub _do_chores {
	my $self = shift;
	my $chores = $self->{chores};
	my $idx = int(rand(@{ $chores }));
	my $chore = $chores->[$idx];
	$self->$chore;
}

sub startup {}

sub process {die 'Subclasss me!'}

sub max_runtime {return 30*60}

sub timeout {return 300}

sub retries {return 3}

sub remove_after {return 30}

sub keep_running {return 1}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Job::Machine::Worker

=head1 VERSION

version 0.26

=head1 DESCRIPTION

=head2 Write a script to instantiate your class and start the receive loop:

  my $worker = My::Worker->new(dbh => $dbh, queue => 'job.task');
  $worker->receive;

=head2 Write the Worker Class

  Job::Machine::Worker inherits from Job::Machine::Base. All you have to do is

  package My::Worker;
  
  use base 'Job::Machine::Worker';

  sub process {
	  my ($self, $task) = @_;
	  $queuename = $task->{name};
	  ... do stuff
  };

=head2 _init_chores

Push the internal chores onto the chores list.

By pushing, we make sure that we don't destroy any existing chores.

NOTE. This is an internal method, meant to make sure that important Job::Machine tasks get done.

=head2 add_chore

Takes a coderef and push it onto the chores list.

The supplied coderef can do anything, but is supposed to perform some kind of housekeeping.

It takes turns with the other chores, including the internal ones.

=head1 NAME

Job::Machine::Worker - Base class for Job Workers

=head1 METHODS

=head2 Methods to be subclassed

A worker process always needs to subclass the process method with the
real functionality.

=head3 startup

 startup will be called before any tasks are fetched and any processing is done.

 Call this method for one-time initializing.

=head3 process

 Subclassable process method.

 E.g. 

 sub process {
	my ($self, $data) = @_;
	... process $data 
	$self->reply({answer => 'Something'});
 };

=head3 max_runtime

If the default of 30 minutes isn't suitable, return the number of seconds a
process is expected to run.

A task will not be killed if it runs for longer than max_runtime. This setting
is only used when reviving tasks that are suspected to be dead.

=head3 timeout

If the default of 5 minutes isn't suitable, return the number of seconds the
worker should wait for notifications before doing housekeeping chores.

If you don't want the worker to perform any housekeeping tasks, return undef

=head3 retries

If the default of 3 times isn't suitable, return the number of times a task is
retried before failing.

=head3 remove_after

If the default of 30 days isn't suitable, return the number of days a task will
remain in the database before being removed.

Return 0 if you never want tasks to be removed.

=head3 keep_running

Worker will wait for next message if this method returns true.

=head2 Methods to be used from within the process method

=head3 reply

  $worker->reply($some_structure);

  Reply to a message. Use from within a Worker's process method.

  Marks the task as done,

=head3 result

	Use from within a Worker's process method.

	$worker->result($result_data);

	Save the result of the task.

	Marks the task as done,

=head3 error_result

	Use from within a Worker's process method.

	$worker->error_result($result_data);

	Save the result of the task.

	Does NOT change the job status,

=head3 db

 Get the DB class. From this it's possible to get the database handle
 
 my $dbh = $self->db->dbh;
 
 If you use the same database for Job::Machine as for your other data, this
 handle can be used by your worker module.

=head3 id

  Get the current task id.

=head2 methods not to be disturbed

=head3 receive

  $worker->receive;
  
  Starts the Worker's receive loop.
  
  receive subscribes the worker to the queue and waits for a message to be passed along.
  It will first see if there are any messages to be processed.

=head1 SEE ALSO

L<Job::Machine::Base>.

=head1 AUTHOR

Kaare Rasmussen <kaare@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009,2014, Kaare Rasmussen

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Kaare Rasmussen <kaare at cpan dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kaare Rasmussen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
