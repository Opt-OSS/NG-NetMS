#
# NextGen NMS
#
# NGNMS_util: miscellaneous utility functions
#
# Copyright (C) 2002,2003 OptOSS LLC
#
# Author: M.Golov
#

package NGNMS_util;

use strict;

use Net::SNMP;
use Net::DNS;
use MIME::Base64;
use Crypt::TripleDES;
use Data::Dumper;

require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $data);

@ISA = qw(Exporter AutoLoader);

## set the version for version checking; uncomment to use
$VERSION     = 0.01;

@EXPORT      = qw(&skip_till &getHostType &reverseDNS &getHostPart  &bits2mask &logError &decryptAttrvalue);

# your exported package globals go here,
# as well as any optionally exported functions
#@EXPORT_OK   = qw($data);

# filehandle, regexp
sub skip_till {
  my $fh = shift;
  my $re = shift;
  #print $re;
  while (<$fh>) {
    chomp;                  # no newline
    #print "$_\n";
    return $_ if $_ =~ $re;
  }
  return undef;
}

# figure out what kind of router we have here...
# Params:
#  host name or ip
# Returns:
#  Cisco/Juniper/unknown/<undef>
#

# Test
my $testHostType;
# $testHostType = "Cisco";
# $testHostType = "Juniper";

sub getHostType($$) {
	my @oids = ('1.3.6.1.2.1.1.3.0');
  return ($testHostType,'') if defined($testHostType);

  my ($host,$community) = @_;
  my $version = '2c';
  my ($sess,$err) = Net::SNMP->session(-hostname => $host,
				       -community => $community);
  if(!defined($sess)) {
    if( $err =~ /Unable to resolve destination address.*/ ) {
      return (undef,"$err");
    }
    return (undef,"SNMP: $err");
  } 
  my $req = '1.3.6.1.2.1.1.2.0';    # 'sysObjectID.0'
  my $res = $sess->get_request(-varbindlist => [$req]);
  
  if (!defined($res)) {
	  
	  $sess->close(); 
	  my ($sess,$err) = Net::SNMP->session(-hostname => $host,
                       -version       => $version,
				       -community => $community);
	  if(!defined($sess)) {
		if( $err =~ /Unable to resolve destination address.*/ ) {
		return (undef,"$err");
		}
		return (undef,"SNMP: $err");
	}
	
	$res = $sess->get_request(-varbindlist => [$req]); 
	
	if (!defined($res)) {
		$err = $sess->error;
		return (undef,"SNMP: $err");
	}
  }

  my $mib = $res->{$req};

  print "mib: ", $mib, "\n";
  my $hostt = "unknown";
  $hostt = "Juniper" if $mib =~ /1\.3\.6\.1\.4\.1\.2636\..*/;
  $hostt = "Cisco" if $mib =~ /1\.3\.6\.1\.4\.1\.9\..*/;
  $hostt = "Linux" if $mib =~ /1\.3\.6\.1\.4\.1\.8072\..*/;
  $hostt = "HP" if $mib =~ /1\.3\.6\.1\.4\.1\.11\..*/;
  $hostt = "Extreme" if $mib =~ /1\.3\.6\.1\.4\.1\.1916\..*/;
  $hostt = "Netscreen" if $mib =~ /1\.3\.6\.1\.4\.1\.3224\..*/;

  
  return ($hostt,'');
}

# return host part of the full host name
sub getHostPart($) {
  my $host = shift;
  return $host if ( $host =~ /\d+\.\d+\.\d+\.\d+/);
  $host =~ /^([^.]*)/;
  return $1;
}

# Do reverse DNS lookup
# Params: ip addr
# Return: host name or IP addr if lookup failed
#
sub reverseDNS($) {
  my $ip_address = shift;
  my $result;
  my $res = new Net::DNS::Resolver;
  my $resp = $res->search($ip_address);
  if ($resp) {
    foreach my $rr ($resp->answer) {
      next unless $rr->type eq "PTR";
      $result = $rr->rdatastr;
      $result =~ s/\.$//g;
    }
  } else {
    $result = $ip_address;
  }
  return $result;
}


# Append the error to the application log
#
sub logError($$) {
  my ($subs, $msg) = @_;
  my $ts = localtime;
  print "LOG: $ts: $subs: $msg\n";
  system("logger","-t ngnms-$subs",$msg);
}

#
# Convert mask specified by number of bits to x.x.x.x format

sub bits2mask($) {
  my $bits = shift;
  my $res = '';
  my $rest = ".0.0.0";
  my %cvt;
  @cvt{("0",  "1",  "2",  "3",  "4",  "5",  "6",  "7")} =
        ("0","128","192","224","240","248","252","254");
  if ($bits == 32) {
    return "255.255.255.255";
  }
  if ($bits > 23) {
    $res = "255.255.255.";
    $rest = '';
    $bits -= 24;
  }
  if ($bits > 15) {
    $res = "255.255.";
    $rest = '.0';
    $bits -= 16;
  }
  if ($bits > 7) {
    $res = "255.";
    $rest = '.0.0';
    $bits -= 8;
  }
  return $res.$cvt{$bits}.$rest;
}

sub decryptAttrvalue($$)
{
	my $pass = shift;
	my $text = shift;
	my $des = Crypt::TripleDES->new();
	my $plaintext = $des->decrypt3 ( decode_base64($text), $pass );
	
	return $plaintext;
}


1;

__END__
