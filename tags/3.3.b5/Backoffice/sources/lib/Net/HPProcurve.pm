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
sub _phint  {$_[0]->{'phint'}}
sub _logint  {$_[0]->{'logint'}}
sub _sysinfo  {$_[0]->{'sysinfo'}}
sub _config  {$_[0]->{'config'}}

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
	my $flag = 1;
    my $version = '';
	my $swmodel = '';
	my $str_ver = '';
	my @sysinfo = '';
	my @phint = '';
	my @logint = '';
	my @config = '';
	my $sys_info = '';
	my $ph_int = '';
	my $log_int = '';
	my $config_f = '';
	my %nopress = (
    "K.14.47" => 1,
    "W.14.49" => 1,
	);
    my $flag_log = 0;
	
    $Error = '';
	if($access eq 'Telnet')
	{
		$model =  new Net::Telnet(errmode => 'return',
								  host=>$host,
								  Timeout    => 5,
                                  Telnetmode => 0,
                                  Prompt     => '/'.$host.'.*?# /',
                                  Dump_log   => "/tmp/procurve.txt",  # Debug log.
                                  );
		$flag_log = 1;
	}
	else
	{		
			my $file_vers = $configPath."_version.txt";
		
			my $ssh =  Net::OpenSSH->new($host,
											user => $username, 
											password => $passwords[1],
											strict_mode => 0, 
											timeout     => 5,
											master_opts => [ -o => "StrictHostKeyChecking=no" ]);	

			if($ssh->error) 
			{
			$ssh =  Net::OpenSSH->new($host,
											user => $username, 
											password => $passwords[0],
											strict_mode => 0, 
											timeout     => 5,
											master_opts => [ -o => "StrictHostKeyChecking=no" ]);	
											$ssh->error and die "Unable to connect to remote host: " . $ssh->error;	
			$flag = 0;											
			}										
		
			my ($fh, $pid) = $ssh->open2pty({stderr_to_stdout => 1});
			my $model = Net::Telnet->new(
			  -fhopen => $fh,
			  -telnetmode => 0,
			  -prompt => '/'.$host.'.*?# /',
			  -cmd_remove_mode => 1
          );
		
			my ($prematch, $match) = $model->waitfor(Match => '/ProCurve.*?Switch.*\n/', Errmode=>'return', Timeout => 4);
		
			if($match)
			{
				$swmodel = $match;
			}
			
			($prematch, $match) = $model->waitfor(Match => '/(Firmware|Software) revision.*\n/', Errmode=>'return');
		    if($match)
			{
				$str_ver = $match;
				$str_ver =~ s/[\r\n]//g;
			}
			$match =~ m/(Software|Firmware) revision (.*)/i;
			$version = $2 || "";
			$version =~ s/[\r\n]//g;
			if (!$nopress{$version}) 
			{
				$model->waitfor(Match => '/Press any key to continue/',Errmode=>'return');
				$model->print("");
			}
			
			$model->waitfor('/[#>] /');
			$model->print("show system-information");
			($prematch, $match) = $model->waitfor( '/IP Mgmt/' );
			@sysinfo = split(/\r/,$prematch);
			
			for(my $i=0; $i < scalar(@sysinfo); $i++)
			{
			   $sysinfo[$i] =~ s/[\n]//g;
				chomp($sysinfo[$i]);
			}
			@sysinfo = grep{$_} @sysinfo;
			$sys_info = join ('~~~~',@sysinfo);
	
			($prematch, $match) = $model->waitfor( '/[#>] /' );
			if($flag)
			{
			$model->print(' terminal length 1000');
			$model->waitfor(Match => '/[#>] /', Errmode=>'return');
			$model->print(" show config");
			($prematch, $match) = $model->waitfor( Match => '/[#>] /', Errmode=>'return' );
			$model->print(" show config");
			($prematch, $match) = $model->waitfor( Match => '/[#>] /', Errmode=>'return' );
			@config = split(/\r/,$prematch);
			
			$config_f =  arr2str(@config);
			}
		
		
		
        $model->print(" show ip");
		($prematch, $match) = $model->waitfor( Match => '/[#>] /', Errmode=>'return',Timeout    => 2 );
		if($flag < 1)
		{
			@logint = split(/\r/,$prematch);
			$log_int =  arr2str(@logint);
		}	
		($prematch, $match) = $model->waitfor( Match => '/[#>] /', Errmode=>'return',Timeout    => 2 );
		

		$model->print("show interfaces brief");
		($prematch, $match) = $model->waitfor( Match => '/[#>] /', Errmode=>'return', Timeout    => 2);
		$model->print("show interfaces brief");
		($prematch, $match) = $model->waitfor( Match => '/[#>] /', Errmode=>'return', Timeout    => 2 );
		
		if($flag)
		{
			@logint = split(/\r/,$prematch);
			$log_int = arr2str(@logint);
			($prematch, $match) = $model->waitfor( Match => '/[#>] /', Errmode=>'return', Timeout    => 5 );
			$model->print("exit");
			($prematch, $match) = $model->waitfor( Match => '/[#>] /', Errmode=>'return', Timeout    => 5 );
			@phint = split(/\r/,$prematch);
			$ph_int = arr2str(@phint);
		}
		else
		{
			@phint = split(/\r/,$prematch);
			$ph_int = arr2str(@phint);
		}
		
		$flag_log =1;		
	}
	
    my $self = {
	'socket'		=> $model,
	'logged_in'	=> $flag_log,
	'prompt'	=> '',
	'error'		=> '',
	'last_command'	=> '',
	't_access' => $access,
	'version' => $version,
	'model' => $swmodel,
	'strver' => $str_ver,
	'phint' => $ph_int,
	'logint' => $log_int,
	'sysinfo' => $sys_info,
	'config' => $config_f
    };
    bless $self, $type;

 return $self;
}


sub arr2str(@)
{
	my @in_arr = @_;
	
	
	my @arr_new;
	my $j;
	my $i;
	my $sdvig = 1;
	my $first_el = $sdvig;
	for( $i=$first_el; $i < $#in_arr; $i++)
			{
			   $j = $i-$sdvig;
			   $in_arr[$i] =~ s/[\n]//g;
				chomp($in_arr[$i]);
			   if($in_arr[$i] =~/^\s*$/)
			   {
					$sdvig++;
			   }
			   else
			   {
					$arr_new[$j] =  $in_arr[$i];
			   }
			}
	@arr_new = grep{$_} @arr_new;
	my $ret_str = join ('~~~~',@arr_new);
	
	return $ret_str;
	
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

