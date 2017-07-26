package NGNMS::App::CommandLineOptions;

use strict;
use warnings FATAL => 'all';
use Moo::Role;
use MooX::Options;
use Emsgd qw /diag/;

=pod Command line options and defualt values

Default config params for connecting to DB, Base-classes for Session (unittest)
Default overidden by command-line args

=cut


option "mode" => (
        is      => 'ro',
        format  => 's',
        default => "audit",
        doc     => "Mudule to run | audit, poll-host etc"
    );
option "record" => (
        is      => 'ro',
        default=>1,
        negativable=>1,
        doc     => "record [default=1] results of executed on remote host macros into  direcory --record-dir, file per macro, disable record with --no-record option"
    );
option "record_dir" => (
        is      => 'ro',
        format  => 's',
        default=> ($ENV{'NGNMS_DATA'} || '.').'/rtconfig',
        doc     => "record output of executed on remote host macros into given direcory, file per macro, default : \$ENV{'NGNMS_HOME'}/data/rtconfig/{Router_id}"
    );
option "play" => (
        is      => 'ro',
        format  => 's',
        doc     => "get results of macros (recorder with --record) given from directory "
    );
#todo move debug to separate options file
option "verbose" => (
        is      => 'ro',
        short   => "v",
        format  => 's',
        default => sub{uc ($ENV{NGNMS_DEBUG} || 'ERROR')},
        doc     => "verbose level: [ DEBUG | INFO | WARN | ERROR | FATAL]  default ERROR",
        trigger=>1,
    );

option "host" => (
        is      => 'rw',
        format  => 's',
        doc     => "host IP or hostname for poll-host",
        trigger=>1,

    );
sub _trigger_host{
    my ($self,$val) = @_;
   $self->put_debug_key('host',$val)
}
option "host_type" => (
        is      => 'rw',
        format  => 's',
        doc     => "force host type : Supported hosts type"
    );
option "host_user" => (
        is      => 'ro',
        format  => 's',
        doc     => "user name for host"
    );
option "host_password" => (
        is      => 'ro',
        format  => 's',
        doc     => "password for host"
    );

option "host_priveleged_password" => (
        is      => 'ro',
        format  => 's',
        doc     => "priveleged password for host"
    );
option "host_transport" => (
        is      => 'ro',
        format  => 's',
        doc     => "transport for host SSHv1 | SSHv2 | Telnet"
    );
option "host_community" => (
        is      => 'ro',
        format  => 's',
        doc     => "SMNP community for host"
    );
option "inject"=>(
      is => 'ro',
        default=>0,
        negativable=>1,
        doc =>"Inject router in DB on PollHost mode if router  not exsists, used  only with  --host-type and --play"
    );
1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
