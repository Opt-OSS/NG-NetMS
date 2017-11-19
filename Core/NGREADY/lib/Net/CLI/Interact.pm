package Net::CLI::Interact;
{
  $Net::CLI::Interact::VERSION = '2.200009';
}

use Moo;
use Sub::Quote;
use Class::Load ();
use MooX::Types::MooseLike::Base qw(InstanceOf Maybe Str HashRef);

with 'Net::CLI::Interact::Role::Engine';

has 'my_args' => (
    is => 'rwp',
    isa => HashRef,
);

# stash all args in my_args
sub BUILDARGS {
    my ($class, @args) = @_;

    # accept single hash ref or naked hash
    my $params = (ref {} eq ref $args[0] ? $args[0] : {@args});

    return { my_args => $params };
}

sub default_log_categories {
    return (qw/dialogue dump engine object phrasebook prompt transport/);
}

has 'log_at' => (
    is => 'rw',
    isa => Maybe[Str],
    default => quote_sub(q[ $ENV{'NCI_LOG_AT'} ]),
    trigger => \&set_global_log_at,
);

sub set_global_log_at {
    my ($self, $level) = @_;
    return unless defined $level and length $level;
    $self->logger->log_flags({
        map {$_ => $level} default_log_categories()
    });
}

sub BUILD {
    my $self = shift;
    $self->set_global_log_at($self->log_at);
    $self->logger->log('engine', 'notice',
        sprintf "NCI loaded, version %s", ($Net::CLI::Interact::VERSION || 'devel'));
}

has 'logger' => (
    is => 'lazy',
    isa => InstanceOf['Net::CLI::Interact::Logger'],
    predicate => 1,
    clearer => 1,
);

sub _build_logger {
    my $self = shift;
    use Net::CLI::Interact::Logger;
    return Net::CLI::Interact::Logger->new($self->my_args);
}

has 'phrasebook' => (
    is => 'lazy',
    isa => InstanceOf['Net::CLI::Interact::Phrasebook'],
    predicate => 1,
    clearer => 1,
);

sub _build_phrasebook {
    my $self = shift;
    use Net::CLI::Interact::Phrasebook;
    return Net::CLI::Interact::Phrasebook->new({
        %{ $self->my_args },
        logger => $self->logger,
    });
}

# does not really *change* the phrasebook, just reconfig and nuke
sub set_phrasebook {
    my ($self, $args) = @_;
    return unless defined $args and ref {} eq ref $args;
    $self->my_args->{$_} = $args->{$_} for keys %$args;
    $self->clear_phrasebook;
}

has 'transport' => (
    is => 'lazy',
    isa => quote_sub(q{ $_[0]->isa('Net::CLI::Interact::Transport') }),
    predicate => 1,
    clearer => 1,
);

sub _build_transport {
    my $self = shift;
    die 'missing transport' unless exists $self->my_args->{transport};
    my $tpt = 'Net::CLI::Interact::Transport::'. $self->my_args->{transport};
    Class::Load::load_class($tpt);
    return $tpt->new({
        %{ $self->my_args },
        logger => $self->logger,
    });
}

1;

# ABSTRACT: Toolkit for CLI Automation


__END__
=pod

=head1 NAME

Net::CLI::Interact - Toolkit for CLI Automation

=head1 PURPOSE

This module exists to support developers of applications and libraries which
must interact with a command line interface.

=head1 SYNOPSIS

 use Net::CLI::Interact;
 
 my $s = Net::CLI::Interact->new({
    personality => 'cisco',
    transport   => 'Telnet',
    connect_options => { host => '192.0.2.1' },
 });
 
 # respond to a usename/password prompt
 $s->macro('to_user_exec', {
     params => ['my_username', 'my_password'],
 });
 
 my $interfaces = $s->cmd('show ip interfaces brief');
 
 $s->macro('to_priv_exec', {
     params => ['my_password'],
 });
 # matched prompt is updated automatically
 
 # paged output is slurped into one response
 $s->macro('show_run');
 my $config = $s->last_response;

=head1 DESCRIPTION

Automating command line interface (CLI) interactions is not a new idea, but
can be tricky to implement. This module aims to provide a simple and
manageable interface to CLI interactions, supporting:

=over 4

=item *

SSH, Telnet and Serial-Line connections

=item *

Unix and Windows support

=item *

Reuseable device command phrasebooks

=back

If you're a new user, please read the
L<Tutorial|Net::CLI::Interact::Manual::Tutorial>. There's also a
L<Cookbook|Net::CLI::Interact::Manual::Cookbook> and a L<Phrasebook
Listing|Net::CLI::Interact::Manual::Phrasebook>. For a more complete worked
example check out the L<Net::Appliance::Session> distribution, for which this
module was written.

=head1 INTERFACE

=head2 new( \%options )

Prepares a new session for you, but will not connect to any device. On
Windows platforms, you B<must> download the C<plink.exe> program, and pass
its location to the C<app> parameter. Other options are:

