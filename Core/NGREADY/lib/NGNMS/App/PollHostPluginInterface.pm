package NGNMS::App::PollHostPluginInterface;
use strict;
use warnings FATAL => 'all';
use Moo::Role;
use Emsgd qw (diag);
use File::Basename;
use NGNMS::Net::Session;

with "NGNMS::App::Helpers";
with "NGNMS::Log4Role";


requires qw (
  checkCanPollHost
  prepare_connection
  beforeProcessing
  checkSNMPsysObjectID
  checkDeviceSupported

  getModel
  getVendor
  getHostName
  getHardware
  getSoftware
  getLocation
  getInterfaces
  getIpLayer
  getConfig
);

#@returns  NGNMS::Net::SessionRole
has session => (
    is      => 'rw',
    handles => 'NGNMS::Net::SessionRole',
);
has snmp_session => ( is => 'rw' );



sub get_first_line {
    my $self  = shift;
    my $lines = shift;
    my $line  = $lines ? $self->trim( ( split( /\n/, $lines ) )[0] ) : '';
    chomp $line;
    return $line ? $line : undef;
}
1;
