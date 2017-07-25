package Net::Appliance::Session;
{
  $Net::Appliance::Session::VERSION = '4.200002';
}

use Moo;
use Sub::Quote;
use MooX::Types::MooseLike::Base qw(Bool Int Str HashRef InstanceOf);
use Net::CLI::Interact;

with 'Net::Appliance::Session::Transport';
with 'Net::Appliance::Session::Engine';
with 'Net::Appliance::Session::Async';

# import Try::Tiny try/catch/finally into caller's namespace
sub import {
    my $caller = caller;

    eval <<ENDEVAL;
        package $caller;
        use Class::Load ();
        Class::Load::load_class('Try::Tiny');
        Try::Tiny->import();
ENDEVAL

    die $@ if $@;
}

foreach my $slot (qw/
    logged_in
    in_privileged_mode
    in_configure_mode
    privileged_paging
    close_called
/) {
    has $slot => (
        is => 'rw',
        isa => Bool,
        required => 0,
        default => quote_sub('0'),
    );
}

foreach my $slot (qw/
    do_paging
    do_login
    do_privileged_mode
    do_configure_mode
    wake_up
/) {
    has $slot => (
        is => 'rw',
        isa => Bool,
        required => 0,
        default => quote_sub('1'),
    );
}

foreach my $slot (qw/
    username
    password
    privileged_password
/) {
    has $slot => (
        is => 'rw',
        isa => Str,
        required => 0,
        predicate => 1,
        reader => "get_$slot",
        writer => "set_$slot",
    );
}

foreach my $slot (qw/
    transport
    personality
/) {
    has $slot => (
        is => 'rw',
        isa => Str,
        required => 1,
    );
}

foreach my $slot (qw/
    host
    app
    add_library
/) {
    has $slot => (
        is => 'ro',
        isa => Str,
        required => 0,
        predicate => 1,
    );
}

has 'timeout' => (
    is => 'ro',
    isa => Int,
    required => 0,
    predicate => 1,
);

has 'connect_options' => (
    is => 'ro',
    isa => HashRef,
    required => 0,
    default => sub { {} },
);

has 'nci_options' => (
    is => 'ro',
    isa => HashRef,
    required => 0,
    default => sub { {} },
);

has 'nci' => (
    is => 'lazy',
    isa => InstanceOf['Net::CLI::Interact'],
    required => 1,
    predicate => 1,
    clearer => 1,
    handles => [qw/
        cmd
        macro
        last_prompt
        last_response
        set_phrasebook
        set_global_log_at
        prompt_looks_like
        find_prompt
    /],
);

sub _build_nci {
    my $self = shift;
    $self->connect_options->{host} = $self->host
        if $self->has_host;

    my $nci = Net::CLI::Interact->new({
        transport => $self->transport,
        personality => $self->personality,
        connect_options => $self->connect_options,
        ($self->has_app ? (app => $self->app) : ()),
        ($self->has_add_library ? (add_library => $self->add_library) : ()),
        ($self->has_timeout ? (timeout => $self->timeout) : ()),
        %{ $self->nci_options },
    });

    $nci->logger->log('engine', 'notice',
        sprintf "NAS loaded, version %s", ($Net::Appliance::Session::VERSION || 'devel'));
    return $nci;
}

1;

# ABSTRACT: Run command-line sessions to network appliances


__END__
=pod

=head1 NAME

Net::Appliance::Session - Run command-line sessions to network appliances

=head1 VERSION

version 4.200002

=head1 SYNOPSIS

 use Net::Appliance::Session;
 
 my $s = Net::Appliance::Session->new({
     personality => 'ios',
     transport => 'SSH',
     host => 'hostname.example',
     privileged_paging => 1, # only if using ASA/PIX OS 7+
                             # and there are other behaviour options, see below
 });
 
 try {
     $s->connect({ username => 'username', password => 'loginpass' });
 
     $s->begin_privileged({ password => 'privilegedpass' });
     print $s->cmd('show access-list');
     $s->end_privileged;
 }
 catch {
     warn "failed to execute command: $_";
 }
 finally {
     $s->close;
 };

or, try the bundled C<nas> helper script (beta feature!):

 nas --help

=head1 DESCRIPTION

Use this module to establish an interactive command-line session with a
network appliance. There is special support for moving into "privileged" mode
and "configure" mode, along with the ability to send commands to the connected
device and retrieve returned output.

There are other CPAN modules that cover similar ground, but they are less
robust and do not handle native SSH, Telnet and Serial Line connections with a
single interface on both Unix and Windows platforms.

Built-in commands come from a phrasebook which supports many network device
vendors (Cisco, HP, etc) or you can install a new phrasebook. Most phases of
the connection are configurable for different device behaviours.

=head1 METHODS

As in the synopsis above, the first step is to create a new instance.

