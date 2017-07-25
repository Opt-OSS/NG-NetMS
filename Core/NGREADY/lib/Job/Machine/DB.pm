package Job::Machine::DB;
$Job::Machine::DB::VERSION = '0.26';
use strict;
use warnings;
use Carp qw/croak confess/;
use DBI;
use Data::Serializer;


use Emsgd qw(diag);
use constant QUEUE_PREFIX    => 'jm:';
use constant RESPONSE_PREFIX => 'jmr:';


sub new {
	my ($class, %args) = @_;
	croak "No connect information" unless $args{dbh} or $args{dsn};
	croak "invalid queue" if ref $args{queue} and ref $args{queue} ne 'ARRAY';

	$args{dbh_inherited} = 1 if $args{dbh};
	$args{user}     ||= undef;
	$args{password} ||= undef;
	$args{db_attr}  ||= undef;
	$args{dbh}      ||= DBI->connect($args{dsn},$args{user},$args{password},$args{db_attr});
	$args{database_schema}   ||= 'jobmachine';

	return bless \%args, $class;
}
#@returns Data::Serializer
sub serializer {

	my ($self) = @_;
	my $args = $self->{serializer_args} || {};
	$args->{serializer} ||= $self->{serializer} || 'Sereal';
	return $self->{serialize} ||= Data::Serializer->new(%$args);
}


sub listen {
	my ($self, %args) = @_;
	my $queue = $args{queue} || return undef;

	my $prefix = $args{reply} ?  RESPONSE_PREFIX :  QUEUE_PREFIX;
	for my $q (ref $queue ? @$queue : ($queue)) {
		$self->{dbh}->do(qq{listen "$prefix$q";});
	}
}


sub unlisten {
	my ($self, %args) = @_;
	my $queue = $args{queue} || return undef;

	my $prefix = $args{reply} ?  RESPONSE_PREFIX :  QUEUE_PREFIX;
	for my $q (ref $queue ? @$queue : ($queue)) {
		$self->{dbh}->do(qq{unlisten "$prefix$q";});
	}
}


sub notify {
	my ($self, %args) = @_;
	my $queue = $args{queue} || return undef;
	my $payload = $args{payload};
	my $prefix = $args{reply} ?  RESPONSE_PREFIX :  QUEUE_PREFIX;
	$queue = $prefix . $queue;
	my $sql = qq{SELECT pg_notify(?,?)};
	my $task = $self->select_first(
		sql => $sql,
		data => [ $queue, $payload],
	);
}


sub get_notification {
	my ($self,$timeout) = @_;
	my $dbh = $self->dbh;
	my $notifies = $dbh->func('pg_notifies');
	return $notifies;
}


sub set_listen {
	my ($self,$timeout) = @_;
	my $dbh = $self->dbh;
	my $notifies = $dbh->func('pg_notifies');
	if (!$notifies) {
		my $fd = $dbh->{pg_socket};
		vec(my $rfds='',$fd,1) = 1;
		my $n = select($rfds, undef, undef, $timeout);
		$notifies = $dbh->func('pg_notifies');
	}
	return $notifies || [0,0];
}


sub fetch_work_task {
	my $self = shift;
	my $queue = ref $self->{queue} ? $self->{queue} : [$self->{queue}];
	$self->{current_table} = 'task';
	my $elems = join(',', ('?') x @$queue);
	my $sql = qq{
		UPDATE "$self->{database_schema}".$self->{current_table} t
		SET status=100,
			modified=default
		FROM "jobmachine".class cx
		WHERE t.class_id = cx.class_id
		AND task_id = (
			SELECT min(task_id)
			FROM "$self->{database_schema}".$self->{current_table} t
			JOIN "jobmachine".class c USING (class_id)
			WHERE t.status=0
			AND c.name IN ($elems)
			AND (t.run_after IS NULL
			OR t.run_after > now())
		)
		AND t.status=0
		RETURNING *
		;
	};
	my $task = $self->select_first(
		sql => $sql,
		data => $queue
	) || return;

	$self->{task_id} = $task->{task_id};
	$task->{data} = $self->serializer->deserialize(delete $task->{parameters});
	return $task;
}


