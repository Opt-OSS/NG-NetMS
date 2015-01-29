#!/usr/bin/perl -w
#
# Scan subnets which were configured in network
#
# Usage:
#  subnets_scanner.pl [switches] user passwd access_type community pass_to_key
#
# Switches:
#  -L        DB host (default:localhost)
#  -D		 DB name
#  -U		 DB User
#  -W 		 Pasword for DB user	
#  -P        DB port
#
#
# Copyright (C) 2015
#
# Author: A.Iaropud
#

use strict;

use NGNMS_DB;
use NGNMS_util;
use NGNMS_Linux;
use Data::Dumper;
use Net::Netmask;
use Nmap::Scanner;
use Sort::Key::IPv4 qw(ipv4keysort);

my $netmask;
my $sample;
my $addr;
my $start;
my $block;
my $counter = 0;
my $counter_int = 0;
my @arr_ip ;
my @arr_mask;
my $nm;
my $type;
my $n;
my $hmin;
my $hmax;
my $mask;
my $hostn;
my %arr;
my $arr_param;
my @nets;
my $h;
my $m;
my $b;
my $range_scan;
my @arr_hmax;
my %blocks0 ;
my @upHosts = ();
my $ipaddr;
my $idx;
my $cur_id;
my $ocx_session;
my $os_name;
my $amount;
my $user_cur;
my $passwd_cur;
my $access_cur;
my $flag;
my $criptokey ;
my @params = ();
my @cmd2 = ();
my $type_router;

## initialize default access to DB
my $dbname = "";
my $dbuser = "";
my $dbpasswd = "";
my $dbport = "5432";
my $dbhost = 'localhost';
############
#####################################################################
# Parse command line
#

