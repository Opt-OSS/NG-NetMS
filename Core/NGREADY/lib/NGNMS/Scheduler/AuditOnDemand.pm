package NGNMS::Scheduler::AuditOnDemand;

use NGNMS::Scheduler::Audit;
use Emsgd qw /diag/;
use strict;
use Moo;
use warnings FATAL => 'all';
with "NGNMS::Log4Role";
has 'exec_file' => (is=>'ro',default => $ENV{NGNMS_HOME}."/bin/audit_run.sh");
has flag_file=> (is=>'rw', default=>($ENV{NGNMS_DATA} || '.')."/exchange/do_audit_now.txt");
has mode=> (is=>'ro', default=>"file");

sub run{
    my $self = shift;
    if ($self->mode eq 'file'){
        $self->logger->debug("Checkng on-demand audit[$self->{mode}] requested [$self->{flag_file}]");
        return 1 unless -f $self->flag_file;
    }

    eval {
        my $r = NGNMS::Scheduler::Audit->new()->exec_file;
        $self->logger->info("On-demand audit[$self->{mode}] stareted mode ");
        system $r;
        $self->logger->info("On-demand audit[$self->{mode}] finished");
    };
    if ($@) {
        my $res = $@;
        $res =~ s/[\n\r]/;/g;
        $self->logger->error("On-demand audit[$self->{mode}] failed: $res");
    }
    unlink $self->flag_file;


}

1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
