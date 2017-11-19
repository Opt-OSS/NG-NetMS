package Net::CLI::Interact::Role::Prompt;
{
  $Net::CLI::Interact::Role::Prompt::VERSION = '2.143070';
}

use Moo::Role;
use MooX::Types::MooseLike::Base qw(Str RegexpRef);
use Net::CLI::Interact::ActionSet;

with 'Net::CLI::Interact::Role::FindMatch';

has 'wake_up_msg' => (
    is => 'rw',
    isa => Str,
    default => sub { (shift)->transport->ors },
    predicate => 1,
);

has '_prompt' => (
    is => 'rw',
    isa => RegexpRef,
    reader => 'prompt_re',
    predicate => 'has_set_prompt',
    clearer => 'unset_prompt',
    trigger => sub {
        (shift)->logger->log('prompt', 'info', 'prompt has been set to', (shift));
    },
);

sub set_prompt {
    my ($self, $name) = @_;
    $self->_prompt( $self->phrasebook->prompt($name)->first->value->[0] );
}

sub last_prompt {
    my $self = shift;
    return $self->last_actionset->item_at(-1)->response;
}

sub last_prompt_re {
    my $self = shift;
    my $prompt = $self->last_prompt;
    return qr/^\Q$prompt\E$/;
}

sub prompt_looks_like {
    my ($self, $name) = @_;
    return $self->find_match(
        $self->last_prompt, $self->phrasebook->prompt($name)->first->value
    );
}

# create an ActionSet of one send and one match Action, for the wake_up
sub _fabricate_actionset {
    my $self = shift;

    my $output = $self->transport->flush;
    my $irs_re = $self->transport->irs_re;

    $output =~ s/^(?:$irs_re)+//;
    my @output_lines = split $irs_re, $output;
    my $last_output_line = pop @output_lines;
    my $current_match = [$self->prompt_re];

    my $set = Net::CLI::Interact::ActionSet->new({
        current_match => $current_match,
        actions => [
            {
                type => 'send',
                value => ($self->has_wake_up_msg ? $self->wake_up_msg : ''),
                response => (join "\n", @output_lines, ''),
            },
            {
                type => 'match',
                response => $last_output_line,
                value => $current_match,
                prompt_hit => $current_match->[0],
            },
        ],
    });

    return $set;
}

# pump until any of the prompts matches the output buffer
sub find_prompt {
    my ($self, $wake_up) = @_;
    $self->logger->log('prompt', 'notice', 'finding prompt');

    # make connection on transport if not yet done
    $self->transport->init if not $self->transport->connect_ready;

    eval {
        my $started_pumping = time;
        PUMPING: while (1) {
            $self->transport->pump;
            $self->logger->log('dump', 'debug', "SEEN:\n". $self->transport->buffer);
            foreach my $prompt ($self->phrasebook->prompt_names) {
                # prompts consist of only one match action
                if ($self->find_match(
                        $self->transport->buffer,
                        $self->phrasebook->prompt($prompt)->first->value)) {
                    $self->logger->log('prompt', 'info', "hit, matches prompt $prompt");
                    $self->set_prompt($prompt);
                    $self->last_actionset( $self->_fabricate_actionset() );
                    $self->logger->log('dialogue', 'info',
                        "trimmed command response:\n". $self->last_response);
                    last PUMPING;
                }
                $self->logger->log('prompt', 'debug', "nope, doesn't (yet) match $prompt");
            }
            $self->logger->log('prompt', 'debug', 'no match so far, more data?');
            last if $self->transport->timeout
                    and time > ($started_pumping + $self->transport->timeout);
        }
    };

    if ($@ and $self->has_wake_up_msg and $wake_up) {
        $self->logger->log('prompt', 'notice',
            "failed: [$@], sending WAKE_UP and trying again");

        eval {
            $self->transport->put( $self->wake_up_msg );
            $self->find_prompt(--$wake_up);
        };
        if ($@) {
            # really died, so this time bail out - with possible transport err
            my $output = $self->transport->flush;
            $self->transport->disconnect;
            die $output;
        }
    }
    else {
        if (not $self->has_set_prompt) {
            # trouble... we were asked to find a prompt but failed :-(
            $self->logger->log('prompt', 'critical', 'failed to find prompt! wrong phrasebook?');

            # bail out with what we have...
            my $output = $self->transport->flush;
            $self->transport->disconnect;
            die $output;
        }
    }
}

