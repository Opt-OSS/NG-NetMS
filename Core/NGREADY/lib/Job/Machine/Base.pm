package Job::Machine::Base;
$Job::Machine::Base::VERSION = '0.26';
use strict;
use warnings;
use Carp;
use Job::Machine::DB;

sub new {
	my ($class, %args) = @_;
	$args{db} = Job::Machine::DB->new( %args );
	return bless \%args, $class;
}

#@returns Job::Machine::DB
sub db { return $_[0]->{db} };

sub id {
	my ($self, $id) = @_;
	$self->{id} = $id if defined $id;
	return $self->{id};
}

sub subscribe {
	my ($self, $queue, $reply) = @_;
	$queue ||= $self->{queue};
	$reply ||= 0;
	return $self->db->listen(queue => $queue, reply => $reply);
}

sub job_log {
	my ($self, $msg) = @_;
	print STDERR $msg, "\n";
	return;
	# $Carp::CarpLevel = 1;
	# carp($msg);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Job::Machine::Base

=head1 VERSION

version 0.26

=head1 NAME

Job::Machine::Base - Base class both for Client and Worker Classes

=head1 METHODS

=head2 new

	my $client = Job::Machine::Base->new(
		dbh   => $dbh,
		queue => 'queue',
	);

	my $client = Job::Machine::Base->new(
		dsn      => $dsn,
		user     => $user,
		password => $password,
		db_attr  => $db_attributes
		...
	);

=head3 Worker:

	my $worker = Job::Machine::Base->new(
		queue => [qw/q1 q2/],
		...
	);

=head3 Arguments:

Either provide an already warm database handle, or give a new array to tell how
to open a database.

	Client: queue is the channel to the worker.
	Worker: queue is what the worker is listening to. Can be a scalar or arrayref. 
	timeout is how long to wait for notifications before doing a housekeeping loop.
	Default is 5 minutes.

=head2 job_log

Give it a text and it will log it.

=head2 db

Returns the database handle.

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