=over 4

=item C<< personality => $name >> (required)

The family of device command phrasebooks to load. There is a built-in library
within this module, or you can provide a search path to other libraries. See
L<Net::CLI::Interact::Manual::Phrasebook> for further details.

=item C<< transport => $backend >> (required)

The name of the transport backend used for the session, which may be one of
L<Telnet|Net::CLI::Interact::Transport::Telnet>,
L<SSH|Net::CLI::Interact::Transport::SSH>, or
L<Serial|Net::CLI::Interact::Transport::Serial>.

=item C<< connect_options => \%options >>

If the transport backend can take any options (for example the target
hostname), then pass those options in this value as a hash ref. See the
respective manual pages for each transport backend for further details.

=item C<< log_at => $log_level >>

To make using the C<logger> somewhat easier, you can pass this argument the
name of a log I<level> (such as C<debug>, C<info>, etc) and all logging in the
library will be enabled at that level. Use C<debug> to learn about how the
library is working internally. See L<Net::CLI::Interact::Logger> for a list of
the valid level names.

=item C<< timeout => $seconds >>

Configures a default timeout value, in seconds, for interaction with the
remote device. The default is 10 seconds. You can also set timeout on a
per-command or per-macro call (see below).

Note that this does not (currently) apply to the initial connection.

=back

=head2 cmd( $command )

Execute a single command statement on the connected device, and consume output
until there is a match with the current I<prompt>. The statement is executed
verbatim on the device, with a newline appended.

In scalar context the C<last_response> is returned (see below). In list
context the gathered response is returned as a list of lines. In both cases
your local platform's newline character will end all lines.

=head2 macro( $name, \%options? )

Execute the commands contained within the named Macro, which must be loaded
from a Phrasebook. Options to control the output, including variables for
substitution into the Macro, are passed in the C<%options> hash reference.

In scalar context the C<last_response> is returned (see below). In list
context the gathered response is returned as a list of lines. In both cases
your local platform's newline character will end all lines.

=head2 last_response

Returns the gathered output after the most recent C<cmd> or C<macro>. In
scalar context all data is returned. In list context the gathered response is
returned as a list of lines. In both cases your local platform's newline
character will end all lines.

=head2 transport

Returns the L<Transport|Net::CLI::Interact::Transport> backend which was
loaded based on the C<transport> option to C<new>. See the
L<Telnet|Net::CLI::Interact::Transport::Telnet>,
L<SSH|Net::CLI::Interact::Transport::SSH>, or
L<Serial|Net::CLI::Interact::Transport::Serial> documentation for further
details.

=head2 phrasebook

Returns the Phrasebook object which was loaded based on the C<personality>
option given to C<new>. See L<Net::CLI::Interact::Phrasebook> for further
details.

=head2 set_phrasebook( \%options )

Allows you to (re-)configure the loaded phrasebook, perhaps changing the
personality or library, or other properties. The C<%options> Hash ref should
be any parameters from the L<Phrasebook|Net::CLI::Interact::Phrasebook>
module, but at a minimum must include a C<personality>.

=head2 set_default_contination( $macro_name )

Briefly, a Continuation handles the slurping of paged output from commands.
See the L<Net::CLI::Interact::Phrasebook> documentation for further details.

Pass in the name of a defined Contination (Macro) to enable paging handling as
a default for all sent commands. This is an alternative to describing the
Continuation format in each Macro.

To unset the default Continuation, call the C<clear_default_continuation>
method.

=head2 logger

This is the application's L<Logger|Net::CLI::Interact::Logger> object. A
powerful logging subsystem is available to your application, built upon the
L<Log::Dispatch> distribution. You can enable logging of this module's
processes at various levels, or add your own logging statements.

=head2 set_global_log_at( $level )

To make using the C<logger> somewhat easier, you can pass this method the
name of a log I<level> (such as C<debug>, C<info>, etc) and all logging in the
library will be enabled at that level. Use C<debug> to learn about how the
library is working internally. See L<Net::CLI::Interact::Logger> for a list of
the valid level names.

=head1 FUTHER READING

=head2 Prompt Matching

Whenever a command statement is issued, output is slurped until a matching
prompt is seen in that output. Control of the Prompts is shared between the
definitions in L<Net::CLI::Interact::Phrasebook> dictionaries, and methods of
the L<Net::CLI::Interact::Role::Prompt> core component. See that module's
documentation for further details.

=head2 Actions and ActionSets

All commands and macros are composed from their phrasebook definitions into
L<Actions|Net::CLI::Interact::Action> and
L<ActionSets|Net::CLI::Interact::ActionSet> (iterable sequences of Actions).
See those modules' documentation for further details, in case you wish to
introspect their structures.

=head1 COMPOSITION

See the following for further interface details:

=over 4

=item *

L<Net::CLI::Interact::Role::Engine>

=back

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Oliver Gorwits.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