Recommended practice is to wrap all other calls (except C<close()>) in a
C<try> block, to catch errors (typically time-outs waiting for CLI response).
This module exports the C<try/catch/finally> methods (from L<Try::Tiny>) into
your namespace as a simpler alternative to using C<eval()>.

For a full demonstration of usage, see the example script shipped with this
distribution.

=head2 Net::Appliance::Session->new( \%options )

 my $s = Net::Appliance::Session->new({
     personality => 'ios',
     transport => 'SSH',
     host => 'hostname.example',
 });

Prepares a new session for you, but will not connect to any device. Some
options are required, others optional:

=over 4

=item C<< personality => $name >> (required)

Tells the module which "language" to use when talking to the connected device,
for example C<ios> for Cisco IOS devices. There's a list of all the supported
platforms in the L<Phrasebook|Net::CLI::Interact::Manual::Phrasebook>
documentation. It's also possible to write new phrasebooks.

=item C<< transport => $backend >> (required)

The name of the transport backend used for the session, which may be one of
L<Telnet|Net::CLI::Interact::Transport::Telnet>,
L<SSH|Net::CLI::Interact::Transport::SSH>, or
L<Serial|Net::CLI::Interact::Transport::Serial>.

=item C<< app => $location >> (required on Windows)

On Windows platforms, you B<must> download the C<plink.exe> program, and pass
its location in this parameter.

=item C<< host => $hostname >> (required for Telnet and SSH transports)

When using the Telnet and SSH transports, you B<must> provide the IP or host
name of the target device in this parameter.

=item C<< timeout => $seconds >>

Configures a global default timeout value, in seconds, for interaction with
the remote device. The default is 10 seconds. You can also set timeout on a
per-command or per-macro call (see below).

=item C<< connect_options => \%options >>

Some of the transport backends can take their own options. For example with a
serial line connection you might specify the port speed, etc. See the
respective manual pages for each transport backend for further details
(L<SSH|Net::CLI::Interact::Transport::SSH>,
L<Telnet|Net::CLI::Interact::Transport::Telnet>,
L<Serial|Net::CLI::Interact::Transport::Serial>).

=item C<< add_library => $directory >>

If you've added to the built-in phrasebook with your own macros, then use
this option to load your new phrasebook file(s). The path here should be the
directory within which all your personalities are located, such as:

 ${directory}/cisco/ios/pb
 ${directory}/other/device/pb

Usually the phrasebook files are called "C<pb>" and to the C<personality>
option you pass the containing directory name, for example C<ios> or C<device>
in the examples shown. See L<Net::CLI::Interact::Manual::Tutorial> for
further details.

=item C<< nci_options => \%options >>

Should you wish to reconfigure the L<Net::CLI::Interact> instance used inside
of C<Net::Appliance::Session>, perhaps for an option not supported above, this
generic setting is available.

=back

=head2 connect( \%options )

 $s->connect({ username => $myname, password => $mysecret });

To establish a connection to the device, and possibly also log in, call this
method. Following a successful connection, paging of device output will be
disabled using commands appropriate to the platform. This feature can be
suppressed (see L</"CONFIGURATION">, below).

Options available to this method, sometimes required, are:

=over 4

=item C<< username => $name >>

The login username for the device. Whether this is required depends both on
how the device is configured, and how you have configured this module to act.
If it looks like the device presented a Username prompt. and you don't pass
the username a Perl exception will be thrown.

The username is cached within the module for possible use later on when
entering "privileged" mode.

=item C<< password => $secret >>

The login password for the device. Whether this is required depends both on
how the device is configured, and how you have configured this module to act.
If it looks like the device presented a Username prompt. and you don't pass
the username a Perl exception will be thrown.

The password is cached within the module for possible use later on when
entering "privileged" mode.

=item C<< privileged_password => $secret >> (optional)

In the situation where you've activated "privileged paging", yet your device
uses a different password for privileged mode than login, you'll need to set
that other password here.

Otherwise, because the module tries to disable paging, it first goes into
privileged mode as you instructed, and fails with the wrong (login) password.

=back

=head2 begin_privileged and end_privileged

 $s->begin_privileged;
 # do some work
 $s->end_privileged;

Once you have connected to the device, change to "privileged" mode by calling
the C<begin_privileged> method. The appropriate command will be issued for
your device platform, from the phrasebook. Likewise to exit "privileged" mode
call the C<end_privileged> method.

Sometimes authentication is required to enter "privileged" mode. In that case,
the module defaults to using the username and password first passed in the
C<connect> method. However to either override those or set them in case they
were not passed to C<connect>, use either or both of the following options to
C<begin_privileged>:

 $s->begin_privileged({ username => $myname, password => $mysecret });

=head2 begin_configure and end_configure

 $s->begin_configure;
 # make some changes
 $s->end_configure;

To enter "configuration" mode for your device platform, call the
C<begin_configure> method. This checks you are already in "privileged" mode,
as the module assumes this is necessary. If it isn't necessary then see
L</"CONFIGURATION"> below to modify this behaviour. Likewise to exit
"configure" mode, call the C<end_configure> method.

