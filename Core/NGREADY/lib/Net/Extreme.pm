#!perl -I.
#+
#  @(#)ExtremeNet.pm 
#
#  Net::Extreme V0.1
#
#  Provide a "Net::Extreme" object to communicate with Extreme switches
#  through their telnet and ssh ports.
#
#-

package Net::Extreme;
require 5.002;

use strict;
use warnings FATAL => 'all';
use	Net::Telnet;
use Net::OpenSSH;
use Data::Dumper;
use	Exporter;


@ISA		= qw( Exporter );
@EXPORT_OK	= qw( $Error $debug $TIMEOUT );

$TIMEOUT	= 60;  # How long to wait for a command to return.
$Error		= '';
if(!defined($debug)) {
    $debug = 0;
}
$debug = 1;
##print "debug=".$debug;

sub host		{
					if($self->_access eq 'Telnet')
					{
						$_[0]->opened ? $_[0]->_socket->host : undef
					}
					else
					{
						$_[0]->_socket->host 
					}
				}
sub logged_in		{ $_[0]->{'logged_in'} }
sub _access	   { $_[0]->{'t_access'} }
sub _socket		{ $_[0]->{'socket'} }

sub opened		{
					 if($self->_access eq 'Telnet')
					 { $_[0]->_socket && $_[0]->_socket->opened }
					 else { 1 }
				 }
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
    my ($access,$host, $username, @passwords,$path_to_key) = @_;
	
	my $model;
	my $flag = 0;

    $Error = '';
	if($access eq 'Telnet')
	{
		$flag = 1;
		$model =  new Net::Telnet(errmode => 'return',host=>$host);
	}
	else
	{
		if(defined($path_to_key) && $path_to_key ne "" )
		{
			$model = Net::OpenSSH->new(
			$host,
			user =>$username,
			strict_mode => 0,
##			passphrase => $passphrase,
			key_path   => $path_to_key,
			timeout     => $timeout,
			master_opts => [ -o => "StrictHostKeyChecking=no" ]
			);
		}
		else
		{
			$model =  Net::OpenSSH->new($host,
											user => $username, 
											password => $passwords[0],
											strict_mode => 0, 
											timeout     => $TIMEOUT,
											master_opts => [ -o => "StrictHostKeyChecking=no" ]);	
        }																		
	}
	
    my $self = {
	'socket'	=> $model,
	'logged_in'	=> 0,
	'prompt'	=> '',
	'error'		=> '',
	'last_command'	=> '',
	't_access' => $access
    };
    bless $self, $type;

 return $self;
}


#
# PUBLIC OPEN
#
#	$bool = $Extreme->open($host, $username, @passwords);
#
# Open a new connection to $host, using $username and @passwords to
# handle Extreme's deviating login sequence.
#
sub open {
    my $self = shift;
	my $access = shift; 
    my $host = shift;
    my $username = shift;
    my @passwords = @_;

    $self->close if $self->logged_in;

	$debug = 0 if !defined($debug);
	
    print STDERR "connecting to $host\n" if $debug > 0;
    if($access eq 'Telnet')
	{
		$self->_socket->open(Host => $host, Port => 'telnet', Timeout => $TIMEOUT)
		or return $self->_set_error($self->_socket->errmsg);
        print "Extreme command 1";
		print STDERR "logging in\n" if $debug gt 0;
		print "Extreme command 2";
		my ($intro, $match);
		for (;;) {
		($intro, $match) = $self->_socket->waitfor(Timeout => 5,
						Match => '/login\s*:\s*$/i',
						Match => '/password\s*:\s*$/i',
						Match => '/\S*[#:>]\s*$/i'
					)
			or return $self->_set_error("login timed out");

		if ($match =~ /^login\s*:\s*$/i) {
			print STDERR "Trying username ".$username."\n" if $debug > 0;
			$self->_socket->print($username);
		}
		elsif ($match =~ /^password\s*:\s*$/i && @passwords) {
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
#			$self->_socket->print('disable clipaging');
			#if(defined($Error)) { return undef if length($Error); }

			$self->_set_error(undef);
			return $self;
		}
		}
	}
	else
	{
		$self->{'logged_in'} = 1;
		return $self;
	}
    return undef; # NOT REACHED
}


#
# PUBLIC CLOSE
#
#	$Extreme->close
#
# Logout from the remote Juniper.
#
sub close {
    my $self = shift;
    $Error = '';
	if (defined($self->_socket))
	{
     if($self->_access eq 'Telnet')
		{
			if ($self->opened) {
				$self->_socket->cmd(String=>'quit', Timeout=>2) if $self->logged_in;
				$self->_socket->close;
				$$self{'logged_in'} = 0;
				$self->prompt('');
			  }
		}
		else
		{
			$self->_socket->system("exit");
			$$self{'logged_in'} = 0;
		}
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
    if ($cmd =~ /^\s*(lo|logo|logou|logout|q|qu|qui|quit|exit)\s*$/) {
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
    if($self->_access eq 'Telnet')
	{
	       if($debug)
		   {
				print STDERR Dumper($self->_socket);
		   }
=for		   
	       my $ok = $self->_socket->cmd(
		    String => $cmd,
		    Output => \@output,
		    Prompt => '/\S+[#>] $/',
		    Timeout => $timeout);
			if (!$ok) {
			$self->_set_error($self->_socket->errmsg);
			return ();
		}
=cut
			$self->_socket->print("sh ver detail");
			my ($prematch, $match) = $self->_socket->waitfor( '/> /' );
			@output = split(/\n/,$prematch);
			if($debug)
		   {
				print STDERR Dumper(@output);
		   }
	}
    else
	{
		@output = eval { $self->_socket->capture($cmd) };
		if($self->_socket->error)
		{
			$self->_set_error($self->_socket->error);
			return ();
		}	
		
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

