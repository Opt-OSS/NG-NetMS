package Net::CLI::Interact::Transport::Base;
{
  $Net::CLI::Interact::Transport::Base::VERSION = '2.143070';
}

use Moo;
use MooX::Types::MooseLike::Base qw(InstanceOf);

with "Net::CLI::Interact::Transport::Role::StripControlChars";

BEGIN {
    sub is_win32 { return ($^O eq 'MSWin32') }

    extends (is_win32()
        ? 'Net::CLI::Interact::Transport::Platform::Win32'
        : 'Net::CLI::Interact::Transport::Platform::Unix');
}

{
    package # hide from pause
        Net::CLI::Interact::Transport::Options;
    use Moo;
    extends 'Net::CLI::Interact::Transport::Platform::Options';
}

has 'logger' => (
    is => 'ro',
    isa => InstanceOf['Net::CLI::Interact::Logger'],
    required => 1,
);

1;

# ABSTRACT: Spawns an Interactive CLI Session



__END__
=pod

=head1 NAME

Net::CLI::Interact::Transport::Base - Spawns an Interactive CLI Session

=head1 VERSION

version 2.143070

=head1 DESCRIPTION

This module provides a generic cross-platform API with the purpose of
interacting with a command line interface.

On Windows the L<IPC::Run> module is used and on Unix when L<IO::Pty> is
available (it requires a compiler) L<Net::Telnet>, else C<IPC::Run>. In all
cases, a program such as openssh is started and methods provided to send and
receive data from the interactive session.

You should not use this class directly, but instead inherit from it in
specific Transport that will set the application command line name, and
marshall any runtime options. The OS platform is detected automatically.

=head1 INTERFACE

=head2 init

This method I<must> be called before any other, to bootstrap the application
wrapper module (IPC::Run or Net::Telnet). However, via L<Net::CLI::Interact>'s
C<cmd>, C<match> or C<find_prompt> it will be called for you automatically.

Two attributes of the specific loaded Transport are used. First the
Application set in C<app> is of course required, plus the options in the
Transport's C<runtime_options> are retrieved, if set, and passed as command
line arguments to the Application.

=head2 connect_ready

Returns True if C<connect> has been called successfully, otherwise returns
False.

=head2 disconnect

Undefines the application wrapper flushes any output data buffer such that
the next call to C<cmd> or C<macro> will cause a new connection to be made.
Useful if you intentionally timeout a command and end up with junk in the
output buffer.

=head2 do_action

When passed a L<Net::CLI::Interact::Action> instance, will execute the
contained instruction on the connected CLI. This might be a command to
C<send>, or a regular expression to C<match> in the output.

Features of the commands and prompts are supported, such as Continuation
matching (and slurping), and sending without an I<output record separator>.

On failing to succeed with a Match, the module will time-out (see C<timeout>,
below) and raise an exception.

Output returned after issuing a command is stored within the Match Action's
C<response> and C<response_stash> slots by this method, with the latter then
marshalled into the correct C<send> Action by the
L<ActionSet|Net::CLI::Interact::ActionSet>.

=head2 put( @data )

Items in C<@data> are joined together by an empty string and sent as input to
the connected program's interactive session.

=head2 pump

Attempts to retrieve pending output from the connected program's interactive
session. Returns true if there is new data available in the buffer, else
will time-out and raise a Perl exception. See C<buffer> and C<timeout>.

=head2 flush

Empties the buffer used for response data returned from the connected CLI, and
returns that data as a single text string (possibly with embedded newlines).

=head2 timeout( $seconds? )

When C<do_action> is polling for response data matching a regular expression
Action, it will eventually time-out and throw an exception if nothing matches
and no more data arrives.

The number of seconds to wait is set via this method, which will also return
the current value of C<timeout>. The default value is 10 seconds.

=head2 irs_re

Returns the Regular Expression reference used to split lines of response from
the connected device. In the end, you will only receive data from this module
separated by the C<ors> value (by default a newline character). The C<irs_re>
is used internally by the module and is:

 qr/(?:\015\012|\015|\012)/  # i.e. CRLF or CR or LF

=head2 ors

Line separator character(s) appended to a command sent to the connected CLI.
This defaults to a newline on the application's platform.

=head2 logger

Slot for storing a reference to the application's
L<Logger|Net::CLI::Interact::Logger> object.

=head2 is_win32

Returns true if the current platform is Windows. Can be called as either a
class or instance method.

=head2 app

Location and name of the program used to establish an interactive CLI session.
On Unix platforms this will be C<ssh> (openssh), C<telnet>, or C<cu> (serial
line). On Windows this must be the C<plink.exe> program.

=head2 connect_options

Slot for storing a set of options for the specific loaded Transport, passed by
the user of Net::CLI::Interact as a hash ref. Do not access this directly, but
instead use C<runtime_options> from the specific Transport class.

=head2 wrapper

Slot for storing the application wrapper instance (IPC::Run or Net::Telnet).
Do not mess with this unless you know what you are doing.

=head2 buffer

After C<pump> returns successfully, the output most recently received is
stored in this slot. Do not access this directly, but instead use the C<flush>
method.

=head2 stash

During long sections of output, this slot allows more efficient detection of
matches. Older data is placed here, and only the most recent line of data is
stored in the C<buffer>. That's why C<flush> is the only way to ensure you get
all the output data in one go.

=head1 NOTES

B<FIXME>: On Unix, when the Telnet transport is selected but C<IP::Pty> is
unavailable, C<Net::Telnet> can still be used, but currently C<IPC::Run> is
used instead.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Oliver Gorwits.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

