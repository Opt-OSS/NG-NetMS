package Net::CLI::Interact::Action;
{
  $Net::CLI::Interact::Action::VERSION = '2.143070';
}

use Moo;
use Sub::Quote;
use MooX::Types::MooseLike::Base qw(Any Bool Str ArrayRef InstanceOf RegexpRef);
use Net::CLI::Interact::ActionSet;

has 'type' => (
    is => 'ro',
    isa => quote_sub(
        q{ die "$_[0] not send/match" unless $_[0] =~ m/^(?:send|match)$/ }),
    required => 1,
);

has 'value' => (
    is => 'ro',
    isa => Any, # FIXME 'Str|ArrayRef[RegexpRef]',
    required => 1,
);

has 'no_ors' => (
    is => 'ro',
    isa => Bool,
    default => quote_sub('0'),
);

has 'continuation' => (
    is => 'rw',
    isa => InstanceOf['Net::CLI::Interact::ActionSet'],
);

has 'params' => (
    is => 'rw',
    isa => ArrayRef,
    default => sub { [] },
);

has 'response' => (
    is => 'rw',
    isa => Str,
    default => quote_sub(q{''}),
);

has 'response_stash' => (
    is => 'rw',
    isa => Str,
    default => quote_sub(q{''}),
);

has 'prompt_hit' => (
    is => 'rw',
    isa => RegexpRef,
);

sub BUILDARGS {
    my ($class, @rest) = @_;

    # accept single hash ref or naked hash
    my $params = (ref {} eq ref $rest[0] ? $rest[0] : {@rest});

    if (exists $params->{continuation} and ref [] eq ref $params->{continuation}) {
        $params->{continuation} = Net::CLI::Interact::ActionSet->new({
            actions => $params->{continuation},
        });
    }

    return $params;
}

# Only a shallow copy so all the reference based slots still
# share data with the original Action's slots.
# 
# I asked in #web-simple and was told that if the object is more magical than
# a simple hashref, then someone is trying to be far too clever. agreed!
sub clone {
    my $self = shift;
    bless({ %{$self}, %{(shift) || {}} }, ref $self)
}

# count the number of sprintf parameters used in the value
sub num_params {
    my $self = shift;
    return 0 if ref $self->value;
    # this tricksy little number comes from the Perl FAQ
    my $count = () = $self->value =~ m/(?<!%)%/g;
    return $count;
}

1;

# ABSTRACT: Sent data or matched response from connected device


__END__
=pod

=head1 NAME

Net::CLI::Interact::Action - Sent data or matched response from connected device

=head1 VERSION

version 2.143070

=head1 DESCRIPTION

This class is used internally by L<Net::CLI::Interact> and it's unlikely that
an end-user will need to make use of Action objects directly. The interface is
documented here as a matter of record.

An Action object represents I<either> some kind of text or command to send to
a connected device, I<or> a regular expression matching the response from a
connected device. Such Actions are built up into ActionSets which describe a
conversation with the connected device.

If the Action is a C<send> type, then after execution it can be cloned and
augmented with the response text of the command. If the response is likely to
be paged, then the Action may also store instruction in how to trigger and
consume the pages.

=head1 INTERFACE

=head2 type

Denotes the kind of Action, which may be C<send> or C<match>.

=head2 value

In the case of C<send>, a String command to send to the device. In the case of
C<match>, a regular expression reference to match response from the device. In
special circumstances an array reference of regular expression references is
also valid, and each will be checked for a match against the device response.

=head2 no_ors

Only applies to the C<send> kind. Whether to skip appending the I<output
record separator> (newline) to the C<send> command when sent to the connected
device.

=head2 continuation

Only applies to the C<send> kind. When response output is likely to be paged,
this stores an L<ActionSet|Net::CLI::Interact::ActionSet> that contains two
Actions: one for the C<match> which indicates output has paused at the end of
a page, and one for the C<send> command which triggers printing of the next
page.

=head2 params

Only applies to the C<send> kind, and contains a list of parameters which are
substituted into the C<value> using Perl's C<sprintf> function. Insufficient
parameters causes C<sprintf> to die.

=head2 num_params

Only applies to the C<send> kind, and returns the number of parameters which
are required for the current C<value>. Used for error checking when setting
C<params>.

=head2 response

A stash for the returned prompt which matched and triggered the end of this
action.

=head2 response_stash

A stash for the returned output following a C<send> command, but not including
the matched prompt which ended the action. This slot is used by the C<match>
action as it slurps output, but the content is then transferred over to the
partner C<send> in the ActionSet.

=head2 prompt_hit

When a command is successfully issued, the response is terminated by a prompt.
However that prompt can be one of a list, defined in the Action. This slot
records the regular expression from that list which was actually matched.

=head2 clone

Returns a new Action, which is a shallow clone of the existing one. All the
reference based slots will share data, but you can add (for example) a
C<response> without affecting the original Action. Used when preparing to
execute an Action which has been retrieved from the
L<Phrasebook|Net::CLI::Interact::Phrasebook>.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Oliver Gorwits.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

