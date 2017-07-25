package Net::CLI::Interact::ActionSet;
{
  $Net::CLI::Interact::ActionSet::VERSION = '2.143070';
}

use Moo;
use Sub::Quote;
use MooX::Types::MooseLike::Base qw(InstanceOf ArrayRef CodeRef RegexpRef);
use Net::CLI::Interact::Action;

with 'Net::CLI::Interact::Role::Iterator';

has default_continuation => (
    is => 'rw',
    isa => InstanceOf['Net::CLI::Interact::ActionSet'],
    predicate => 1,
);

has current_match => (
    is => 'rw',
    isa => ArrayRef[RegexpRef],
    predicate => 1,
    coerce => quote_sub(q{ (ref qr// eq ref $_[0]) ? [$_[0]] : $_[0] }),
);

sub BUILDARGS {
    my ($class, @rest) = @_;

    # accept single hash ref or naked hash
    my $params = (ref {} eq ref $rest[0] ? $rest[0] : {@rest});

    if (exists $params->{actions} and ref $params->{actions} eq ref []) {
        foreach my $a (@{$params->{actions}}) {
            if (ref $a eq 'Net::CLI::Interact::ActionSet') {
                push @{$params->{_sequence}}, @{ $a->_sequence };
                next;
            }

            if (ref $a eq 'Net::CLI::Interact::Action') {
                push @{$params->{_sequence}}, $a;
                next;
            }

            if (ref $a eq ref {}) {
                push @{$params->{_sequence}},
                    Net::CLI::Interact::Action->new($a);
                next;
            }

            die "don't know what to do with a: '$a'\n";
        }
        delete $params->{actions};
    }

    return $params;
}

sub clone {
    my $self = shift;
    return Net::CLI::Interact::ActionSet->new({
        actions => [ map { $_->clone } @{ $self->_sequence } ],
        ($self->_has_callbacks ? (_callbacks => $self->_callbacks) : ()),
        ($self->has_default_continuation ? (default_continuation => $self->default_continuation) : ()),
        ($self->has_current_match ? (current_match => $self->current_match) : ()),
    });
}

# store params to the set, used when send is passed via sprintf
sub apply_params {
    my ($self, @params) = @_;

    $self->reset;
    while ($self->has_next) {
        my $next = $self->next;
        $next->params([splice @params, 0, $next->num_params]);
    }
}

has _callbacks => (
    is => 'rw',
    isa => ArrayRef[CodeRef],
    default => sub { [] },
    predicate => 1,
);

sub register_callback {
    my $self = shift;
    $self->_callbacks([ @{$self->_callbacks}, shift ]);
}

sub execute {
    my $self = shift;

    $self->_pad_send_with_match;
    $self->_forward_continuation_to_match;
    $self->_do_exec;
    $self->_marshall_responses;
}

sub _do_exec {
    my $self = shift;

    $self->reset;
    while ($self->has_next) {
        $_->($self->next) for @{$self->_callbacks};
    }
}

# pad out the Actions with match Actions if needed between send pairs.
sub _pad_send_with_match {
    my $self = shift;
    my $match = Net::CLI::Interact::Action->new({
        type => 'match', value => $self->current_match,
    });

    $self->reset;
    while ($self->has_next) {
        my $this = $self->next;
        my $next = $self->peek or last; # careful...
        next unless $this->type eq 'send' and $next->type eq 'send';

        $self->insert_at($self->idx + 1, $match->clone);
    }

    # always finish on a match
    if ($self->last->type ne 'match') {
        $self->insert_at($self->count, $match->clone);
    }
}

# carry-forward a continuation beacause it's the match which really does the
# heavy lifting.
sub _forward_continuation_to_match {
    my $self = shift;

    $self->reset;
    while ($self->has_next) {
        my $this = $self->next;
        my $next = $self->peek or last; # careful...
        my $cont = ($this->continuation || $self->default_continuation);
        next unless $this->type eq 'send'
            and $next->type eq 'match'
            and defined $cont;

        $next->continuation($cont);
    }
}

# marshall the responses so as to move data from match to send
sub _marshall_responses {
    my $self = shift;

    $self->reset;
    while ($self->has_next) {
        my $send = $self->next;
        my $match = $self->peek or last; # careful...
        next unless $match->type eq 'match';

        # remove echoed command from the beginning
        my $cmd = quotemeta( sprintf $send->value, @{ $send->params } );
        (my $output = $match->response_stash) =~ s/^${cmd}[\t ]*(?:\r\n|\r|\n)?//s;
        $send->response($output);
    }
}

1;

# ABSTRACT: Conversation of Send and Match Actions


__END__
=pod

=head1 NAME

Net::CLI::Interact::ActionSet - Conversation of Send and Match Actions

=head1 VERSION

version 2.143070

=head1 DESCRIPTION

This class is used internally by L<Net::CLI::Interact> and it's unlikely that
an end-user will need to make use of ActionSet objects directly. The interface
is documented here as a matter of record.

An ActionSet comprises a sequence (usefully, two or more) of
L<Actions|Net::CLI::Interact::Action> which describe a conversation with a
connected network device. Actions will alternate between type C<send> and
C<match>, perhaps not in their original
L<Phrasebook|Net::CLI::Interact::Phrasebook> definition, but certainly by the
time they are used.

If the first Action is of type C<send> then the ActionSet is a normal sequence
of "send a command" then "match a response", perhaps repeated. If the first
Action is of type C<match> then the ActionSet represents a C<continuation>,
which is the method of dealing with paged output.

=head1 INTERFACE

=head2 default_continuation

An ActionSet (C<match> then C<send>) which will be available for use on all
commands sent from this ActionSet. An alternative to explicitly describing the
Continuation sequence within the Phrasebook.

=head2 current_match

A stash for the current Prompt (regular expression reference) which
L<Net::CLI::Interact> expects to see after each command. This is passed into
the constructor and is used when padding Match Actions into the ActionSet (see
C<execute>, below).

=head2 clone

Returns a new ActionSet which is a shallow clone of the existing one. All the
reference based slots will share data, but you can add (for example) a
C<current_match> without affecting the original ActionSet. Used when preparing
to execute an ActionSet which has been retrieved from the
L<Phrasebook|Net::CLI::Interact::Phrasebook>.

=head2 apply_params

Accepts a list of parameters which will be used when C<sprintf> is called on
each Send Action in the set. You must supply sufficient parameters as a list
for I<all> Send Actions in the set, and they will be popped off and stashed
with the Action(s) according to how many are required.

=head2 register_callback

Allows the L<Transport|Net::CLI::Interact::Transport> to be registered
such that when the ActionSet is executed, commands are sent to the registered
callback subroutine. May be called more than once, and on execution each of
the callbacks will be run, in turn and in order.

=head2 execute

The business end of this class, where the sequence of Actions is prepared for
execution and then control passed to the Transport. This process is split into
a number of phases:

=over 4

=item Pad C<send> with C<match>

The Phrasebook allows missing out of the Match statements between Send
statements, when they are expected to be the same as the C<current_match>.
This phase inserts Match statements to restore a complete ActionSet
definition.

=item Forward C<continuation> to C<match>

In the Phrasebook a user defines a Continuation (C<match>, then C<send>)
following a Send statement (because it deals with the response to the sent
command). However they are actually used by the Match, as it's the Match which
captures output.

This phase copies Continuation ActionSets from Send statements to following
Match statements in the ActionSet. It also performs a similar action using the
C<default_continuation> if one is set and there's no existing Continuation
configured.

=item Callback(s)

Here the registered callbacks are executed (i.e. data is sent to the
Transport).

=item Marshall Responses

Finally, responses which are stashed in the Match Actions are copied back to
the Send actions, as more logically they are responses to commands sent. The
ActionSet is now ready for access to retrieve the C<last_response> from the
device.

=back

=head1 COMPOSITION

See the following for further interface details:

=over 4

=item *

L<Net::CLI::Interact::Role::Iterator>

=back

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Oliver Gorwits.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

