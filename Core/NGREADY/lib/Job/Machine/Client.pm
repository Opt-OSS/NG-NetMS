package Job::Machine::Client;
$Job::Machine::Client::VERSION = '0.26';
use strict;
use warnings;

use base 'Job::Machine::Base';

sub send {
	my ($self, $data, $queue) = @_;
	$queue ||= $self->{queue};
	my $id = $self->db->insert_task($data,$queue);
	$self->db->notify(queue => $queue);
	return $id;
}

sub check {
	my ($self, $id) = @_;
	$id ||= $self->id;
	$self->{subscribed} ||= $self->subscribe($id,1); # Subscribe if not already subscribed
	return $self->db->get_notification;
}

sub uncheck {
	my ($self, $id) = @_;
	$id ||= $self->id;
	delete $self->{subscribed};
	$self->db->unlisten(queue => $id, reply => 1);
	return 1;
}

sub receive {
	my ($self, $id) = @_;
	$id ||= $self->id;
	return $self->db->fetch_first_result($id);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Job::Machine::Client

=head1 VERSION

version 0.26

=head1 SYNOPSIS

  my $client = Job::Machine::Client->new(dbh => $dbh, queue => 'job.task');
  my $id = $client->send({foo => 'bar'});

=head1 NAME

Job::Machine::Client - Class for Job Clients

=head1 METHODS

=head2 send

 Send a message to the configured queue

  Parameters
  data - data to pass to the worker process
  queue - optional queue name. Not needed if already set in new

 Returns the message id.

=head2 check

 Check for reply. 
 
 Parameter: The message id.

 Will listen for any answers from the worker(s) and return true if there is one.

=head2 uncheck

 Stop check for reply. 
 
 Parameter: The message id.

 Will stop listening for any answers.

=head2 receive

 Receive the reply.

 Parameter: The message id.

 Will get the latest reply to a message or null if no reply.

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
