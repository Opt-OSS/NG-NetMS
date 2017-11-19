package Net::CLI::Interact::Role::Engine;
{
  $Net::CLI::Interact::Role::Engine::VERSION = '2.143070';
}

{
    package # hide from pause
        Net::CLI::Interact::Role::Engine::ExecuteOptions;

    use Moo;
    use Sub::Quote;
    use MooX::Types::MooseLike::Base qw(Bool ArrayRef Str Any);

    has 'no_ors' => (
        is => 'ro',
        isa => Bool,
        default => quote_sub('0'),
    );

    has 'params' => (
        is => 'ro',
        isa => ArrayRef[Str],
        predicate => 1,
    );

    has 'timeout' => (
        is => 'ro',
        isa => quote_sub(q{die "$_[0] is not a posint!" unless $_[0] > 0 }),
    );

    has 'match' => (
        is => 'rw',
        isa => ArrayRef, # FIXME ArrayRef[RegexpRef|Str]
        predicate => 1,
        coerce => quote_sub(q{ (ref [] ne ref $_[0]) ? [$_[0]] : $_[0] }),
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

use Moo::Role;
use MooX::Types::MooseLike::Base qw(InstanceOf);

with 'Net::CLI::Interact::Role::Prompt';

use Net::CLI::Interact::Action;
use Net::CLI::Interact::ActionSet;
use Class::Load ();

# try to load Data::Printer for last_actionset debug output
if (Class::Load::try_load_class('Data::Printer', {-version => '0.27'})) {
    Data::Printer->import({class => { expand => 'all' }});
}

has 'last_actionset' => (
    is => 'rw',
    isa => InstanceOf['Net::CLI::Interact::ActionSet'],
    trigger => 1,
);

sub _trigger_last_actionset {
    my ($self, $new) = @_;
    $self->logger->log('prompt', 'notice',
        sprintf ('output matching prompt was "%s"', $new->item_at(-1)->response));
    if (Class::Load::is_class_loaded('Data::Printer', {-version => '0.27'})) {
        Data::Printer::p($new, output => \my $debug);
        $self->logger->log('object', 'debug', $debug);
    }
}

sub last_response {
    my $self = shift;
    my $irs_re = $self->transport->irs_re;
    (my $resp = $self->last_actionset->item_at(-2)->response) =~ s/$irs_re/\n/g;
    $resp =~ s/\n+$//;
    return (wantarray
        ? (map {$_ .= "\n"} split m/\n/, $resp)
        : ($resp ."\n"));
}

has 'default_continuation' => (
    is => 'rw',
    isa => InstanceOf['Net::CLI::Interact::ActionSet'],
    writer => '_default_continuation',
    predicate => 1,
    clearer => 1,
);

sub set_default_continuation {
    my ($self, $cont) = @_;
    die "missing continuation" unless $cont;
    die "unknown continuation [$cont]" unless
        eval{ $self->phrasebook->macro($cont) };
    $self->_default_continuation( $self->phrasebook->macro($cont) );
    $self->logger->log('engine', 'info', 'default continuation set to', $cont);
}

sub cmd {
    my ($self, $command, $options) = @_;
    $options = Net::CLI::Interact::Role::Engine::ExecuteOptions->new($options || {});

    $self->logger->log('engine', 'notice', 'running command', $command);

    if ($options->has_match) {
        # convert prompt name(s) from name into regexpref, or die
        $options->match([
            map { ref $_ eq ref '' ? @{ $self->phrasebook->prompt($_)->first->value }
                                   : $_ }
                @{ $options->match }
        ]);

        $self->logger->log('engine', 'info', 'to match',
            (ref $options->match eq ref [] ? (join '|', @{$options->match})
                                           : $options->match));
    }

    # command will be run through sprintf but without any params
    # so convert any embedded % to literal %
    ($command =~ s/%/%%/g) &&
        $self->logger->log('engine', 'debug', 'command expanded to:', $command);

    return $self->_execute_actions(
        $options,
        Net::CLI::Interact::Action->new({
            type => 'send',
            value => $command,
            no_ors => $options->no_ors,
        }),
    );
}

sub macro {
    my ($self, $name, $options) = @_;
    $options = Net::CLI::Interact::Role::Engine::ExecuteOptions->new($options || {});

    $self->logger->log('engine', 'notice', 'running macro', $name);
    $self->logger->log('engine', 'info', 'macro params are:',
        join ', ', @{ $options->params }) if $options->has_params;

    my $set = $self->phrasebook->macro($name)->clone;
    $set->apply_params(@{ $options->params }) if $options->has_params;

    return $self->_execute_actions($options, $set);
}

sub _execute_actions {
    my ($self, $options, @actions) = @_;

    $self->logger->log('engine', 'notice', 'executing actions');

    # make connection on transport if not yet done
    $self->transport->init if not $self->transport->connect_ready;

    # user can install a prompt, call find_prompt, or let us trigger that
    $self->find_prompt(1) if not ($self->prompt_re || $self->last_actionset);

    my $set = Net::CLI::Interact::ActionSet->new({
        actions => [@actions],
        current_match => ($options->match || $self->prompt_re || $self->last_prompt_re),
        ($self->has_default_continuation ? (default_continuation => $self->default_continuation) : ()),
    });
    $set->register_callback(sub { $self->transport->do_action(@_) });

    $self->logger->log('engine', 'debug', 'dispatching to execute method');
    my $timeout_bak = $self->transport->timeout;

    $self->transport->timeout($options->timeout || $timeout_bak);
    $set->execute;
    $self->transport->timeout($timeout_bak);
    $self->last_actionset($set);

    $self->logger->log('prompt', 'debug',
        sprintf 'setting new prompt to %s',
            $self->last_actionset->last->prompt_hit || '<none>');
    $self->_prompt( $self->last_actionset->last->prompt_hit );

    $self->logger->log('dialogue', 'info',
        "trimmed command response:\n". $self->last_response);
    return $self->last_response; # context sensitive
}

1;

# ABSTRACT: Statement execution engine


__END__
=pod

=head1 NAME

Net::CLI::Interact::Role::Engine - Statement execution engine

=head1 VERSION

version 2.143070

=head1 DESCRIPTION

This module is the core of L<Net::CLI::Interact>, and serves to take entries
from your loaded L<Phrasebooks|Net::CLI::Interact::Phrasebook>, issue them to
connected devices, and gather the returned output.

=head1 INTERFACE

=head2 cmd( $command_statement, \%options? )

Execute a single command statement on the connected device, and consume output
until there is a match with the current I<prompt>. The statement is executed
verbatim on the device, with a newline appended.

The following options are supported:

=over 4

=item C<< timeout => $seconds >> (optional)

Sets a value of C<timeout> for the
L<Transport|Net::CLI::Interact::Transport> local to this call of C<cmd>, that
overrides whatever is set in the Transport, or the default of 10 seconds.

=item C<< no_ors => 1 >> (optional)

When passed a true value, a newline character (in fact the value of C<ors>)
will not be appended to the statement sent to the device.

=item C<< match => $name | $regexpref | \@names_and_regexprefs >> (optional)

Allows this command (only) to complete with a custom match, which must be one
or more of either the name of a loaded phrasebook Prompt or your own regular
expression reference (C<< qr// >>). The module updates the current prompt to
be the same value on a successful match.

=back

In scalar context the C<last_response> is returned (see below). In list
context the gathered response is returned as a list of lines. In both cases
your local platform's newline character will end all lines.

=head2 macro( $macro_name, \%options? )

Execute the commands contained within the named Macro, which must be loaded
from a Phrasebook. Options to control the output, including variables for
substitution into the Macro, are passed in the C<%options> hash reference.

The following options are supported:

=over 4

=item C<< params => \@values >> (optional)

If the Macro contains commands using C<sprintf> Format variables then the
corresponding parameters must be passed in this value as an array reference.

Values are consumed from the provided array reference and passed to the
C<send> commands in the Macro in order, as needed. An exception will be thrown
if there are insufficient parameters.

=item C<< timeout => $seconds >> (optional)

Sets a value of C<timeout> for the
L<Transport|Net::CLI::Interact::Transport> local to this call of C<macro>,
that overrides whatever is set in the Transport, or the default of 10 seconds.

=back

An exception will be thrown if the Match statements in the Macro are not
successful against the output returned from the device. This is based on the
value of C<timeout>, which controls how long the module waits for matching
output.

In scalar context the C<last_response> is returned (see below). In list
context the gathered response is returned as a list of lines. In both cases
your local platform's newline character will end all lines.

=head2 last_response

Returns the gathered output after issuing the last recent C<send> command
within the most recent C<cmd> or C<prompt>. That is, you get the output from
the last command sent to the connected device.

In scalar context all data is returned. In list context the gathered response
is returned as a list of lines. In both cases your local platform's newline
character will end all lines.

=head2 last_actionset

Returns the complete L<ActionSet|Net::CLI::Interact::ActionSet> that was
constructed from the most recent C<macro> or C<cmd> execution. This will be a
sequence of L<Actions|Net::CLI::Interact::Action> that correspond to C<send>
and C<match> statements.

In the case of a Macro these directly relate to the contents of your
Phrasebook, with the possible addition of C<match> statements added
automatically. In the case of a C<cmd> execution, an "anonymous" Macro is
constructed which consists of a single C<send> and a single C<match>.

=head1 COMPOSITION

See the following for further interface details:

=over 4

=item *

L<Net::CLI::Interact::Role::Prompt>

=back

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Oliver Gorwits.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