1;

# ABSTRACT: Command-line prompt management


__END__
=pod

=head1 NAME

Net::CLI::Interact::Role::Prompt - Command-line prompt management

=head1 VERSION

version 2.143070

=head1 DESCRIPTION

This is another core component of L<Net::CLI::Interact>, and its role is to
keep track of the current prompt on the connected command line interface. The
idea is that most CLI have a prompt where you issue commands, and are returned
some output which this module gathers. The prompt is a demarcation between
each command and its response data.

Note that although we "keep track" of the prompt, Net::CLI::Interact is not a
state machine, and the choice of command issued to the connected device bears
no relation to the current (or last matched) prompt.

=head1 INTERFACE

=head2 set_prompt( $prompt_name )

This method will be used most commonly by applications to select and set a
prompt from the Phrasebook which matches the current context of the connected
CLI session. This allows a sequence of commands to be sent which share the
same Prompt.

The name you pass in is looked up in the loaded Phrasebook and the entry's
regular expression stored internally. An exception is thrown if the named
Prompt is not known.

Typically you would either refer to a Prompt in a Macro, or set the prompt you
are expecting once for a sequence of commands in a particular CLI context.

When a Macro completes and it has been defined in the Phrasebook with an
explicit named Prompt at the end, we can assume the user is indicating some
change of context. Therefore the C<prompt> is I<automatically updated> on such
occasions to have the regular expression from that named Prompt.

=head2 prompt_re

Returns the current Prompt in the form of a regular expression reference. The
Prompt is used as a default to catch the end of command response output, when
a Macro has not been set up with explicit Prompt matching.

Typically you would either refer to a Prompt in a Macro, or set the prompt you
are expecting once for a sequence of commands in a particular CLI context.

=head2 unset_prompt

Use this method to empty the current C<prompt> setting (see above). The effect
is that the module will automatically set the Prompt for itself based on the
last line of output received from the connected CLI. Do not use this option
unless you know what you are doing.

=head2 has_set_prompt

Returns True if there is currently a Prompt set, otherwise returns False.

=head2 prompt_looks_like( $name )

Returns True if the current prompt matches the given named prompt. This is
useful when you wish to make a more specific check on the current prompt.

=head2 find_prompt( $wake_up? )

A helper method that consumes output from the connected CLI session until a
line matches any one of the named Prompts in the loaded Phrasebook, at which
point no more output is consumed. As a consequence the C<prompt> will be set
(see above).

This might be used when you're connecting to a device which maintains CLI
state between session disconnects (for example a serial console), and you need
to discover the current state. However, C<find_prompt> is executed
automatically for you if you call a C<cmd> or C<macro> before any interaction
with the CLI.

The current device output will be scanned against all known named Prompts. If
nothing is found, the default behaviour is to die. Passing a positive number
to the method (as C<$wake_up>) will instead send the content of our
C<wake_up_msg> slot (see below), typically a carriage return, and try to match
again. The idea is that by sending one carriage return, the connected device
will print its CLI prompt. This "send and try to match" process will be
repeated up to "C<$wake_up>" times.

=head2 wake_up_msg

Text sent to a device within the C<find_prompt> method if no output has so far
matched any known named Prompt. Default is the value of the I<output record
separator> from the L<Transport|Net::CLI::Interact::Transport> (one newline).

=head2 last_prompt

Returns the Prompt which most recently was matched and terminated gathering of
output from the connected CLI. This is a simple text string.

=head2 last_prompt_re

Returns the text which was most recently matched and terminated gathering of
output from the connected CLI, as a quote-escaped regular expression with line
start and end anchors.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Oliver Gorwits.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

