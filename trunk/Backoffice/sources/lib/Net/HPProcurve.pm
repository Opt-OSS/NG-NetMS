#!perl -I.
#+
#  @(#)HPProcurve.pm 
#
#  Net::Extreme V0.1
#
#  Provide a "Net::Extreme" object to communicate with Extreme switches
#  through their telnet and ssh ports.
#
#-

package Net::HPProcurve;
require 5.002;

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
		$model =  new Net::Telnet(errmode => 'return',
								  host=>$host,
								  Timeout    => 5,
                                  Telnetmode => 0,
                                  Prompt     => '/'.$host.'.*?# /',
                                  Dump_log   => "/tmp/procurve.txt",  # Debug log.
                                  );
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



1;

__END__