sub insert_task {
	my ($self,$data,$queue) = @_;
	my $class = $self->fetch_class($queue);
	$self->{current_table} = 'task';
	my $frozen = $self->serializer->serialize($data);
	my $sql = qq{
		INSERT INTO "$self->{database_schema}".$self->{current_table}
			(class_id,parameters,status)
		VALUES (?,?,?)
		RETURNING task_id
	};
	$self->insert(sql => $sql,data => [$class->{class_id},$frozen,0]);
}


sub set_task_status {
	my ($self,$status) = @_;
	my $id = $self->task_id;
	$self->{current_table} = 'task';
	my $sql = qq{
		UPDATE "$self->{database_schema}".$self->{current_table}
		SET status=?
		WHERE task_id=?
	};
	$self->update(sql => $sql,data => [$status,$id]);
}


sub fetch_class {
	my ($self,$queue) = @_;
	$self->{current_table} = 'class';
	my $sql = qq{
		SELECT *
		FROM "$self->{database_schema}".$self->{current_table}
		WHERE name=?
	};
	return $self->select_first(sql => $sql,data => [$queue]) || $self->insert_class($queue);
}


sub fetch_task {
	my ($self,$id) = @_;
	$self->{current_table} = 'task';
	my $sql = qq{
		SELECT t.*, c.name
		FROM "$self->{database_schema}".$self->{current_table} t
		JOIN "$self->{database_schema}".class c USING (class_id)
		WHERE task_id=?
	};
	my $task = $self->select_first(sql => $sql,data => [$id]) or return;

	$task->{frozen} = $task->{parameters};
	$task->{parameters} = $self->serializer->deserialize($task->{parameters});
	return $task;
}


sub insert_class {
	my ($self,$queue) = @_;
	my $sql = qq{
		INSERT INTO "$self->{database_schema}".$self->{current_table}
			(name)
		VALUES (?)
		RETURNING class_id
	};
	$self->select_first(sql => $sql,data => [$queue]);
}


sub insert_result {
	my ($self,$data) = @_;
	$self->{current_table} = 'result';
	my @columns = qw/task_id result/;
	my @values = ($self->{task_id});
	if (ref $data eq 'HASH') {
		push @columns, 'resulttype';
		my $type = delete $data->{type};
		push @values, $self->serializer->serialize($data), $type;
	} else {
		push @values, $self->serializer->serialize($data);
	}
	my $columns = join ', ', @columns;
	my $qs = join(',', ('?') x @columns);
	my $sql = qq{
		INSERT INTO "$self->{database_schema}".$self->{current_table}
			($columns)
		VALUES ($qs)
		RETURNING result_id
	};
	$self->insert(sql => $sql,data => \@values);
}


sub fetch_result {
	my ($self,$result_id) = @_;
	$self->{current_table} = 'result';
	my $sql = qq{
		SELECT *
		FROM "$self->{database_schema}".$self->{current_table}
		WHERE result_id=?
	};
	my $result = $self->select_first(sql => $sql,data => [$result_id]) || return;

	my $r = $self->serializer->deserialize($result->{result});
	$result->{result} = $r;
	return $result;
}


sub fetch_first_result {
	my ($self,$task_id) = @_;
	$self->{current_table} = 'result';
	my $sql = qq{
		SELECT *
		FROM "$self->{database_schema}".$self->{current_table}
		WHERE task_id=?
		ORDER BY result_id DESC
	};
	my $result = $self->select_first(sql => $sql,data => [$task_id]) || return;

	return $self->serializer->deserialize($result->{result});
}


sub fetch_results {
	my ($self,$id) = @_;
	$self->{current_table} = 'result';
	my $sql = qq{
		SELECT *
		FROM "$self->{database_schema}".$self->{current_table}
		WHERE task_id=?
		ORDER BY result_id DESC
	};
	my $results = $self->select_all(sql => $sql,data => [$id]) || return;

	return [map { {id => $_->{result_id}, type => $_->{resulttype}, result => $self->serializer->deserialize($_->{result}) } } @{ $results } ];
}


sub get_statuses {
	my ($self) = @_;
	$self->{current_table} = 'task';
	my $sql = qq{
		SELECT status
		FROM "$self->{database_schema}".$self->{current_table}
		GROUP BY status
	};
	my $stats = $self->select_all(sql => $sql) || return;
	return $stats;
}


