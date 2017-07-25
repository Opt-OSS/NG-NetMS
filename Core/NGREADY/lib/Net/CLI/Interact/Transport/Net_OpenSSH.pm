package Net::CLI::Interact::Transport::Net_OpenSSH;
{
  $Net::CLI::Interact::Transport::Net_OpenSSH::VERSION = '0.01';
}

use Moo;
use Sub::Quote;
use MooX::Types::MooseLike::Base qw(InstanceOf ArrayRef Str);

extends 'Net::CLI::Interact::Transport::Base';

{
    package # hide from pause
        Net::CLI::Interact::Transport::Net_OpenSSH::Options;

    use Moo;
    use Sub::Quote;
    use MooX::Types::MooseLike::Base qw(InstanceOf Any Str HashRef ArrayRef);

    extends 'Net::CLI::Interact::Transport::Options';

    has 'master' => (
        is => 'rw',
        isa => InstanceOf['Net::OpenSSH'],
        required => 1,
    );

    has 'opts' => (
        is => 'rw',
        isa => HashRef[Any],
        default => sub { {} },
    );

    has 'shell_cmd' => (
        is => 'rw',
        coerce => quote_sub(q{ (ref '' eq ref $_[0]) ? [$_[0]] : $_[0] }),
        isa => ArrayRef[Str],
        default => sub { [] },
    );
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

has 'connect_options' => (
    is => 'ro',
    isa => InstanceOf['Net::CLI::Interact::Transport::Net_OpenSSH::Options'],
    coerce => quote_sub(q{ (ref '' eq ref $_[0]) ? $_[0] :
        Net::CLI::Interact::Transport::Net_OpenSSH::Options->new(@_) }),
    required => 1,
);

has app_and_runtime_options => (
    is => 'lazy',
    isa => ArrayRef[Str],
);

sub _build_app_and_runtime_options {
    my $self = shift;
    my $master = $self->connect_options->master;
    [ $master->make_remote_command($self->connect_options->opts,
                                   @{$self->connect_options->shell_cmd}) ]
}

sub app {
    shift->app_and_runtime_options->[0]
}

sub runtime_options {
    my @cmd = @{ shift->app_and_runtime_options };
    shift @cmd;
    @cmd;
}

1;

# ABSTRACT: Net_OpenSSH based CLI connection


__END__
=pod

=encoding UTF-8

=head1 NAME

Net::CLI::Interact::Transport::Net_OpenSSH - Net::OpenSSH based CLI connection

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

This module provides a wrapped instance of a L<Net::OpenSSH> SSH
client object for use by L<Net::CLI::Interact>.

This allows one to combine the capability of Net::CLI::Interact to
talk to remote servers for which Net::OpenSSH one-command-per-session
approach is not well suited (i.e. network equipment running custom
administration shells) and still use the capability of Net::OpenSSH to
run several sessions over one single SSH connection, including
accessing SCP and SFTP services.

Note that this transport is not supported on Windows as Net::OpenSSH
is not supported there either.

=head1 INTERFACE

=head2 app_and_runtime_options

Based on the C<connect_options> hash provided to Net::CLI::Interact on
construction, selects and formats the command and arguments required
to run the SSH session over the Net::OpenSSH connection.

Under the hood, this method just wraps Net::OpenSSH
C<make_remote_command> method.

Supported attributes:

=over 4

=item master

Reference to the Net::OpenSSH object wrapping the SSH master connection.

=item opts

Optional hash of extra options to be forwarded to Net::OpenSSH
C<make_remote_command> method.

=item shell_cmd

Remote command to start the shell. Can be a single string or an array reference.

The default is to pass nothing which on conforming SSH implementations
starts the shell configured for the user.

Examples:

  # interact with default user shell:
  $s->new({
     # ...other parameters to new()...
     connect_options => { master => $ssh },
  });

  # interact with csh:
  $s->new({
     # ...other parameters to new()...
     connect_options => {
         master => $ssh,
         shell_cmd => ['csh', '-i'],
     },
  });

=item reap

Only used on Unix platforms, this installs a signal handler which attempts to
reap the C<ssh> child process. Pass a true value to enable this feature only
if you notice zombie processes are being left behind after use.

=back

=head1 COMPOSITION

See the following for further interface details:

=over 4

=item *

L<Net::CLI::Interact::Transport::Base>

=back

=head1 AUTHORS

Oliver Gorwits <oliver@cpan.org>
Salvador FandiE<ntilde>o <sfandino@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Oliver Gorwits.
This software is copyright (c) 2014 by Salvador Fandiño.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

