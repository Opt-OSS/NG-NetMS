package Net::CLI::Interact::Transport::Telnet;
{
  $Net::CLI::Interact::Transport::Telnet::VERSION = '2.143070';
}

use Moo;
use Sub::Quote;
use MooX::Types::MooseLike::Base qw(InstanceOf);

extends 'Net::CLI::Interact::Transport::Base';

{
    package # hide from pause
        Net::CLI::Interact::Transport::Telnet::Options;

    use Moo;
    use Sub::Quote;
    use MooX::Types::MooseLike::Base qw(Str Int ArrayRef Any);

    extends 'Net::CLI::Interact::Transport::Options';

    has 'host' => (
        is => 'rw',
        isa => Str,
        required => 1,
    );

    has 'port' => (
        is => 'rw',
        isa => Int,
        default => quote_sub('23'),
    );

    has 'opts' => (
        is => 'rw',
        isa => ArrayRef[Any],
        default => sub { [] },
    );
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# allow native use of Net::Telnet on Unix
if (not Net::CLI::Interact::Transport::Base::is_win32()) {
    has '+use_net_telnet_connection' => ( default => quote_sub('1') );
}

has 'connect_options' => (
    is => 'ro',
    isa => InstanceOf['Net::CLI::Interact::Transport::Telnet::Options'],
    coerce => quote_sub(q{ (ref '' eq ref $_[0]) ? $_[0] :
        Net::CLI::Interact::Transport::Telnet::Options->new(@_) }),
    required => 1,
);

sub _build_app {
    my $self = shift;
    die "please pass location of plink.exe in 'app' parameter to new()\n"
        if $self->is_win32;
    return 'telnet';
}

sub runtime_options {
    my $self = shift;
    if ($self->is_win32) {
        return (
            '-telnet',
            '-P', $self->connect_options->port,
            @{$self->connect_options->opts},
            $self->connect_options->host,
        );
    }
    elsif ($self->can_use_pty) {
        return (
            Host => $self->connect_options->host,
            Port => $self->connect_options->port,
            @{$self->connect_options->opts},
        );
    }
    else {
        return (
            @{$self->connect_options->opts},
            $self->connect_options->host,
            $self->connect_options->port,
        );
    }
}

1;

# ABSTRACT: TELNET based CLI connection


__END__
=pod

=head1 NAME

Net::CLI::Interact::Transport::Telnet - TELNET based CLI connection

=head1 VERSION

version 2.143070

=head1 DESCRIPTION

This module provides a wrapped instance of a TELNET client for use by
L<Net::CLI::Interact>.

=head1 INTERFACE

=head2 app

On Windows platforms you B<must> download the C<plink.exe> program, and pass its
location to the library in this parameter. On other platforms, this defaults to
C<telnet>.

=head2 runtime_options

Based on the C<connect_options> hash provided to Net::CLI::Interact on
construction, selects and formats parameters to provide to C<app> on the
command line. Supported attributes:

=over 4

=item host (required)

Host name or IP address of the host to which the TELNET application is to
connect.

=item port

Port number on the host which is listening for the TELNET connection.
Defaults to 23.

=item opts

If you want to pass any other options to the Telnet application, then use
this option, which should be an array reference.

On Windows platforms, each item on the list will be passed to the C<plink.exe>
application, separated by a single space character. On Unix platforms, if depends
whether you have L<IO::Pty> installed (which in turn depends on a compiler).
Typically, the L<Net::Telnet> library is used for TELNET connections, so the 
list can be any options taken by its C<new()> constructor. Otherwise the local
C<telnet> application is used.

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

