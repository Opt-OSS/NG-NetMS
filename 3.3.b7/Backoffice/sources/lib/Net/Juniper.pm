#!perl -I.
#+
#  @(#)Juniper.pm from Cisco.pm	1.1 9/07/99 saverio.pangoli@dante.org.uk
# 
#  CopyLeft Saverio Pangoli 1999
#
#  Net::Juniper V0.1
#
#  Provide a "Net::Juniper" object to communicate with Juniper routers
#  through their telnet port.
#
#-

package Net::Juniper;
require 5.002;

use	Net::Telnet;
use	Exporter;


@ISA		= qw( Exporter );
@EXPORT_OK	= qw( $Error $debug $TIMEOUT );

$TIMEOUT	= 60;  # How long to wait for a command to return.
$Error		= '';
if(!defined($debug)) {
    $debug = 0;
}
##print "debug=".$debug;

sub host		{ $_[0]->opened ? $_[0]->_socket->host : undef }
sub logged_in		{ $_[0]->{'logged_in'} }

sub _socket		{ $_[0]->{'socket'} }
sub opened		{ $_[0]->_socket && $_[0]->_socket->opened }
sub errmsg		{ $_[0]->{'error'} }

sub prompt {
    my $self = shift;
    my $old  = $self->{'prompt'};
    $self->{'prompt'} = shift if @_;
    return $old;
}

sub timeout {
    my $self = shift;
#    my $to = $self->{'timeout'}>0 ? $self->{'timeout'} : $TIMEOUT;
    my $to = $TIMEOUT;
    $self->{'timeout'} = shift if @_;
    return $to;
}

sub DESTROY {
    my $self = shift;
    $self->close;
}

sub _set_error {
    $self = shift;
    $Error = pop;
    $self->{'error'} = $Error;
}


sub new {
    my $type = shift;
    my ($host, $username, @passwords) = @_;

    $Error = '';

    my $self = {
	'socket'	=> new Net::Telnet(errmode => 'return'),
	'logged_in'	=> 0,
	'prompt'	=> '',
	'error'		=> '',
	'last_command'	=> '',
    };
    bless $self, $type;

    return $host ? $self->open($host, $username, @passwords) : $self;
}


