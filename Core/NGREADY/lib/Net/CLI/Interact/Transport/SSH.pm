package Net::CLI::Interact::Transport::SSH;
{
  $Net::CLI::Interact::Transport::SSH::VERSION = '2.143070';
}

use Moo;
use Sub::Quote;
use MooX::Types::MooseLike::Base qw(InstanceOf);

extends 'Net::CLI::Interact::Transport::Base';

{
    package # hide from pause
        Net::CLI::Interact::Transport::SSH::Options;

    use Moo;
    use Sub::Quote;
    use MooX::Types::MooseLike::Base qw(Str Bool ArrayRef Any);

    extends 'Net::CLI::Interact::Transport::Options';

    has 'host' => (
        is => 'rw',
        isa => Str,
        required => 1,
    );

    has 'username' => (
        is => 'rw',
        isa => Str,
        predicate => 1,
    );

    has 'shkc' => (
        is => 'rw',
        isa => Bool,
        default => quote_sub('0'),
    );

    has 'ignore_host_checks' => (
        is => 'rw',
        isa => Bool,
        default => quote_sub('1'),
    );

    has 'opts' => (
        is => 'rw',
        isa => ArrayRef[Any],
        default => sub { [] },
    );
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

has 'connect_options' => (
    is => 'ro',
    isa => InstanceOf['Net::CLI::Interact::Transport::SSH::Options'],
    coerce => quote_sub(q{ (ref '' eq ref $_[0]) ? $_[0] :
        Net::CLI::Interact::Transport::SSH::Options->new(@_) }),
    required => 1,
);

sub _build_app {
    my $self = shift;
    die "please pass location of plink.exe in 'app' parameter to new()\n"
        if $self->is_win32;
    return 'ssh';
}

sub runtime_options {
    my $self = shift;
    if ($self->is_win32) {
        return (
            '-ssh',
            @{$self->connect_options->opts},
            ($self->connect_options->has_username
                ? ($self->connect_options->username . '@') : '')
                . $self->connect_options->host,
        );
    }
    else {
        return (
            (($self->connect_options->ignore_host_checks and not $self->connect_options->shkc)
                ? (
                    '-o', 'StrictHostKeyChecking=no',
                    '-o', 'UserKnownHostsFile=/dev/null',
                    '-o', 'CheckHostIP=no',
                ) : ()),
            @{$self->connect_options->opts},
            ($self->connect_options->has_username
                ? ('-l', $self->connect_options->username) : ()),
            $self->connect_options->host,
        );
    }
}

1;

# ABSTRACT: SSH based CLI connection


__END__
=pod

=head1 NAME

Net::CLI::Interact::Transport::SSH - SSH based CLI connection

=head1 VERSION

version 2.143070

=head1 DESCRIPTION

This module provides a wrapped instance of an SSH client for use by
L<Net::CLI::Interact>.

=head1 INTERFACE

=head2 app

On Windows platforms you B<must> download the C<plink.exe> program, and pass its
location to the library in this parameter. On other platforms, this defaults to
C<ssh> (openssh).

=head2 runtime_options

Based on the C<connect_options> hash provided to Net::CLI::Interact on
construction, selects and formats parameters to provide to C<app> on the
command line. Supported attributes:

=over 4

=item host (required)

Host name or IP address of the host to which the SSH application is to
connect. Alternatively you can pass a value of the form C<user@host>, but it's
probably better to use the separate C<username> parameter instead.

=item username

Optionally pass in the username for the SSH connection, otherwise the SSH
client defaults to the current user's username. When using this option, you
should obviously I<only> pass the host name to C<host>.

=item ignore_host_checks

Under normal interactive use C<openssh> tracks the identity of connected hosts
and verifies these identities upon each connection. In automation this behaviour
can be irritating because it is interactive.

This option, enabled by default, causes C<openssh> to skip or ignore this host
identity verification. This means the default setting is less secure, but also
less likely to trip you up. It is equivalent to the following:

 StrictHostKeyChecking=no
 UserKnownHostsFile=/dev/null
 CheckHostIP=no

Pass a false value to this option to disable the above and return C<openssh> to
its default configured settings.

=item opts

If you want to pass any other options to openssh on its command line, then use
this option, which should be an array reference. Each item in the list will be
passed to C<openssh>, separated by a single space character. For example:

 $s->new({
     # ...other parameters to new()...
     connect_options => {
         opts => [
             '-p', '222',            # connect to non-standard port on remote host
             '-o', 'CheckHostIP=no', # don't check host IP in known_hosts file
         ],
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

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Oliver Gorwits.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

