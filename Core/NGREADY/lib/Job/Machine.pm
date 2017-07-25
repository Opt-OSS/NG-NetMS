package Job::Machine;
$Job::Machine::VERSION = '0.26';
use strict;

1;

=pod

=encoding UTF-8

=head1 NAME

Job::Machine - Job queue handling using PostgreSQL.

=head1 VERSION

version 0.26

=head1 SYNOPSIS

=head2 The Client

  my $client = Job::Machine::Client->new(queue => 'job.task');
  my $id = $client->send({foo => 'bar'});

=head2 The Worker

The Worker is a subclass

  use base 'Job::Machine::Worker';

  sub process {
      my ($self, $data) = @_;
      $self->reply({baz => 'Yeah!'}) if $data->{foo} eq 'bar';
  };

and then use the worker

  my $worker = Worker->new(queue => 'job.task');
  $worker->receive;

Back at the Client:

  if ($client->check('reply')) {
      print $client->receive->{baz};
  }

=head2 Moose

Job::Machine doesn't use Moose itself, so this is the way to subclass it in a Moose environment:

  use MooseX::NonMoose;
  extends 'Job::Machine::Worker';

This makes sure that Moose doesn't step on the precious new method.

=head2 Database Connection

Both client and worker accepts a Database Handle (dbh), or a Data Source Name (dsn).

From scratch:

  my $client = Job::Machine::Client->new(
    dsn => 'dbi:Pg:dbname=jobqueue',
    queue => 'my.queue',
  );

Hot Handle:

  my $dbh = $self->existing_dbh;
  my $client = Job::Machine::Client->new(
    dbh => $dbh,
    queue => 'my.queue',
  );

=head2 Queue

Normally the queue name is passed as a parameter to new, but it can be overriden
for any method call.

The queue can be named anything PostgreSQL accepts. A good idea is to maintain a
hierarchical structure. e.g. I<gl.accounting> or I<message.email>.

=head2 Extra Parameters

You might have some already initialized data you want to pass to your worker
instance. Job::Machine just pushes any extra parameter you send it into the
object, so you can always access it from your process method.

There's no reason to repeat your configuration process in the worker if you already
have it when the worker starts:

	my $config = C<some lenghty process>

	my $worker = SMSio::Worker::CPA->new(
		...
		config => $config,
	);
	$worker->receive;

You can access $self->{config} e.g. in your worker's startup and process methods.

=head1 DESCRIPTION

Job queue handling using PostgreSQL.

A small, but versatile system for sending jobs to a message queue and, if necessary,
communicating answers back to the sender.

Job::Machine uses LISTEN / NOTIFY from PostgreSQL to send signals between
clients and workers. This ensures very efficient message passing, giving any
worker that is awake the chance to start working immediately.

The Database:

The Database Schema of Job::Machine is in sql/create_tables.sql. Just install it into your
database. It is environmental friendly (will not pollute your namespace). By default
it installs in a new jobmachine schema (Database schema, NOT DBIC schema; Job::Machine doesn't use DBIx::Class).

=head2 NB!

Starting with version 0.18, Job::Machine needs at least PostgreSQL 9.0.

Using pg_notify means we need PostgreSQL >= 9.0

=head1 NAME

Job::Machine

=head1 SUPPORT

Report tickets to http://rt.cpan.org/Job-Machine/

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

__END__


# PODNAME: Job::Machine
# ABSTRACT: Job queue handling using PostgreSQL.