sub get_classes {
	my ($self) = @_;
	$self->{current_table} = 'class';
	my $sql = qq{
		SELECT *
		FROM "$self->{database_schema}".$self->{current_table}
	};
	my $stats = $self->select_all(sql => $sql) || return;
	return $stats;
}


sub get_tasks {
	my ($self,%args) = @_;
	$self->{current_table} = 'task';
	my ($where_clause, @where_args) = $self->where_clause($args{where});
	my $order_by = $self->order_by($args{order_by});
	my $sql = qq{
		SELECT t.*, c.name
		FROM "$self->{database_schema}".$self->{current_table} t
		JOIN "$self->{database_schema}".class c USING (class_id)
		$where_clause
		$order_by
	};
	my $tasks = $self->select_all(sql => $sql,data => \@where_args) || return;
	return $tasks;
}


sub revive_tasks {
	my ($self,$max) = @_;
	$self->{current_table} = 'task';
	my $status = 100;
	my $sql = qq{
		UPDATE "$self->{database_schema}".$self->{current_table}
		SET status=0
		WHERE status=?
		AND modified < now() - INTERVAL '$max seconds'
	};
	my $result = $self->do(sql => $sql,data => [$status]);
	return $result;
}


sub fail_tasks {
	my ($self,$retries) = @_;
	$self->{current_table} = 'result';
	my $limit = 100;
	my $sql = qq{
		SELECT task_id
		FROM "$self->{database_schema}".$self->{current_table}
		GROUP BY task_id
		HAVING count(*)>?
		LIMIT ?
	};
	my $result = $self->select_all(sql => $sql,data => [$retries,$limit]) || return 0;
	return 0 unless @$result;

	my $task_ids = join ',',map {$_->{task_id}} @$result;
	$self->{current_table} = 'task';
	my $status = 900;
	$sql = qq{
		UPDATE "$self->{database_schema}".$self->{current_table}
		SET status=?
		WHERE task_id IN ($task_ids)
	};
	$self->do(sql => $sql,data => [$status]);
	return scalar @$result;
}


sub remove_tasks {
	my ($self,$after) = @_;
	return 0 unless $after;

	$self->{current_table} = 'task';
	my $limit = 100;
	my $sql = qq{
		DELETE FROM "$self->{database_schema}".$self->{current_table}
		WHERE modified < now() - INTERVAL '$after days'
	};
	my $result = $self->do(sql => $sql,data => []);
	return $result;
}


sub select_first {
	my ($self, %args) = @_;
	my $sth = $self->dbh->prepare($args{sql}) || return 0;

	unless($sth->execute(@{$args{data}})) {
		my @c = caller;
		print STDERR "File: $c[1] line $c[2]\n";
		print STDERR $args{sql}."\n" if($args{sql});
		return 0;
	}
	my $r = $sth->fetchrow_hashref();
	$sth->finish();
	return ( $r );
}


sub select_all {
	my ($self, %args) = @_;
	my $sth = $self->dbh->prepare($args{sql}) || return 0;
	$self->set_bind_type($sth,$args{data} || []);
	unless($sth->execute(@{$args{data}})) {
		my @c = caller;
		print STDERR "File: $c[1] line $c[2]\n";
		print STDERR $args{sql}."\n" if($args{sql});
		return 0;
	}
	my @result;
	while( my $r = $sth->fetchrow_hashref) {
			push(@result,$r);
	}
	$sth->finish();
	return ( \@result );
}

sub set_bind_type {
	my ($self,$sth,$data) = @_;
	for my $i (0..scalar(@$data)-1) {
		next unless(ref($data->[$i]));

		$sth->bind_param($i+1, undef, $data->[$i]->[1]);
		$data->[$i] = $data->[$i]->[0];
	}
	return;
}

sub do {
	my ($self, %args) = @_;
	my $sth = $self->dbh->prepare($args{sql}) || return 0;

	$sth->execute(@{$args{data}});
	my $rows = $sth->rows;
	$sth->finish();
	return $rows;
}

sub insert {
	my ($self, %args) = @_;
	my $sth = $self->dbh->prepare($args{sql}) || return 0;

	$sth->execute(@{$args{data}});
	my $retval = $sth->fetch()->[0];
	$sth->finish();
	return $retval;
}

