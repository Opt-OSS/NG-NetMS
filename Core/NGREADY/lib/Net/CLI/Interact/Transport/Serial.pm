package Net::CLI::Interact::Transport::Serial;
{
  $Net::CLI::Interact::Transport::Serial::VERSION = '2.143070';
}

use Moo;
use Sub::Quote;
use MooX::Types::MooseLike::Base qw(InstanceOf);

extends 'Net::CLI::Interact::Transport::Base';

{
    package # hide from pause
        Net::CLI::Interact::Transport::Serial::Options;

    use Moo;
    use Sub::Quote;
    use MooX::Types::MooseLike::Base qw(Str Bool Int ArrayRef Any);

    extends 'Net::CLI::Interact::Transport::Options';

    has 'device' => (
        is => 'rw',
        isa => Str,
        required => 1,
    );

    has 'parity' => (
        is => 'rw',
        isa => quote_sub(
            q{ die "$_[0] not none/even/odd" unless $_[0] =~ m/^(?:none|even|odd)$/ }),
        default => quote_sub(q{'none'}),
    );

    has 'nostop' => (
        is => 'rw',
        isa => Bool,
        default => quote_sub('0'),
    );

    has 'speed' => (
        is => 'rw',
        isa => Int,
        default => quote_sub('9600'),
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
    isa => InstanceOf['Net::CLI::Interact::Transport::Serial::Options'],
    coerce => quote_sub(q{ (ref '' eq ref $_[0]) ? $_[0] :
        Net::CLI::Interact::Transport::Serial::Options->new(@_) }),
    required => 1,
);

sub _build_app {
    my $self = shift;
    die "please pass location of plink.exe in 'app' parameter to new()\n"
        if $self->is_win32;
    return 'cu'; # unix
}

sub runtime_options {
    my $self = shift;

    if ($self->is_win32) {
        return (
            '-serial',
            @{$self->connect_options->opts},
            $self->connect_options->device,
        );
    }
    else {
        return (
            ('--parity=' . $self->connect_options->parity),
            ('-l', $self->connect_options->device),
            ('-s', $self->connect_options->speed),
            ($self->connect_options->nostop ? '--nostop' : ()),
            @{$self->connect_options->opts},
        );
    }
}

1;

# ABSTRACT: Serial-line based CLI connection


__END__
=pod

=head1 NAME

Net::CLI::Interact::Transport::Serial - Serial-line based CLI connection

=head1 VERSION

version 2.143070

=head1 DESCRIPTION

This module provides a wrapped instance of a Serial-line client for use by
L<Net::CLI::Interact>.

=head1 INTERFACE

=head2 app

On Windows platforms you B<must> download the C<plink.exe> program, and pass its
location to the library in this parameter. On other platforms, this defaults to
C<cu>, which again you B<must> download and install.

=head2 runtime_options

Based on the C<connect_options> hash provided to Net::CLI::Interact on
construction, selects and formats parameters to provide to C<app> on the
command line. Supported attributes:

B<FIXME:> on Windows platforms, only the device attribute is supported.

=over 4

=item device (required)

Name of the device providing access to the Serial-line (e.g. C<< /dev/ttyUSB0
>> or C<COM5>.

=item parity

You have a choice of C<even>, C<odd> or C<none> for the parity used in serial
communication. The default is C<none>.

=item nostop

You can control whether to use C<XON/XOFF> handling for the serial
communication. The default is to disable this, so to enable it pass any True
value.

=item speed

You can set the speed (or I<baud rate>) of the serial line by passing a value
to this named parameter. The default is C<9600>.

=item opts

If you want to pass any other options to the application, then use
this option, which should be an array reference. Each item in the list will be
passed to the application, separated by a single space character.

=item reap

Only used on Unix platforms, this installs a signal handler which attempts to
reap the child process. Pass a true value to enable this feature only
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

