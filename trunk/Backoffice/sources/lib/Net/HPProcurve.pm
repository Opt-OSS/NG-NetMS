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

sub _version  {$_[0]->{'version'}}
sub _model  {$_[0]->{'model'}}
sub _strver  {$_[0]->{'strver'}}

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
    my ($access,$configPath,$host, $username, @passwords,$path_to_key) = @_;
	
	print "Path1 : $configPath\n";
	
	my $model;
	my $flag = 0;
    my $version = '';
	my $swmodel = '';
	my $str_ver = '';
	
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
			my $file_vers = $configPath."_version.txt";
			my $ssh  =  Net::OpenSSH->new($host,
											user => $username, 
											password => $passwords[0],
											strict_mode => 0, 
											timeout     => $TIMEOUT,
											master_opts => [ -o => "StrictHostKeyChecking=no" ]);
			my ($pty, $pid) = $ssh->open2pty({stderr_to_stdout => 1})
				or die "unable to start remote shell: " . $ssh->error;
				
			$model = Net::Telnet->new(
				-fhopen => $pty,
				-telnetmode => 0,
				-prompt => '/'.$host.'.*?# /',
				-cmd_remove_mode => 1);
				
			my ($prematch, $match) = $model->waitfor(Match => '/ProCurve.*?Switch.*\n/', Errmode=>'return', Timeout => 4);
		
			if($match)
			{
				$swmodel = $match;
			}
			
			($prematch, $match) = $model->waitfor(Match => '/(Firmware|Software) revision.*\n/', Errmode=>'return');
		    if($match)
			{
				$str_ver = $match;
			}
			$match =~ m/(Software|Firmware) revision (.*)/i;
			$version = $2 || "";
			$version =~ s/[\r\n]//g;
	}
	
    my $self = {
	'socket'		=> $model,
	'logged_in'	=> 0,
	'prompt'	=> '',
	'error'		=> '',
	'last_command'	=> '',
	't_access' => $access,
	'version' => $version,
	'model' => $swmodel,
	'strver'=>$str_ver
    };
    bless $self, $type;
print Dumper($self);
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
				$self{'logged_in'} = 0;
				$self->prompt('');
			  }
		}
	}
	
    return $self;
}


sub cmd {
    my $self = shift;
    my $cmd =  shift;
    my @output=();

    $self->_set_error(undef);
    if ($cmd =~ /^\s*(lo|logo|logou|logout|q|qu|qui|quit)\s*$/) {
	$self->close;
	$self->_set_error("Connection closed by foreign host.\n");
	return ($Error);
    }
    else {
    
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
}


1;

__END__