sub update {
	my $self = shift;
	$self->do(@_);
	return;
}

sub dbh {
	return $_[0]->{dbh} || confess "No database handle";
}

sub task_id {
	return $_[0]->{task_id} || confess "No task id";
}

sub disconnect {
	return $_[0]->{dbh}->disconnect if $_[0]->{dbh};
}

sub DESTROY {
	my $self = shift;
	$self->disconnect() unless $self->{dbh_inherited};
	return;
}


sub where_clause {
	my ($self, $where) = @_;
	my $where_clause = join(' AND ', ("$_ = ?") x keys %$where);
	$where_clause = "WHERE $where_clause" if $where_clause;
	return $where_clause, values %$where;
}


sub order_by {
	my ($self, $order) = @_;
	return unless ref $order eq 'HASH';

	my $order_by = join(',', ("$_") x keys %$order);
	$order_by = "ORDER BY $order_by" if $order_by;
	return $order_by;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Job::Machine::DB

=head1 VERSION

version 0.26

=head1 NAME

Job::Machine::DB - Database class for Job::Machine

=head1 METHODS

=head2 new

  my $client = Job::Machine::DB->new(
	  dbh   => $dbh,
	  queue => 'queue.subqueue',

  );

  my $client = Job::Machine::Base->new(
	  dsn   => @dsn,
  );

=head2 serializer

Returns the serializer, default Data::Serializer

=head2 listen

Sets up the listener.  Quit listening to the named queues. If 'reply' is
passed, we listen to the related reply queue instead of the task queue.

Return undef immediately if no queue is provided.

 $self->listen( queue => 'queue_name' );
 $self->listen( queue => \@queues, reply => 1  );

=head2 unlisten

Quit listening to the named queues. If 'reply' is passed, we unlisten
to the related reply queue instead of the task queue.

Return undef immediately if no queue is provided.

 $self->unlisten( queue => 'queue_name' );
 $self->unlisten( queue => \@queues, reply => 1  );

=head2 notify

Sends an asynchronous notification to the named queue, with an optional
payload. If 'reply' is true, then the queue names are taken to be reply.

Return undef immediately if no queue name is provided.

 $self->notify( queue => 'queue_name' );
 $self->notify( queue => 'queue_name', reply => 1, payload => $data  );

=head2 get_notification

Retrieve one notification, if there is one

Retrievies the pending notifications.

 my $notifies = $self->get_notification();

The return value is an arrayref where each row looks like this:

 my ($name, $pid, $payload) = @$notify;

=head2 set_listen

Wait for a notification. The required parameter timeout tells for how long time to wait.

=head2 fetch_work_task

Fetch one work task from the task table

=head2 insert_task

Insert a row in the task table

=head2 set_task_status

Update the task with a new status

=head2 fetch_class

Fetch a class

=head2 fetch_task

Fetch a task

=head2 insert_class

Insert a row in the class table

=head2 insert_result

Insert a row in the result table

Argument

 data - either a scalar value that will be inserted as the result, or a hashref containing the type and result

=head2 fetch_result

Fetch a result using the result id

=head2 fetch_first_result

Fetch a result using the task id

=head2 fetch_results

Fetch all results of a given task

=head2 get_statuses

Fetch all distinct statuses

=head2 get_classes

Fetch all classes

=head2 get_tasks

Fetch all tasks, joined with the class for a suitable name

=head2 revive_tasks

	1. Find started tasks that have passed the time limit, most probably because of a dead worker. (status 100, modified < now - max_runtime)
	2. Trim status so task can be tried again

=head2 fail_tasks

	1. Find tasks that have failed too many times (# of result rows > $self->retries
	2. fail them (Set status 900)
	There's a hard limit (100) for how many tasks can be failed at one time for
	performance resons

=head2 remove_tasks

	3. Find tasks that should be removed (remove_task < now)
	- delete them
	- log

=head2 select_first

Select the first row from the given sql statement

=head2 select_all

Select all rows from the given sql statement

=head2 where_clause

Very light weight where clause builder

=head2 order_by

Very light weight order-by builder

=head1 AUTHOR

Kaare Rasmussen <kaare@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009,2015, Kaare Rasmussen

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Kaare Rasmussen <kaare at cpan dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kaare Rasmussen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