while (($#ARGV >= 0) && ($ARGV[0] =~ /^-.*/)) {
  
  if ($ARGV[0] eq "-L") {
    shift @ARGV;
    $dbhost = $ARGV[0] if defined($ARGV[0]);
	shift @ARGV;
    next;
  }
  
  if ($ARGV[0] eq "-D") {
    shift @ARGV;
    $dbname = $ARGV[0] if defined($ARGV[0]);
	shift @ARGV;
    next;
  }
  
  if ($ARGV[0] eq "-U") {
	shift @ARGV;
    $dbuser = $ARGV[0] if defined($ARGV[0]);
	shift @ARGV;
    next;
  }
  
  if ($ARGV[0] eq "-W") {
    shift @ARGV;
    $dbpasswd = $ARGV[0] if defined($ARGV[0]);
	shift @ARGV;
    next;
  }
  
  if ($ARGV[0] eq "-P") {
    shift @ARGV;
    $dbport = $ARGV[0] if defined($ARGV[0]);
	shift @ARGV;
    next;
	}
	
  if ($ARGV[0] eq "-h") {
    print <<EOF ;
Usage:
  subnets_scanner.pl [switches] user passwd access_type(Telnet/SSH) community pass_to_key(if it exist)

  Switches:
   -L       DB host (default:localhost)
   -D       DB name
   -U	 	DB User
   -W		Pasword for DB user
   -P		DB Port
EOF
    exit;
  }
  shift @ARGV;
}

die "Usage: $0 user passwd access_type [pass_to_key]\n" unless ($#ARGV >= 0);
my ($user, $passwd, $access,$community,$path_to_key) = @ARGV[0..4];

# Redirect stdout
=for
my $logFile = "/dev/null";
  if (defined($ENV{"NGNMS_LOGFILE"})) {
    $logFile = $ENV{"NGNMS_LOGFILE"};
  }

  open( STDERR, ">&STDOUT") or
    warn "Failed to redirect stderr to stdout: $!\n";
  open( STDOUT, "> $logFile") or
    warn "Failed to redirect stdout to $logFile: $!\n";
##
=cut
DB_open($dbname,$dbuser,$dbpasswd,$dbport,$dbhost);
my $arr = DB_getAllIntefaces();




         my @sorted_keys = ipv4keysort { $arr->{$_}->{ip_addr} } keys %$arr;
my $old_block=new Net::Netmask ('0.0.0.0' , '255.0.0.0');
my $high_link = 0;

for my $key (@sorted_keys) {
#    print qq{$key\t}, $arr->{$key}{ip_addr}, qq{\t\t},
#            $arr->{$key}{router_id}, qq{\n};
            $addr = $arr->{$key}{ip_addr};
		    $netmask = $arr->{$key}{mask};
		    $block = new Net::Netmask ($addr , $netmask);
			my @nets = split /\./, $addr;
			if($block->bits() <32)
			{
##				if(getClassNet($block->bits(),$nets[0]) < 1  )
##				{
					
					if(DB_isScanException($block))
					{
						if($block ne $old_block)
						{
							$blocks0{$counter_int}{block}=$block;
							$blocks0{$counter_int}{high_link}=&ip2num($addr);
							$high_link = &ip2num($addr);
							$old_block = $block;
							$counter_int++;
						}
						else
						{
							if(&ip2num($addr) > $high_link)
							{
								$idx = $counter_int -1;
								$blocks0{$idx}{high_link}=&ip2num($addr);
								$high_link = &ip2num($addr);
							}
						}
					}
					
=for
					$range_scan = &bintodq($hmin)."-";
					@arr_hmax = split /\./, &bintodq($hmax);
					$range_scan .= $arr_hmax[3];
					print $range_scan.":".$hostn."\n";
=cut
##				}
			}					
}
print Dumper(%blocks0);
    my @block_one = keys %blocks0;
    for my $block_idx (@block_one) {
    print 	"Scan ".$blocks0{$block_idx}{block}."\n";	
##	if($blocks0{$block_idx}{block}->base() eq '192.168.3.0')
##	{
		&scansubnet($blocks0{$block_idx}{block},$blocks0{$block_idx}{high_link});
##	}
    }

	my $p=48;
	$criptokey = DB_getCriptoKey();
	my $length = length $criptokey ;
	$p -= $length; 
	my $suffix =  ( '0' x $p );
	$criptokey.=$suffix;
	my $cmd = "$ENV{'NGNMS_HOME'}/bin/poll_host.pl";

for $ipaddr ( @upHosts ) {
	print "Process ".$ipaddr->{addr}.":";
	
#	$cur_id = DB_addRouter($ipaddr->{addr},$ipaddr->{addr},'unknown');
#	DB_writeLink($ipaddr->{high_link},$cur_id,'B');

	$amount = DB_isInRouterAccess($ipaddr->{addr});
	@params=();
	$params[0] = $ipaddr->{addr}; ##host
	$params[0] =~ s/\s+$//; 
	
	
	if(!defined($amount))
	{
		$amount =0;
	}
	print $amount."\n";
	if($amount < 1)	##if is not special access to router then it connects with default parameters
	{
		$params[1] = $user;
		$params[2] = $passwd;
		$params[3] = $passwd;
		$params[4] = $community; 		##community
		$params[4] =~ s/\s+$//; 
		$params[5] = $access;			##access
		$params[5] =~ s/\s+$//; 
		if(defined $path_to_key)
		{
			$params[6] = $path_to_key;
			$params[6] =~ s/\s+$//; 
		}
	}
	else
	{
		my $r_id = DB_getRouterId($ipaddr->{addr});
		$arr_param = DB_getRouterAccess($r_id);
####
foreach my $emp(@$arr_param)
				{
				    $access_cur = $access;
					$access_cur =  $emp->[0] if defined($emp->[0]);
					if(defined($emp->[1]))
					{
						$type_router = $emp->[1];
						$type_router =~ s/\s+$//;
					}
					
					$flag = lc($emp->[2]);
	#				print $emp->[2].":".$flag."\n";
					if($flag eq 'login')	#username
					{
						$params[1] = decryptAttrvalue($criptokey,$emp->[3]);
						$params[1] =~ s/\s+$//; 
					}
					if($flag eq 'password')	#password
					{
						$params[2] = decryptAttrvalue($criptokey,$emp->[3]); 
						$params[2] =~ s/\s+$//; 
						$params[3] = decryptAttrvalue($criptokey,$emp->[3]);
						$params[3] =~ s/\s+$//; 
					}
					if($flag eq 'enpassword')	#password
					{
						$params[3] = decryptAttrvalue($criptokey,$emp->[3]);
						$params[3] =~ s/\s+$//; 
					}

	##			case "port"

	##			case "pathphrase"
					if($flag eq 'path_to_key')	#path to key
					{
						$params[6] = decryptAttrvalue($criptokey,$emp->[3]);
						$params[6] =~ s/\s+$//; 
					}
					$params[4] = $community; 		##community
					$params[4] =~ s/\s+$//; 
					$params[5] = $access_cur;			##access
					$params[5] =~ s/\s+$//; 
				}
####				
				
				
				
	}
	
		@cmd2=($cmd);
		
		push @cmd2,'-d';
		push @cmd2,'-L';
		push @cmd2,$dbhost;
		push @cmd2,'-D';
		push @cmd2,$dbname;
		push @cmd2,'-U';
		push @cmd2,$dbuser;
		push @cmd2,'-W';
		push @cmd2,$dbpasswd;
		push @cmd2,'-P';
		push @cmd2,$dbport;
		
		system( @cmd2, @params );
	
}

DB_close;




## Subs to convert dotted-quads to integers and vice versa
sub dq2n{ unpack 'N', pack 'C4', split '\.', $_[ 0 ] };;
sub n2dq{ join '.', unpack 'C4', pack 'N', $_[ 0 ] };;
sub cidrtobin {
   my $cidr = $_[0];
   pack( "B*",(1 x $cidr) . (0 x (32 - $cidr)) );
}
sub getclass {
   my $n = $_[0];
   my $class = 1;
   while (unpack("B$class",$n) !~ /0/) {
      $class++;
      if ($class > 5) {
	 last;
      }
   } 
   return $class;
}
sub getClassNet{
		my ($btmask,$btfb) = @_;
        my $ret_val = 0;
        if($btmask == 8 && $btfb >= 0 && $btfb < 128)
        {
            $ret_val = 1;
        }
        elsif ($btmask == 16 && $btfb>=128 && $btfb <192)
        {
            $ret_val = 1;
        }
        elsif ($btmask == 24 && $btfb>=192 && $btfb <224)
        {
            $ret_val = 1;
        }
        
        return $ret_val;
    }

sub dqtobin {
        my @dq;
	my $q;
	my $i;
	my $bin;

	foreach $q (split /\./,$_[0]) {
		push @dq,$q;
	}
	for ($i = 0; $i < 4 ; $i++) {
		if (! defined $dq[$i]) {
			push @dq,0;
		}
	}
	$bin    = pack("CCCC",@dq);      # 4 unsigned chars
	return $bin;
}
sub bintodq {
	my $dq = join ".",unpack("CCCC",$_[0]);
print 
	return $dq;
}

sub ip2num()
{
	my $ip = $_[0];
	my @a = split /\./,$ip;
    my $intip = int($a[0])*256*256*256+int($a[1])*256*256+int($a[2])*256+int($a[3]); 
    
    return $intip;
	}	
sub num2ip()
{
	my $intip = $_[0];
	my $d = $intip % 256; $intip -= $d; $intip /= 256;
    my $c = $intip % 256; $intip -= $c; $intip /= 256;
    my $b = $intip % 256; $intip -= $b; $intip /= 256;
    my $ip="$intip.$b.$c.$d";
    return $ip;

}	
sub scansubnet{
	my ($target,$high_link) = @_;
	my $scanner = new Nmap::Scanner;
	my $cur_id ;
	my $cur_ip;
	my $control_cur_id;
#	$scanner->add_target($target);
	my $results = $scanner->scan("-sn $target");
	##print $results->as_xml();
	my $host_list = $results->get_host_list();
##	print Dumper($host_list);

    my $id_link = DB_getInterfaceRouterId(&num2ip($high_link));
 
while (my $host = $host_list->get_next()) 
	{
		unless (!($host->addresses)[0]->addr) 
		{
			if( $host->status eq 'up' ) 
			{
				$cur_ip = ($host->addresses)[0]->addr();
				$control_cur_id = DB_getRouterId($cur_ip);
				if(!defined $control_cur_id)
				{
					if(!defined DB_getInterfaceRouterId($cur_ip))
					{
						$cur_id = DB_addRouter($cur_ip,$cur_ip,'unknown');
						print "addr:".$cur_ip."\n";					
						$upHosts[$counter]{'addr'} =  $cur_ip;
						$upHosts[$counter]{'high_link'} =  $id_link;
						DB_writeLink($id_link,$cur_id,'B');
						$counter++;
					
					}
				}
				else
				{
					$upHosts[$counter]{'addr'} =  $cur_ip;
					$upHosts[$counter]{'high_link'} =  $id_link;
					DB_writeLink($id_link,$control_cur_id,'B');
					$counter++;
					
				}
			}
		}
	}
}	