#
# PUBLIC OPEN
#
#	$bool = $Juniper->open($host, $username, @passwords);
#
# Open a new connection to $host, using $username and @passwords to
# handle Juniper's deviating login sequence.
#
sub open {
    my $self = shift;
    my $host = shift;
    my $username = shift;
    my @passwords = @_;

    $self->close if $self->logged_in;

    print STDERR "connecting to $host\n" if $debug > 0;

    $self->_socket->open(Host => $host, Port => 'telnet', Timeout => $TIMEOUT)
	or return $self->_set_error($self->_socket->errmsg);

    print STDERR "logging in\n" if $debug gt 0;

    my ($intro, $match);
    for (;;) {
	($intro, $match) = $self->_socket->waitfor(Timeout => 15,
				    Match => '/username\s*:\s*$/i',
				    Match => '/password\s*:\s*$/i',
				    Match => '/\S*[#:>]\s*$/i'
			    )
	    or return $self->_set_error("login timed out");

	if ($match =~ /^login\s*:\s*$/i) {
	    print STDERR "Trying username ".$username."\n" if $debug > 0;
	    $self->_socket->print($username);
	}
	elsif ($match =~ /^Password\s*:\s*$/i && @passwords) {
	    if (@passwords) {
		my $password = shift @passwords;
		print STDERR "Trying password \"$password\"\n" if $debug > 0;
		$self->_socket->print($password);
	    }
	    else {
		$intro =~ s/\n+/ /g;
		$intro =~ s/(^\s+)|(\s+$)//g;
		return $self->_set_error("Login failed: $intro");
	    }
	}
	elsif ($match =~ /[#>]\s*$/i) {
	    print STDERR "Login succeeded\n" if $debug > 0;
	    $self->prompt($match);
	    $self->{'logged_in'} = 1;

	    print STDERR "Sending 'term len 0'\n" if $debug > 0;
	    $self->cmd('set cli screen-width 0', 3);
	    $self->cmd('set cli screen-length 0', 3);
	    #if(defined($Error)) { return undef if length($Error); }

	    $self->_set_error(undef);
	    return $self;
	}
    }
    return undef; # NOT REACHED
}


#
# PUBLIC CLOSE
#
#	$Juniper->close
#
# Logout from the remote Juniper.
#
sub close {
    my $self = shift;
    $Error = '';

    if ($self->opened) {
	$self->_socket->cmd(String=>'quit', Timeout=>2) if $self->logged_in;
	$self->_socket->close;
	$$self{'logged_in'} = 0;
	$self->prompt('');
    }
    return $self;
}


#
# PUBLIC CMD
#
#	@results = $Juniper->cmd($command [, $timeout]);
#
# Send "$command" to the remote Juniper, return the results in an
# array of lines.  Prompt and command-echo are stripped.
# Error is reset.
#
sub cmd {
    my $self = shift;
    my $cmd =  shift;
    my $timeout = @ARGV ? shift : $self->timeout;

    $self->_set_error(undef);
    if ($cmd =~ /^\s*(lo|logo|logou|logout|q|qu|qui|quit)\s*$/) {
	$self->close;
	$self->_set_error("Connection closed by foreign host.\n");
	return ($Error);
    }
    elsif ($self->logged_in) {
	my @output = ();
	if ($debug)
	{
	    print STDERR "cmd: \"$cmd\"";
	    if (defined($timeout))
	    {
		print STDERR " timeout: $timeout\n";
	    }
	    else
	    {
		print STDERR "\n";
	    }
	}

	my $ok = $self->_socket->cmd(
		    String => $cmd,
		    Output => \@output,
		    Prompt => '/\S+[#>] $/',
		    Timeout => $timeout);
	if (!$ok) {
	    $self->_set_error($self->_socket->errmsg);
	    return ();
	}
	return @output;
    }
    else {
	$self->_set_error("Not logged in");
	return ();
    }
}

1;

__END__

=head1 NAME

Net::Juniper - Perl(1) object class for communicating with Juniper routers

=head1 SYNOPSIS

=over 4

=item

B<require 5.004;>

B<use Net::Juniper qw(>C<$Error> C<$debug> C<$TIMEOUT>);

I<$juniper> = C<new> B<Net::Juniper>;

I<$juniper> = C<new> B<Net::Juniper>(I<$host>,I<$user>, I<@pass>);

I<$juniper> = I<$juniper>-E<gt>C<open>(I<$host>,I<$user>, I<@pass>);

I<@reply> = I<$juniper>-E<gt>C<cmd>(I<$command> [, I<$timeout>);

I<$errmsg> = I<$juniper>-E<gt>C<errmsg>;

I<$host> = I<$juniper>-E<gt>C<host>;

I<$prompt> = I<$juniper>-E<gt>C<prompt>;

I<$old_prompt> = I<$juniper>-E<gt>C<prompt>(I<$newprompt>);

I<$connected> = I<$juniper>-E<gt>C<opened>;

I<$where_there> = I<$juniper>-E<gt>C<logged_in>;

I<$juniper>-E<gt>C<close>;

=back 4

=head1 DESCRIPTION

The B<Net::Juniper> module provides a simple object to communicate with Juniper
routers.

A new instance of the class is created by C<new>(), which takes optional
I<host>, I<username> and I<passwords> arguments.

Communication with the remote end is done through the C<cmd>() method.

=head1 VARIABLES

=over 8

=item I<$Error>

Contains the last error message for any instance of the module.
Normally, it's better to use the C<errmsg>() method, since that contains
the last error message for a particular I<object instance>, but this is useful
if you call the second form of C<new>() and get B<undef> as a result.

=item I<$debug>

If this variable is set to a non-negative integer, the module will spit out
debug information to I<STDERR>.

=item I<$TIMEOUT>

Default timeout to use for commands to the Juniper.  Can be overridden with
C<timeout>() on a per-object basis, or with C<cmd>() on a per-command
basis.  Default value is 64 seconds.  To change the package-wide default,
change this variable.

=back 8

=head1 METHODS

Most of B<Net::Juniper>'s methods look similar to B<Net::Telnet>.  However,
although this module uses B<Net::Telnet>, it's not a true descendant of it.

=over 8

=item B<new>

=item B<new>(I<$host> [, I<$username>, I<@passwords>])

The first variant of B<new> creates a new B<Net::Juniper> instance and
returns a reference to it.

The second version creates the object and calls C<open>() to connect to
and log in on I<$host>.  It returns a reference on success, B<undef> on
failure.

=item B<close>

Closes the current connection (if any), returns I<$juniper>.  Causes
C<logged_in>() and C<opened>() to return false.

This method is automatically called when the object has to be destroyed.

=item B<cmd>(I<$command> [, I<$timeout>)

Sends I<$command> to the remote end and waits for a response.  The
I<$timeout> parameter is optional and can be used to override the default
(this might be useful for very short/simple commands like "C<quit>", etc.).

The reply is split into an array of lines.  Note that an empty array does
not necessarily mean that an error occurred.  The C<errmsg>() method can be
used to determine if there was an error.

=item B<errmsg>

Returns the most recent error message on the connection to I<$juniper>.  Returns
B<undef> if the last command was successful.

=item B<host>

Returns the name of the remote host, B<undef> if there is no connection.

=item B<logged_in>

Returns B<true> if there we managed to successfully connect and login to
a remote Juniper, B<false> otherwise.

=item B<open>(I<$host>)

=item B<open>(I<$host>, I<$user>)

=item B<open>(I<$host>, I<$user> ,I<@passwords>)

Open a connection to I<$host> and try to login using the I<$user> and
I<@passwords> credentials.
Returns the object reference on success, B<undef> on failure.

If the object already has a connection open, it closes it first.

On successful login, the command "C<term len 0>" will be issued first, to
prevent the "C<--More-->" prompt from mucking up things.

Multiple passwords are allowed (and will be tried
one by one).  This may seem strange, but there are several good reasons to
allow this:

B<(1)> You poll your router periodically with a
B<cron>(1) job and plan on changing the password in the near future.  Adding
the new password to the I<@passwords> list before actually changing it on
the router allows you a smooth transition.

B<(2)> Your router normally uses TACACS, but sometimes the TACACS server is
down or times out.  In such cases a backup password can be used.

=item B<opened>

Returns B<true> if the object has a connection open.  This does not
necessarily mean that the login was successful (see C<logged_in> for that).

=item B<prompt>

=item B<prompt>(I<$newprompt>);

Returns the command prompt of the remote Juniper.  Initially set to the first
command prompt that is encountered.

The second call will set the command prompt (and return the old one).  Note
that the object does not use this value for anything useful.  It's there for
your convenience (or your script's for that matter).

=back 8

=head1 EXAMPLE

The following script will send a "C<show ip bgp regex>" command to the remote
host and print the results:

    use Net::Juniper;

    $regex    = '_1129_';
    $host     = 'my.doma.in';
    $user     = 'foo';
    $pass     = 'bar';
    $command  = 'show ip bgp regex '.$regex;

    $juniper = new Net::Juniper;

    $juniper->open($host, $user, $pass)
       or die "$0: cannot connect to $host: ".$juniper->errmsg."\n";

    @reply = $juniper->cmd($command);

    if (!@reply) {
	if ($juniper->errmsg) {
	    die "** Error: ".$juniper->errmsg."\n";
	}
	else {
	    die "no routes match specification\n";
	}
    }
    else {
	print $juniper->host, " replied:\n", @reply;
	$juniper->close;
	exit 0;
    }

=head1 SEE ALSO

L<Net::Telnet>.

=head1 AUTHOR

Saverio Pangoli,  I<(saverio@dante.org.uk)>; Steven Bakker, I<(steven@dante.org.uk)>

=head1 COPYRIGHT

Copyright (c) 1999 Dante. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.