=head2 cmd( $command )

 my $config     = $s->cmd('show running-config');
 my @interfaces = $s->cmd('show interfaces brief');

Execute a single command statement on the connected device. The statement is
executed verbatim on the device, with a newline appended.

In scalar context the response is returned as a single string. In list context
the gathered response is returned as a list of lines. In both cases your local
platform's newline character will end all lines.

You can also call the C<last_response> method which returns the same data with
the same contextual behaviour.

This method accepts a hashref of options following the C<$command>, which can
include a C<timeout> value to permit long running commands to have all their
output gathered.

To handle more complicated interactions, for example commands which prompt for
confirmation or optional parameters, you should use a Macro. These are set up
in the phrasebook and issued via the C<< $s->macro($name) >> method call. See
the L<Phrasebook|Net::CLI::Interact::Phrasebook> and
L<Cookbook|Net::CLI::Interact::Manual::Cookbook> manual pages for further
details.

If you receive response text with a "mangled" copy of the issued command at
the start, then it's likely you need to set the terminal width. This prevents
the connected device from line-wrapping long commands. Issue something like:

 $s->begin_privileged;
 $s->cmd('terminal width 510');

=head2 close

 $s->close;

Once you have finished work with the device, call this method. It attempts to
back out of any "privileged" or "configuration" mode you've entered, re-enable
paging (unless suppressed) and then disconnect.

If a macro named C<"disconnect"> exists in the loaded phrasebook then it's
called just before disconnection. This allows you to issue a command such as
C<"exit"> to cleanly log out.

=head1 CONFIGURATION

Each of the entries below may either be passed as a parameter in the options
to the C<new> method, or called as a method in its own right and passed the
appropriate setting. If doing the latter, it should be before you call the
C<connect> method.

=over

=item do_login

Defaults to true. Pass a zero (false) to disable logging in to the device with
a username and password, should you get a command prompt immediately upon
connection.

=item do_privileged_mode

Defaults to true. If on connecting to the device your user is immediately in
"privieleged" mode, then set this to zero (false), which permits immediate
access to "configure" mode.

=item do_configure_mode

Defaults to true. If you set this to zero (false), the module assumes you're
in "configure" mode immediately upon entering "privileged" mode. I can't think
why this would be useful but you never know.

=item do_paging

Defaults to true. Pass a zero (false) to disable the post-login
reconfiguration of a device which avoids paged command output. If you cleanly
C<close> the device connection then paging is re-enabled. Use this option to
suppress these steps.

=item privileged_paging

Defaults to false. On some series of devices, in particular the Cisco ASA and
PIXOS7+ you must be in privileged mode in order to alter the pager. If that is
the case for your device, call this method with a true value to instruct the
module to better manage the situation.

=item pager_enable_lines

Defaults to 24. The command issued to re-enable paging (on disconnect)
typically takes a parameter which is the number of lines per page. If you want
a different value, set it in this option.

=item pager_disable_lines

Defaults to zero. The command issued to disable paging typically takes a
parameter which is the number of lines per page (zero begin to disable
paging). If your device uses a different number here, set it in this option.

=item wake_up

When first connecting to the device, the most common scenario is that a
Username (or some other) prompt is shown. However if no output is forthcoming
and nothing matches, the "enter" key is pressed, in the hope of triggering the
display of a new prompt. This is typically most useful on Serial connected
devices.

Set this configuration option to zero to suppress this behaviour, or to the
number of times "enter" should be pressed and output waited for. The default
is to press "enter" once.

=back

=head1 ASYNCHRONOUS BEHAVIOUR

The standard, and recommended way to use this module is as above, whereby the
application is blocked waiting for command response. It's also possible to
send a command, and separately return to ask for output at a later time.

 $s->say('show clock');

This will send the command C<show clock> to the connected device, followed by
a newline character.

 $s->gather();

This will gather and return output, with similar behaviour to C<cmd()>, above.
That is, it blocks waiting for output and a prompt, will timeout, and accepts
the same options.

You can still use C<last_response> after calling C<gather>, however be aware
that the command (from C<say>) may be echoed at the start of the output,
depending on device and connection transport.

=head1 DIAGNOSTICS

To see a log of all the processes within this module, and a copy of all data
sent to and received from the device, call the following method:

 $s->set_global_log_at('notice');

In place of C<notice> you can have other log levels (e.g. C<debug> for more,
or C<info> for less), and via the embedded
L<Logger|Net::CLI::Interact::Logger> at C<< $s->nci->logger >> it's possible
to finely control the diagnostics.

=head1 INTERNALS

See L<Net::CLI::Interact>.

=head1 THANKS

Over several years I have received many patches and suggestions for
improvement from users of this module. My heartfelt thanks to all, for their
contributions.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Oliver Gorwits.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

